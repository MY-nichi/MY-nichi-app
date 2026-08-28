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
                Label("タスク \(cards.count)件", systemImage: "rectangle.stack")
                Label("完了履歴 \(completionRecords.filter(\.isCompletedStatus).count)件", systemImage: "checkmark.circle")
            } header: {
                Text("現在のデータ")
            }

            Section {
                Button("バックアップを保存する", systemImage: "square.and.arrow.up") {
                    prepareExport()
                }
                Button("バックアップから復元する", systemImage: "square.and.arrow.down") {
                    isImporting = true
                }
            } header: {
                Text("バックアップと復元")
            } footer: {
                Text("復元時に、現在のデータを置き換えるか、追加で取り込むかを選べます。")
            }

            if let message {
                Section {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.tint)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appScreenBackground()
        .navigationTitle("バックアップ・復元")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: .json, defaultFilename: "yasashii-task-backup") { result in
            if case .success = result { message = "バックアップを書き出しました。" }
            if case .failure = result { errorMessage = "バックアップを書き出せませんでした。" }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            readImport(result)
        }
        .confirmationDialog("復元方法を選択", isPresented: $isConfirmingRestore, titleVisibility: .visible) {
            Button("上書き復元", role: .destructive) { restore() }
            Button("追加で取り込む") { importAdding() }
            Button("キャンセル", role: .cancel) { pendingRestoreData = nil }
        } message: {
            Text("上書き復元は現在のデータを置き換えます。追加取り込みは現在のデータを残します。")
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

    private func importAdding() {
        guard let pendingRestoreData else { return }
        do {
            try BackupService.importAdding(pendingRestoreData, using: modelContext)
            self.pendingRestoreData = nil
            message = "バックアップを追加で取り込みました。"
        } catch {
            errorMessage = "バックアップを追加できませんでした。アプリを閉じずに、もう一度お試しください。"
        }
    }
}

#Preview {
    NavigationStack { BackupRestoreView() }
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
