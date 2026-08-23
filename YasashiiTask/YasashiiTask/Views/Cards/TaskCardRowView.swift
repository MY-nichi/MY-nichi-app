import SwiftUI

struct TaskCardRowView: View {
    let card: TaskCard
    var achievement: TaskAchievement? = nil
    var showsDueDate = true
    var showsExecutionTime = false
    var showsSchedule = false
    var strikesThroughCompletedTitle = true
    var usesSimpleCompletionStatus = false
    var onToggleCompletion: (() -> Void)?

    private var cardColor: Color {
        let hex = card.colorHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return Color(red: 0.00, green: 0.45, blue: 0.30) }
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
                .accessibilityHint("もうちょっと、できた、よくできたから選びます")
            } else {
                rowContent
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilitySummary)
            }
        }
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 14) {
            cardIcon
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(card.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .strikethrough(card.isCompleted && strikesThroughCompletedTitle)
                    .fixedSize(horizontal: false, vertical: true)

                if !card.detail.isEmpty {
                    Text(card.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    Label(
                        usesSimpleCompletionStatus ? (card.isCompleted ? "完了" : "未完了") : achievement?.title ?? (card.isCompleted ? "完了" : "未完了"),
                        systemImage: card.isCompleted ? "checkmark.circle" : "circle"
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
                .foregroundStyle(card.isCompleted ? .primary : cardColor)
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
    }

    private var cardIcon: some View {
        Group {
            if let achievement {
                AchievementStampView(achievement: achievement, compact: true)
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: card.iconName)
                    .font(.title2)
                    .foregroundStyle(cardColor)
                    .frame(width: 44, height: 44)
                    .background(cardColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var accessibilitySummary: String {
        let status = achievement?.title ?? (card.isCompleted ? "完了" : "未完了")
        let detail = card.detail.isEmpty ? "" : "、\(card.detail)"
        return "\(card.title)\(detail)、\(status)"
    }

    private var executionTime: String? {
        card.reminderTime?.formatted(date: .omitted, time: .shortened)
    }

    private var scheduleText: String? {
        guard let reminderTime = card.reminderTime else { return nil }
        let time = reminderTime.formatted(date: .omitted, time: .shortened)
        switch card.repeatRule {
        case "daily":
            return "毎日 \(time)"
        case "weekdays":
            return "平日 \(time)"
        case "weekends":
            return "週末 \(time)"
        case "weekly":
            let weekday = weekdayText(from: card.dueDate ?? card.createdAt)
            return "毎週\(weekday) \(time)"
        case "monthly":
            let day = Calendar.current.component(.day, from: card.dueDate ?? card.createdAt)
            return "毎月\(day)日 \(time)"
        default:
            if let dueDate = card.dueDate {
                return "\(weekdayText(from: dueDate)) \(time)"
            }
            return time
        }
    }

    private func weekdayText(from date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return [1: "日", 2: "月", 3: "火", 4: "水", 5: "木", 6: "金", 7: "土"][weekday] ?? ""
    }
}
