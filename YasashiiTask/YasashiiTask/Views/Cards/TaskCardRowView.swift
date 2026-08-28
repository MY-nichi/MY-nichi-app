import SwiftUI

struct TaskCardRowView: View {
    let card: TaskCard
    var achievement: TaskAchievement? = nil
    var showsDueDate = true
    var showsExecutionTime = false
    var showsSchedule = false
    var strikesThroughCompletedTitle = true
    var usesSimpleCompletionStatus = false
    var achievementMemo = ""
    var compact = false
    var onToggleCompletion: (() -> Void)?

    private var cardColor: Color {
        let hex = card.colorHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return AppTheme.tint }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var body: some View {
        Group {
            if let onToggleCompletion {
                Button(action: onToggleCompletion) {
                    rowContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilitySummary)
                .accessibilityHint("まあまあ、できた、よくできた、今日はお休みから選びます")
            } else {
                rowContent
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilitySummary)
            }
        }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: compact ? 10 : 12) {
            cardIcon
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: compact ? 2 : 3) {
                Text(card.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .strikethrough(card.isCompleted && strikesThroughCompletedTitle)
                    .lineLimit(compact ? 1 : nil)
                    .fixedSize(horizontal: false, vertical: !compact)

                if !card.detail.isEmpty {
                    Text(card.detail)
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
                .fill(cardColor.opacity(0.55))
                .frame(width: 3)
                .padding(.vertical, 14)
        }
        .contentShape(Rectangle())
    }

    private var cardIcon: some View {
        Group {
            if let achievement {
                AchievementStampView(achievement: achievement, compact: true)
                    .frame(width: compact ? 36 : 40, height: compact ? 36 : 40)
            } else {
                Image(systemName: card.iconName)
                    .font(compact ? .title3 : .title2)
                    .foregroundStyle(cardColor)
                    .frame(width: compact ? 38 : 42, height: compact ? 38 : 42)
                    .background(cardColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var trailingInfo: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Label(
                achievement?.title ?? (usesSimpleCompletionStatus ? (card.isCompleted ? "完了" : "未完了") : (card.isCompleted ? "完了" : "未完了")),
                systemImage: isCompletedStatus ? "checkmark.circle" : "circle"
            )
            if showsExecutionTime, let executionTime {
                Label(executionTime, systemImage: "clock")
            }
            if showsDueDate, let dueDate = card.dueDate {
                Label(dueDate.formatted(date: .numeric, time: .omitted), systemImage: "calendar")
            }
            if showsSchedule, let scheduleText {
                Label(scheduleText, systemImage: "calendar.badge.clock")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(cardColor)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: compact ? 112 : 170, alignment: .trailing)
    }

    private var accessibilitySummary: String {
        let status = achievement?.title ?? (card.isCompleted ? "完了" : "未完了")
        let detail = card.detail.isEmpty ? "" : "、\(card.detail)"
        return "\(card.title)\(detail)、\(status)"
    }

    private var isCompletedStatus: Bool {
        achievement?.countsAsCompletion ?? card.isCompleted
    }

    private var executionTime: String? {
        card.reminderTime?.formatted(date: .omitted, time: .shortened)
    }

    private var scheduleText: String? {
        guard let reminderTime = card.reminderTime else { return nil }
        let time = reminderTime.formatted(date: .omitted, time: .shortened)
        switch card.repeatRule {
        case "weekly":
            return "毎週\(weekdaysText()) \(time)"
        case "biweekly":
            return "隔週\(weekdaysText()) \(time)"
        case "monthly":
            return "毎月\(weekdaysText()) \(time)"
        default:
            if let dueDate = card.dueDate {
                return "\(weekdayText(from: dueDate)) \(time)"
            }
            return time
        }
    }

    private func weekdayText(from date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekdayName(weekday)
    }

    private func weekdaysText() -> String {
        let weekdays = card.repeatWeekdays.isEmpty
            ? [Calendar.current.component(.weekday, from: card.dueDate ?? card.createdAt)]
            : card.repeatWeekdays.sorted()
        return weekdays.map(weekdayName).joined(separator: "・")
    }

    private func weekdayName(_ weekday: Int) -> String {
        [1: "日", 2: "月", 3: "火", 4: "水", 5: "木", 6: "金", 7: "土"][weekday] ?? ""
    }
}
