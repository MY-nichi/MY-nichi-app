import SwiftUI

struct WeeklyProgressChart: View {
    let values: [DailyCompletion]

    private let emerald = Color(red: 0.06, green: 0.58, blue: 0.42)
    private var maximum: Int { max(values.map(\.count).max() ?? 0, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 9) {
            ForEach(values) { value in
                VStack(spacing: 6) {
                    Text("\(value.count)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(value.count == 0 ? Color(.tertiarySystemFill) : emerald)
                        .frame(height: max(8, 82 * CGFloat(value.count) / CGFloat(maximum)))
                    Text(value.date.formatted(.dateTime.weekday(.narrow).locale(Locale(identifier: "ja_JP"))))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(value.date.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "ja_JP"))))、\(value.count)件完了")
            }
        }
        .frame(height: 125, alignment: .bottom)
    }
}
