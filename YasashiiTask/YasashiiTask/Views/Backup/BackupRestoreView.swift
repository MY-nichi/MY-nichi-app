import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct BackupRestoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var cards: [TaskCard]
    @Query private var checklistItems: [ChecklistItem]
    @Query private var completionRecords: [CompletionRecord]
    @Query private var settings: [AppSettings]

    @State private var exportDocument: BackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingRestoreData: Data?
    @State private var isConfirmingRestore = false
    @State private var message: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Label("習慣 \(habits.count)件", systemImage: "leaf")
                Label("カード \(cards.count)件", systemImage: "rectangle.stack")
                Label("完了履歴 \(completionRecords.filter(\.isCompletedStatus).count)件", systemImage: "checkmark.circle")
            } header: {
                Text("現在のデータ")
            }

            Section {
                Button("JSONを書き出す", systemImage: "square.and.arrow.up") {
                    prepareExport()
                }
                Button("JSONから復元する", systemImage: "square.and.arrow.down") {
                    isImporting = true
                }
            } header: {
                Text("バックアップと復元")
            } footer: {
                Text("復元すると、現在のデータはバックアップ内のデータへ置き換わります。")
            }

            if let message {
                Section {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.06, green: 0.58, blue: 0.42))
                }
            }
        }
        .navigationTitle("バックアップ・復元")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: .json, defaultFilename: "yasashii-task-backup") { result in
            if case .success = result { message = "バックアップを書き出しました。" }
            if case .failure = result { errorMessage = "バックアップを書き出せませんでした。" }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            readImport(result)
        }
        .confirmationDialog("バックアップから復元しますか？", isPresented: $isConfirmingRestore, titleVisibility: .visible) {
            Button("現在のデータを置き換える", role: .destructive) { restore() }
            Button("キャンセル", role: .cancel) { pendingRestoreData = nil }
        } message: {
            Text("この操作は元に戻せません。必要であれば、先に現在のデータを書き出してください。")
        }
        .alert("処理できませんでした", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "不明なエラーです。")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func prepareExport() {
        do {
            let data = try BackupService.makeData(habits: habits, cards: cards, checklistItems: checklistItems, completionRecords: completionRecords, settings: settings)
            exportDocument = BackupDocument(data: data)
            isExporting = true
        } catch {
            errorMessage = "バックアップを作成できませんでした。"
        }
    }

    private func readImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let canAccess = url.startAccessingSecurityScopedResource()
            defer { if canAccess { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            _ = try BackupService.decode(data)
            pendingRestoreData = data
            isConfirmingRestore = true
        } catch {
            errorMessage = "有効なバックアップファイルを読み込めませんでした。"
        }
    }

    private func restore() {
        guard let pendingRestoreData else { return }
        do {
            try BackupService.restore(pendingRestoreData, using: modelContext)
            self.pendingRestoreData = nil
            message = "バックアップから復元しました。"
        } catch {
            errorMessage = "バックアップを復元できませんでした。アプリを閉じずに、もう一度お試しください。"
        }
    }
}

#Preview {
    NavigationStack { BackupRestoreView() }
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
