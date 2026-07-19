import SwiftUI

struct TimelineCardRow: View {
    let card: TaskCard

    private let emerald = Color(red: 0.06, green: 0.58, blue: 0.42)

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(timeText)
                    .font(.caption.monospacedDigit().weight(.semibold))
                Circle()
                    .fill(card.isCompleted ? Color.secondary : emerald)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1, height: 34)
            }
            .frame(width: 58)
            .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 5) {
                Text(card.title)
                    .font(.headline)
                    .strikethrough(card.isCompleted)
                if !card.detail.isEmpty {
                    Text(card.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Label(card.isCompleted ? "完了" : "未完了", systemImage: card.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(card.isCompleted ? .primary : emerald)
            }
            Spacer(minLength: 4)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeText)、\(card.title)、\(card.isCompleted ? "完了" : "未完了")")
    }

    private var timeText: String {
        guard let startTime = card.startTime else { return "時刻なし" }
        let start = startTime.formatted(date: .omitted, time: .shortened)
        guard let endTime = card.endTime else { return start }
        return "\(start)–\(endTime.formatted(date: .omitted, time: .shortened))"
    }
}
