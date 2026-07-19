import SwiftData
import SwiftUI

struct TaskCardFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TaskCardFormViewModel

    private let icons = ["rectangle.stack", "checkmark.square", "book", "pencil", "figure.walk", "music.note", "heart", "briefcase"]
    private let colors = ["#10B981", "#60A5FA", "#FBBF24", "#F472B6", "#A78BFA"]

    init(habit: Habit, card: TaskCard?, nextSortOrder: Int) {
        _viewModel = State(initialValue: TaskCardFormViewModel(habit: habit, card: card, nextSortOrder: nextSortOrder))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("カード名（必須）", text: $viewModel.title)
                    TextField("内容", text: $viewModel.detail, axis: .vertical).lineLimit(2...5)
                    TextField("メモ", text: $viewModel.memo, axis: .vertical).lineLimit(2...5)
                }

                Section("期限と時刻") {
                    Toggle("期限を設定", isOn: $viewModel.hasDueDate)
                    if viewModel.hasDueDate {
                        DatePicker("期限", selection: $viewModel.dueDate, displayedComponents: .date)
                    }
                    Toggle("開始時刻を設定", isOn: $viewModel.hasStartTime)
                    if viewModel.hasStartTime {
                        DatePicker("開始時刻", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                        Toggle("終了時刻を設定", isOn: $viewModel.hasEndTime)
                        if viewModel.hasEndTime {
                            DatePicker("終了時刻", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }

                Section("分類") {
                    Picker("優先度", selection: $viewModel.priority) {
                        Text("低い").tag("low")
                        Text("通常").tag("normal")
                        Text("高い").tag("high")
                    }
                    Picker("繰り返し", selection: $viewModel.repeatRule) {
                        Text("なし").tag("none")
                        Text("毎日").tag("daily")
                        Text("毎週").tag("weekly")
                        Text("毎月").tag("monthly")
                    }
                    TextField("タグ（読書、勉強）", text: $viewModel.tagsText)
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
            dismiss()
        } catch {
            modelContext.rollback()
            viewModel.errorMessage = "データを保存できませんでした。もう一度お試しください。"
        }
    }

    private func iconName(_ icon: String) -> String {
        ["rectangle.stack": "カード", "checkmark.square": "チェック", "book": "読書", "pencil": "学習", "figure.walk": "運動", "music.note": "音楽", "heart": "健康", "briefcase": "仕事"][icon] ?? "アイコン"
    }

    private func colorName(_ color: String) -> String {
        ["#10B981": "エメラルド", "#60A5FA": "ブルー", "#FBBF24": "イエロー", "#F472B6": "ピンク", "#A78BFA": "パープル"][color] ?? "色"
    }
}

#Preview {
    TaskCardFormView(habit: Habit(title: "朝の習慣"), card: nil, nextSortOrder: 0)
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
