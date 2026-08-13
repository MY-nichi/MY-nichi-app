import SwiftData
import SwiftUI

struct TaskCardFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TaskCardFormViewModel
    @State private var isPriorityDialogPresented = false
    @State private var isFrequencyDialogPresented = false

    private let icons = ["rectangle.stack", "checkmark.square", "book", "pencil", "figure.walk", "music.note", "heart", "briefcase"]
    private let colors = ["#10B981", "#60A5FA", "#FBBF24", "#F472B6", "#A78BFA"]

    init(habit: Habit, card: TaskCard?, nextSortOrder: Int) {
        _viewModel = State(initialValue: TaskCardFormViewModel(habit: habit, card: card, nextSortOrder: nextSortOrder))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タスク名（必須）", text: $viewModel.title)
                    TextField("内容", text: $viewModel.detail, axis: .vertical).lineLimit(2...5)
                    TextField("メモ", text: $viewModel.memo, axis: .vertical).lineLimit(2...5)
                }

                Section("期限と時刻") {
                    Toggle("期限を設定", isOn: $viewModel.hasDueDate)
                        .controlSize(.small)
                    if viewModel.hasDueDate {
                        DatePicker("期限", selection: $viewModel.dueDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                    Toggle("開始時刻を設定", isOn: $viewModel.hasStartTime)
                        .controlSize(.small)
                    if viewModel.hasStartTime {
                        DatePicker("開始時刻", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                        Toggle("終了時刻を設定", isOn: $viewModel.hasEndTime)
                            .controlSize(.small)
                        if viewModel.hasEndTime {
                            DatePicker("終了時刻", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }

                Section("分類") {
                    Button {
                        isPriorityDialogPresented = true
                    } label: {
                        HStack {
                            Text("優先度")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(priorityName(viewModel.priority))
                                .foregroundStyle(.tint)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }
                    .buttonStyle(.plain)
                    Button {
                        isFrequencyDialogPresented = true
                    } label: {
                        HStack {
                            Text("頻度")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(frequencyName(viewModel.repeatRule))
                                .foregroundStyle(.tint)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }
                    .buttonStyle(.plain)
                    TextField("タグ（読書、勉強）", text: $viewModel.tagsText)
                }

                Section {
                    Toggle("リマインダーを設定", isOn: $viewModel.hasReminder)
                        .controlSize(.small)
                    if viewModel.hasReminder {
                        DatePicker("通知時刻", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("リマインダー")
                } footer: {
                    Text("設定した頻度の日に通知します。初回保存時に通知の許可を確認します。")
                }

                Section("見た目") {
                    Picker("アイコン", selection: $viewModel.iconName) {
                        ForEach(icons, id: \.self) { icon in
                            Label(iconName(icon), systemImage: icon).tag(icon)
                        }
                    }
                    Picker("色", selection: $viewModel.colorHex) {
                        ForEach(colors, id: \.self) { color in
                            Text(colorName(color)).tag(color)
                        }
                    }
                }

                Section("チェックリスト") {
                    ForEach($viewModel.checklistDrafts) { $draft in
                        HStack {
                            TextField("項目", text: $draft.title)
                            Button("削除", systemImage: "minus.circle.fill", role: .destructive) {
                                viewModel.removeChecklistDraft(id: draft.id)
                            }
                            .labelStyle(.iconOnly)
                        }
                    }
                    Button("項目を追加", systemImage: "plus.circle") {
                        viewModel.addChecklistDraft()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [.white, Color(red: 0.92, green: 0.99, blue: 0.97)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.fontWeight(.semibold)
                }
            }
            .alert("保存できませんでした", isPresented: errorBinding) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーです。")
            }
            .confirmationDialog("優先度を選択", isPresented: $isPriorityDialogPresented, titleVisibility: .visible) {
                priorityButton("低い", value: "low")
                priorityButton("通常", value: "normal")
                priorityButton("高い", value: "high")
                Button("キャンセル", role: .cancel) {}
            }
            .confirmationDialog("頻度を選択", isPresented: $isFrequencyDialogPresented, titleVisibility: .visible) {
                frequencyButton("1回だけ", value: "none")
                frequencyButton("毎日", value: "daily")
                frequencyButton("平日", value: "weekdays")
                frequencyButton("週末", value: "weekends")
                frequencyButton("毎週", value: "weekly")
                frequencyButton("毎月", value: "monthly")
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    private func priorityButton(_ title: String, value: String) -> some View {
        Button(viewModel.priority == value ? "✓ \(title)" : title) {
            viewModel.priority = value
        }
    }

    private func priorityName(_ value: String) -> String {
        switch value {
        case "low": "低い"
        case "high": "高い"
        default: "通常"
        }
    }

    private func frequencyButton(_ title: String, value: String) -> some View {
        Button(viewModel.repeatRule == value ? "✓ \(title)" : title) {
            viewModel.repeatRule = value
        }
    }

    private func frequencyName(_ value: String) -> String {
        switch value {
        case "daily": "毎日"
        case "weekdays": "平日"
        case "weekends": "週末"
        case "weekly": "毎週"
        case "monthly": "毎月"
        default: "1回だけ"
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }

    private func save() {
        guard let card = viewModel.save() else { return }
        if viewModel.card == nil {
            modelContext.insert(card)
        }
        do {
            try modelContext.save()
            Task { await NotificationService.updateReminder(for: card) }
            dismiss()
        } catch {
            modelContext.rollback()
            viewModel.errorMessage = "データを保存できませんでした。もう一度お試しください。"
        }
    }

    private func iconName(_ icon: String) -> String {
        ["rectangle.stack": "タスク", "checkmark.square": "チェック", "book": "読書", "pencil": "学習", "figure.walk": "運動", "music.note": "音楽", "heart": "健康", "briefcase": "仕事"][icon] ?? "アイコン"
    }

    private func colorName(_ color: String) -> String {
        ["#10B981": "エメラルド", "#60A5FA": "ブルー", "#FBBF24": "イエロー", "#F472B6": "ピンク", "#A78BFA": "パープル"][color] ?? "色"
    }
}

#Preview {
    TaskCardFormView(habit: Habit(title: "朝の習慣"), card: nil, nextSortOrder: 0)
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
