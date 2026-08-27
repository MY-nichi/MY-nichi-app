import SwiftUI

struct TodaySummaryView: View {
    let summary: TodaySummary
    var compact = false

    private let emerald = AppTheme.tint

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日の達成率")
                        .font(compact ? .caption.weight(.semibold) : .subheadline)
                        .foregroundStyle(.primary)
                    Text("\(summary.achievementRate)%")
                        .font(compact ? .title2.bold() : .largeTitle.bold())
                        .foregroundStyle(emerald)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(AppTheme.chipBackground, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: Double(summary.achievementRate) / 100)
                        .stroke(emerald, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(emerald)
                }
                    .frame(width: compact ? 38 : 48, height: compact ? 38 : 48)
                    .accessibilityLabel("今日の達成率")
                    .accessibilityValue("\(summary.achievementRate)パーセント")
            }

            HStack(spacing: 8) {
                summaryItem("未完了", count: summary.incomplete, icon: "circle")
                summaryItem("完了", count: summary.completed, icon: "checkmark.circle.fill")
                summaryItem("期限超過", count: summary.overdue, icon: "exclamationmark.triangle.fill")
            }
        }
        .padding(compact ? 14 : 18)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private func summaryItem(_ title: String, count: Int, icon: String) -> some View {
        VStack(spacing: compact ? 3 : 5) {
            Label("\(count)", systemImage: icon)
                .font(compact ? .subheadline.weight(.semibold) : .headline)
            Text(title)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)、\(count)件")
    }
}
