import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    var achievement: TaskAchievement? = nil
    var showsActiveStatus = true
    var isCompleted: Bool?
    var showsExecutionTime = false
    var showsSchedule = false
    var achievementMemo = ""
    var streakCount: Int? = nil
    var compact = false

    private var habitColor: Color {
        let hex = habit.colorHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return AppTheme.tint }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 10 : 12) {
            Group {
                if let achievement {
                    AchievementStampView(achievement: achievement, compact: true)
                        .frame(width: compact ? 36 : 40, height: compact ? 36 : 40)
                } else if habit.iconName == "sparkles",
                   let customText = habit.customIconText,
                   !customText.isEmpty {
                    Text(customText)
                        .font(compact ? .subheadline.weight(.semibold) : .headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Image(systemName: habit.iconName)
                        .font(compact ? .title3 : .title2)
                }
            }
                .foregroundStyle(habitColor)
                .frame(width: compact ? 38 : 42, height: compact ? 38 : 42)
                .background(habitColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: compact ? 2 : 3) {
                Text(habit.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(compact ? 1 : nil)
                    .fixedSize(horizontal: false, vertical: !compact)

                if !habit.detail.isEmpty {
                    Text(habit.detail)
                        .font(compact ? .caption : .subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(compact ? 1 : nil)
                        .fixedSize(horizontal: false, vertical: !compact)
                }

                if !achievementMemo.isEmpty {
                    Text(achievementMemo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(compact ? 1 : 2)
                        .fixedSize(horizontal: false, vertical: !compact)
                }

            }

            Spacer(minLength: 6)

            trailingInfo

        }
        .padding(compact ? 10 : 12)
        .polishedCard(cornerRadius: 18)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(habitColor.opacity(0.55))
                .frame(width: 3)
                .padding(.vertical, 14)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var trailingInfo: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if showsActiveStatus {
                Label(
                    habit.isActive ? "有効" : "お休み中",
                    systemImage: habit.isActive ? "checkmark.circle.fill" : "pause.circle.fill"
                )
            }
            if let isCompleted {
                Label(achievement?.title ?? (isCompleted ? "完了" : "未完了"), systemImage: isCompleted ? "checkmark.circle" : "circle")
            }
            if showsExecutionTime, let executionTime {
                Label(executionTime, systemImage: "clock")
            }
            if showsSchedule, let scheduleText {
                Label(scheduleText, systemImage: "calendar.badge.clock")
            }
            if let streakCount {
                Label("継続\(streakCount)日", systemImage: "flame")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(habitColor)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: compact ? 112 : 170, alignment: .trailing)
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
