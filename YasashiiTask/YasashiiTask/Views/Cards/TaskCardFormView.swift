import SwiftData
import SwiftUI
import UIKit

struct TaskCardFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var viewModel: TaskCardFormViewModel
    @State private var isDeleteConfirmationPresented = false

    private let icons = ["rectangle.stack", "checkmark.square", "book", "pencil", "figure.walk", "music.note", "heart", "briefcase"]
    private let colors = ["#10B981", "#60A5FA", "#06B6D4", "#84CC16", "#FBBF24", "#F97316", "#EF4444", "#F472B6", "#A78BFA", "#64748B"]
    private let weekdays = [(1, "日"), (2, "月"), (3, "火"), (4, "水"), (5, "木"), (6, "金"), (7, "土")]

    init(habit: Habit? = nil, card: TaskCard?, nextSortOrder: Int) {
        _viewModel = State(initialValue: TaskCardFormViewModel(habit: habit, card: card, nextSortOrder: nextSortOrder))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タスク名（必須）", text: $viewModel.title)
                    TextField("内容", text: $viewModel.detail)
                    TextField("メモ", text: $viewModel.memo)
                }

                Section {
                    Toggle("日時を設定", isOn: $viewModel.hasDueDate)
                        .controlSize(.small)
                    if viewModel.hasDueDate {
                        DatePicker("期限", selection: $viewModel.dueDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                    if !viewModel.requiresRepeatDetails {
                        Toggle("リマインダー", isOn: $viewModel.hasReminder)
                            .controlSize(.small)
                        if viewModel.hasReminder {
                            DatePicker("通知時刻", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }

                Section("繰り返し") {
                    Picker("繰り返し", selection: $viewModel.repeatRule) {
                        Text("なし").tag("none")
                        Text("毎週").tag("weekly")
                        Text("隔週").tag("biweekly")
                        Text("毎月").tag("monthly")
                    }

                    if viewModel.requiresRepeatDetails {
                        HStack(spacing: 8) {
                            ForEach(weekdays, id: \.0) { weekday, label in
                                Button {
                                    viewModel.toggleRepeatWeekday(weekday)
                                } label: {
                                    Text(label)
                                        .font(.caption.weight(.semibold))
                                        .frame(width: 34, height: 34)
                                        .foregroundStyle(viewModel.repeatWeekdays.contains(weekday) ? .white : .primary)
                                        .background(
                                            viewModel.repeatWeekdays.contains(weekday)
                                                ? AppTheme.tint
                                                : AppTheme.chipBackground,
                                            in: Circle()
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)

                        DatePicker("通知時刻", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("分類") {
                    Menu {
                        priorityButton("低い", value: "low")
                        priorityButton("通常", value: "normal")
                        priorityButton("高い", value: "high")
                    } label: {
                        HStack {
                            Text("優先度")
                            Spacer()
                            Text(priorityName(viewModel.priority))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(.tint)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                }

                Section {
                    Menu {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                viewModel.iconName = icon
                            } label: {
                                Label(iconName(icon), systemImage: icon)
                            }
                        }
                    } label: {
                        pickerRow(
                            title: "アイコン",
                            value: iconName(viewModel.iconName),
                            systemImage: viewModel.iconName
                        )
                    }
                    .transaction { $0.animation = nil }

                    Menu {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                viewModel.colorHex = color
                            } label: {
                                Label {
                                    Text(colorName(color))
                                } icon: {
                                    Image(uiImage: colorCircleImage(color))
                                        .renderingMode(.original)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Text("カラー")
                            Spacer()
                            Circle()
                                .fill(colorValue(viewModel.colorHex))
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(.secondary.opacity(0.35), lineWidth: 1))
                            Text(colorName(viewModel.colorHex))
                                .frame(minWidth: 70, alignment: .trailing)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(.tint)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .transaction { $0.animation = nil }
                }

                if viewModel.card != nil {
                    Section {
                        Button("タスクを削除", systemImage: "trash", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [.white, AppTheme.screenBackground],
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
            .confirmationDialog("タスクを削除しますか？", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
                Button("削除する", role: .destructive) {
                    deleteCard()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("関連する完了履歴も削除されます。この操作は元に戻せません。")
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
            Task { await NotificationService.updateReminder(for: card, hapticsEnabled: hapticsEnabled) }
            dismiss()
        } catch {
            modelContext.rollback()
            viewModel.errorMessage = "データを保存できませんでした。もう一度お試しください。"
        }
    }

    private func deleteCard() {
        guard let card = viewModel.card else { return }
        NotificationService.removeTaskReminder(for: card.id)
        modelContext.delete(card)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            viewModel.errorMessage = "タスクを削除できませんでした。もう一度お試しください。"
        }
    }

    private func iconName(_ icon: String) -> String {
        ["rectangle.stack": "タスク", "checkmark.square": "チェック", "book": "読書", "pencil": "学習", "figure.walk": "運動", "music.note": "音楽", "heart": "健康", "briefcase": "仕事"][icon] ?? "アイコン"
    }

    private var hapticsEnabled: Bool {
        settings.first?.hapticsEnabled ?? true
    }

    private func colorName(_ color: String) -> String {
        ["#10B981": "エメラルド", "#60A5FA": "ブルー", "#06B6D4": "水色", "#84CC16": "グリーン", "#FBBF24": "イエロー", "#F97316": "オレンジ", "#EF4444": "レッド", "#F472B6": "ピンク", "#A78BFA": "パープル", "#64748B": "グレー"][color] ?? "カラー"
    }

    private func colorValue(_ hex: String) -> Color {
        let value = Int(hex.dropFirst(), radix: 16) ?? 0
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    private func colorCircleImage(_ hex: String) -> UIImage {
        let size = CGSize(width: 18, height: 18)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(colorValue(hex)).setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1))
        }.withRenderingMode(.alwaysOriginal)
    }

    private func pickerRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Text(title)
            Spacer()
            Label(value, systemImage: systemImage)
                .frame(minWidth: 96, alignment: .trailing)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
        }
        .foregroundStyle(.tint)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

#Preview {
    TaskCardFormView(habit: Habit(title: "朝の習慣"), card: nil, nextSortOrder: 0)
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
