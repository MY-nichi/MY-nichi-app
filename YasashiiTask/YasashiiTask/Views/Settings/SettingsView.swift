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
            Section {
                TextField("お名前（任意）", text: displayNameBinding)
                    .textContentType(.name)
                    .onSubmit(save)
            } header: {
                Text("プロフィール")
            } footer: {
                Text("入力した名前は、この端末内だけに保存します。")
            }

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
                LabeledContent("タスク通知", value: "カードごとに設定")
            } header: {
                Text("通知の準備")
            } footer: {
                Text("タスク通知は、カードの作成・編集画面で時刻を設定できます。")
            }

            Section("データ") {
                NavigationLink {
                    BackupRestoreView()
                } label: {
                    Label("バックアップ・復元", systemImage: "externaldrive")
                }
            }

            Section("アプリ情報") {
                LabeledContent("アプリ名", value: "MY-nichi")
                LabeledContent("データ保存", value: "この端末内")
                LabeledContent("バージョン", value: "MVP開発中")
            }
        }
    }

    private var displayNameBinding: Binding<String> {
        Binding(
            get: { settings.displayName ?? "" },
            set: {
                settings.displayName = $0.isEmpty ? nil : $0
                save()
            }
        )
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
