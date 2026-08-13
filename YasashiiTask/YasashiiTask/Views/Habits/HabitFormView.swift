import SwiftData
import SwiftUI
import UIKit

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HabitFormViewModel
    @State private var isCustomIconInputVisible = false
    @FocusState private var isCustomIconFieldFocused: Bool

    private let icons = ["checkmark.circle", "leaf", "figure.walk", "book", "pencil", "music.note", "heart", "cup.and.saucer", "sparkles"]
    private let colors = ["#10B981", "#60A5FA", "#06B6D4", "#84CC16", "#FBBF24", "#F97316", "#EF4444", "#F472B6", "#A78BFA", "#64748B"]
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

                Section {
                    VStack(spacing: 0) {
                        Menu {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    viewModel.iconName = icon
                                    isCustomIconInputVisible = icon == "sparkles"
                                    if icon == "sparkles" {
                                        isCustomIconFieldFocused = true
                                    }
                                } label: {
                                    Label(iconDisplayName(icon), systemImage: icon)
                                }
                            }
                        } label: {
                            HStack {
                                Text("アイコン")
                                Spacer()
                                Label(selectedIconDisplayName, systemImage: viewModel.iconName)
                            }
                            .foregroundStyle(Color.emerald)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }

                        if viewModel.iconName == "sparkles", isCustomIconInputVisible {
                            Divider()
                            HStack {
                                Text("表示文字")
                                TextField("文字・絵文字", text: $viewModel.customIconText)
                                    .multilineTextAlignment(.trailing)
                                    .focused($isCustomIconFieldFocused)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        isCustomIconFieldFocused = false
                                        isCustomIconInputVisible = false
                                    }
                            }
                            .frame(minHeight: 44)
                        }

                        Divider()
                        Menu {
                            ForEach(colors, id: \.self) { color in
                                Button {
                                    viewModel.colorHex = color
                                } label: {
                                    Label {
                                        Text("\(color == viewModel.colorHex ? "✓ " : "")\(colorDisplayName(color))")
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
                                Text(colorDisplayName(viewModel.colorHex))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                            }
                            .foregroundStyle(Color.emerald)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
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
                    JapaneseDatePickerRow(title: "開始日", selection: $viewModel.startDate)
                    Toggle("終了日", isOn: $viewModel.hasEndDate)
                    if viewModel.hasEndDate {
                        JapaneseDatePickerRow(title: "終了日の日付", selection: $viewModel.endDate)
                    }
                    Stepper("1日の目標：\(viewModel.targetCount)回", value: $viewModel.targetCount, in: 1...99)
                    Toggle("実施時間設定", isOn: $viewModel.hasDailyTime)
                    if viewModel.hasDailyTime {
                        DatePicker("開始時間", selection: $viewModel.dailyStartTime, displayedComponents: .hourAndMinute)
                        DatePicker("終了時間", selection: $viewModel.dailyEndTime, displayedComponents: .hourAndMinute)
                        LabeledContent("予定時間", value: durationText)
                    }
                    Toggle("目標時間設定", isOn: $viewModel.hasTargetMinutes)
                    if viewModel.hasTargetMinutes {
                        Stepper("1日の目標：\(viewModel.targetMinutes)分", value: $viewModel.targetMinutes, in: 1...1440, step: 5)
                    }
                    Toggle("目標日数を設定", isOn: $viewModel.hasTargetDays)
                    if viewModel.hasTargetDays {
                        Stepper("目標：\(viewModel.targetDays)日", value: $viewModel.targetDays, in: 1...3650)
                    }
                    Toggle("習慣を有効", isOn: $viewModel.isActive)
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

    private var durationText: String {
        let start = Calendar.current.dateComponents([.hour, .minute], from: viewModel.dailyStartTime)
        let end = Calendar.current.dateComponents([.hour, .minute], from: viewModel.dailyEndTime)
        let startMinutes = (start.hour ?? 0) * 60 + (start.minute ?? 0)
        let endMinutes = (end.hour ?? 0) * 60 + (end.minute ?? 0)
        let minutes = (endMinutes - startMinutes + 1440) % 1440
        return minutes >= 60 ? "\(minutes / 60)時間\(minutes % 60 == 0 ? "" : "\(minutes % 60)分")" : "\(minutes)分"
    }

    private func iconDisplayName(_ icon: String) -> String {
        ["checkmark.circle": "チェック", "leaf": "葉", "figure.walk": "運動", "book": "読書", "pencil": "学習", "music.note": "音楽", "heart": "健康", "cup.and.saucer": "休憩", "sparkles": "その他"][icon] ?? "アイコン"
    }

    private var selectedIconDisplayName: String {
        let customText = viewModel.customIconText.trimmingCharacters(in: .whitespacesAndNewlines)
        if viewModel.iconName == "sparkles", !isCustomIconInputVisible, !customText.isEmpty {
            return customText
        }
        return iconDisplayName(viewModel.iconName)
    }

    private func colorDisplayName(_ color: String) -> String {
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
}

private struct JapaneseDatePickerRow: View {
    let title: String
    @Binding var selection: Date
    @State private var isPresented = false

    var body: some View {
        LabeledContent(title) {
            Button(formattedDate) { isPresented = true }
                .foregroundStyle(.primary)
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                DatePicker("日付", selection: $selection, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .padding()
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完了") { isPresented = false }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: selection)
    }
}

private extension Color {
    static let emerald = Color(red: 0.06, green: 0.58, blue: 0.42)
}

#Preview {
    HabitFormView(habit: nil, nextSortOrder: 0)
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
