import SwiftData
import SwiftUI

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HabitFormViewModel

    private let icons = ["checkmark.circle", "leaf", "figure.walk", "book", "pencil", "music.note", "heart", "cup.and.saucer"]
    private let colors = ["#10B981", "#60A5FA", "#FBBF24", "#F472B6", "#A78BFA"]
    private let weekdays = [(1, "日"), (2, "月"), (3, "火"), (4, "水"), (5, "木"), (6, "金"), (7, "土")]

    init(habit: Habit?, nextSortOrder: Int) {
        _viewModel = State(initialValue: HabitFormViewModel(habit: habit, nextSortOrder: nextSortOrder))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("習慣名（必須）", text: $viewModel.title)
                    TextField("説明", text: $viewModel.detail, axis: .vertical)
                        .lineLimit(2...5)
                    TextField("カテゴリ", text: $viewModel.category)
                }

                Section("見た目") {
                    Picker("アイコン", selection: $viewModel.iconName) {
                        ForEach(icons, id: \.self) { icon in
                            Label(iconDisplayName(icon), systemImage: icon).tag(icon)
                        }
                    }
                    Picker("色", selection: $viewModel.colorHex) {
                        ForEach(colors, id: \.self) { color in
                            Label(colorDisplayName(color), systemImage: "circle.fill").tag(color)
                        }
                    }
                }

                Section("実施する曜日") {
                    HStack(spacing: 7) {
                        ForEach(weekdays, id: \.0) { weekday, label in
                            Button {
                                viewModel.toggleDay(weekday)
                            } label: {
                                Text(label)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(
                                        viewModel.activeDays.contains(weekday) ? Color.emerald : Color(.tertiarySystemFill),
                                        in: Circle()
                                    )
                                    .foregroundStyle(viewModel.activeDays.contains(weekday) ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(label)曜日")
                            .accessibilityValue(viewModel.activeDays.contains(weekday) ? "選択中" : "未選択")
                        }
                    }
                    Text("未選択の場合は毎日として扱います。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("期間と目標") {
                    DatePicker("開始日", selection: $viewModel.startDate, displayedComponents: .date)
                    Toggle("終了日を設定", isOn: $viewModel.hasEndDate)
                    if viewModel.hasEndDate {
                        DatePicker("終了日", selection: $viewModel.endDate, displayedComponents: .date)
                    }
                    Stepper("1日の目標：\(viewModel.targetCount)回", value: $viewModel.targetCount, in: 1...99)
                    Toggle("この習慣を有効にする", isOn: $viewModel.isActive)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
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
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func save() {
        guard let habit = viewModel.save() else { return }
        if viewModel.habit == nil {
            modelContext.insert(habit)
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            viewModel.errorMessage = "データを保存できませんでした。もう一度お試しください。"
        }
    }

    private func iconDisplayName(_ icon: String) -> String {
        ["checkmark.circle": "チェック", "leaf": "葉", "figure.walk": "運動", "book": "読書", "pencil": "学習", "music.note": "音楽", "heart": "健康", "cup.and.saucer": "休憩"][icon] ?? "アイコン"
    }

    private func colorDisplayName(_ color: String) -> String {
        ["#10B981": "エメラルド", "#60A5FA": "ブルー", "#FBBF24": "イエロー", "#F472B6": "ピンク", "#A78BFA": "パープル"][color] ?? "色"
    }
}

private extension Color {
    static let emerald = Color(red: 0.06, green: 0.58, blue: 0.42)
}

#Preview {
    HabitFormView(habit: nil, nextSortOrder: 0)
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
