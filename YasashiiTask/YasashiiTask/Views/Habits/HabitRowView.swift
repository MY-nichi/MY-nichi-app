import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    var achievement: TaskAchievement? = nil
    var showsActiveStatus = true
    var isCompleted: Bool?
    var showsExecutionTime = false
    var showsSchedule = false

    private var habitColor: Color {
        let hex = habit.colorHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return Color(red: 0.00, green: 0.45, blue: 0.30) }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if let achievement {
                    AchievementStampView(achievement: achievement, compact: true)
                        .frame(width: 44, height: 44)
                } else if habit.iconName == "sparkles",
                   let customText = habit.customIconText,
                   !customText.isEmpty {
                    Text(customText)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Image(systemName: habit.iconName)
                        .font(.title2)
                }
            }
                .foregroundStyle(habitColor)
                .frame(width: 44, height: 44)
                .background(habitColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !habit.detail.isEmpty {
                    Text(habit.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if showsActiveStatus {
                    Label(
                        habit.isActive ? "有効" : "お休み中",
                        systemImage: habit.isActive ? "checkmark.circle.fill" : "pause.circle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(habit.isActive ? habitColor : .secondary)
                }

                if let isCompleted {
                    Label(achievement?.title ?? (isCompleted ? "完了" : "未完了"), systemImage: isCompleted ? "checkmark.circle" : "circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isCompleted ? .primary : habitColor)
                }

                if showsExecutionTime, let executionTime {
                    Label(executionTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if showsSchedule, let scheduleText {
                    Label(scheduleText, systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            }

            Spacer(minLength: 8)

        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let detail = habit.detail.isEmpty ? "" : "、\(habit.detail)"
        let status = habit.isActive ? "有効" : "お休み中"
        return "\(habit.title)\(detail)、\(status)"
    }

    private var executionTime: String? {
        habit.reminderTime?.formatted(date: .omitted, time: .shortened)
    }

    private var scheduleText: String? {
        guard let reminderTime = habit.reminderTime else { return nil }
        let days = habit.activeDays.isEmpty ? "毎日" : habit.activeDays.sorted().compactMap(weekdayName).joined(separator: "・")
        return "\(days) \(reminderTime.formatted(date: .omitted, time: .shortened))"
    }

    private func weekdayName(_ weekday: Int) -> String? {
        [1: "日", 2: "月", 3: "火", 4: "水", 5: "木", 6: "金", 7: "土"][weekday]
    }
}
