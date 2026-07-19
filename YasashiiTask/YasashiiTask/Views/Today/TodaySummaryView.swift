import SwiftUI

struct TodaySummaryView: View {
    let summary: TodaySummary

    private let emerald = Color(red: 0.00, green: 0.45, blue: 0.30)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日の達成率")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("\(summary.achievementRate)%")
                        .font(.largeTitle.bold())
                        .foregroundStyle(emerald)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: Double(summary.achievementRate) / 100)
                        .stroke(emerald, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(emerald)
                }
                    .frame(width: 48, height: 48)
                    .accessibilityLabel("今日の達成率")
                    .accessibilityValue("\(summary.achievementRate)パーセント")
            }

            HStack(spacing: 8) {
                summaryItem("未完了", count: summary.incomplete, icon: "circle")
                summaryItem("完了", count: summary.completed, icon: "checkmark.circle.fill")
                summaryItem("期限超過", count: summary.overdue, icon: "exclamationmark.triangle.fill")
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func summaryItem(_ title: String, count: Int, icon: String) -> some View {
        VStack(spacing: 5) {
            Label("\(count)", systemImage: icon)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)、\(count)件")
    }
}
