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
            .navigationBarTitleDisplayMode(.inline)
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
    @FocusState private var isNameFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("お名前（任意）", text: displayNameBinding)
                    .textContentType(.name)
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onSubmit {
                        finishNameInput()
                    }
            } header: {
                Text("名前")
            } footer: {
                Text("入力した名前は、この端末内だけに保存します。")
            }

            Section("リマインダー") {
                Toggle("振動", isOn: $settings.hapticsEnabled)
                    .onChange(of: settings.hapticsEnabled) { _, _ in save() }
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
                LabeledContent("バージョン", value: "1.0.0")
            }
        }
        .scrollContentBackground(.hidden)
        .appScreenBackground()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    finishNameInput()
                }
            }
        }
    }

    private var displayNameBinding: Binding<String> {
        Binding(
            get: { settings.displayName ?? "" },
            set: {
                settings.displayName = $0.isEmpty ? nil : $0
            }
        )
    }

    private func finishNameInput() {
        save()
        isNameFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
