import SwiftUI

struct TaskCardRowView: View {
    let card: TaskCard
    var achievement: TaskAchievement? = nil
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
                    .strikethrough(card.isCompleted)
                    .fixedSize(horizontal: false, vertical: true)

                if !card.detail.isEmpty {
                    Text(card.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    Label(
                        achievement?.title ?? (card.isCompleted ? "完了" : "未完了"),
                        systemImage: card.isCompleted ? "checkmark.circle" : "circle"
                    )
                    if let dueDate = card.dueDate {
                        Label(dueDate.formatted(date: .numeric, time: .omitted), systemImage: "calendar")
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
}
