import SwiftUI

struct TaskCardRowView: View {
    let card: TaskCard
    var onToggleCompletion: (() -> Void)?

    private let emerald = Color(red: 0.00, green: 0.45, blue: 0.30)

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let onToggleCompletion {
                Button(action: onToggleCompletion) {
                    cardIcon
                }
                .buttonStyle(.plain)
                .accessibilityLabel(card.isCompleted ? "未完了に戻す" : "完了にする")
                .accessibilityHint("カードの完了状態を切り替えます")
            } else {
                cardIcon
                    .accessibilityHidden(true)
            }

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
                        card.isCompleted ? "完了" : "未完了",
                        systemImage: card.isCompleted ? "checkmark.circle" : "circle"
                    )
                    if let dueDate = card.dueDate {
                        Label(dueDate.formatted(date: .numeric, time: .omitted), systemImage: "calendar")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(card.isCompleted ? .primary : emerald)
            }

            Spacer(minLength: 8)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
        .accessibilityElement(children: onToggleCompletion == nil ? .combine : .contain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("ダブルタップすると編集できます")
    }

    private var cardIcon: some View {
        Image(systemName: card.isCompleted ? "checkmark.circle.fill" : card.iconName)
            .font(.title2)
            .foregroundStyle(card.isCompleted ? .secondary : emerald)
            .frame(width: 44, height: 44)
            .background(
                (card.isCompleted ? Color.secondary : emerald).opacity(0.12),
                in: RoundedRectangle(cornerRadius: 12)
            )
    }

    private var accessibilitySummary: String {
        let status = card.isCompleted ? "完了" : "未完了"
        let detail = card.detail.isEmpty ? "" : "、\(card.detail)"
        return "\(card.title)\(detail)、\(status)"
    }
}
