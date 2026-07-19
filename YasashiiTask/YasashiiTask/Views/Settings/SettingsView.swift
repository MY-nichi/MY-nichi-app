import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let appSettings = settings.first {
                    SettingsForm(settings: appSettings) {
                        viewModel.save(using: modelContext)
                    }
                } else {
                    ProgressView("設定を準備しています")
                }
            }
            .navigationTitle("設定")
        }
        .task {
            viewModel.ensureSettings(settings, using: modelContext)
        }
        .alert("保存できませんでした", isPresented: errorBinding) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーです。")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.clearError() } })
    }
}

private struct SettingsForm: View {
    @Bindable var settings: AppSettings
    let save: () -> Void

    var body: some View {
        Form {
            Section("外観") {
                Picker("テーマ", selection: $settings.theme) {
                    Text("端末に合わせる").tag("system")
                    Text("ライト").tag("light")
                    Text("ダーク").tag("dark")
                }
                .onChange(of: settings.theme) { _, _ in save() }
            }

            Section {
                Toggle("完了時に振動", isOn: $settings.hapticsEnabled)
                    .onChange(of: settings.hapticsEnabled) { _, _ in save() }
            } header: {
                Text("操作")
            } footer: {
                Text("カードを完了したとき、操作できたことを軽い振動で伝えます。")
            }

            Section {
                LabeledContent("バックアップのお知らせ", value: "今後追加予定")
                    .foregroundStyle(.secondary)
                LabeledContent("タスク通知", value: "MVP完成後に追加")
                    .foregroundStyle(.secondary)
            } header: {
                Text("通知の準備")
            } footer: {
                Text("バックアップの保存忘れやタスク時刻を知らせる機能は、MVP完成後に追加します。")
            }

            Section("データ") {
                NavigationLink {
                    BackupRestoreView()
                } label: {
                    Label("バックアップ・復元", systemImage: "externaldrive")
                }
            }

            Section("アプリ情報") {
                LabeledContent("アプリ名", value: "やさしいタスク")
                LabeledContent("データ保存", value: "この端末内")
                LabeledContent("バージョン", value: "MVP開発中")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
