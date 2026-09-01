import SwiftUI
import WidgetKit

private enum WidgetConstants {
    static let appGroupIdentifier = "group.jp.kishiko.YasashiiTask"
    static let widgetSnapshotKey = "todayWidgetSnapshot"
    static let appURL = URL(string: "mynichi://today")
}

private struct TodayWidgetItem: Codable {
    var title: String
    var reminderTimeLabel: String?
}

private struct TodayWidgetSnapshot: Codable {
    var dateLabel: String
    var habits: [String]
    var tasks: [String]
    var habitItems: [TodayWidgetItem]
    var taskItems: [TodayWidgetItem]

    init(dateLabel: String, habits: [String], tasks: [String], habitItems: [TodayWidgetItem]? = nil, taskItems: [TodayWidgetItem]? = nil) {
        self.dateLabel = dateLabel
        self.habits = habits
        self.tasks = tasks
        self.habitItems = habitItems ?? habits.map { TodayWidgetItem(title: $0, reminderTimeLabel: nil) }
        self.taskItems = taskItems ?? tasks.map { TodayWidgetItem(title: $0, reminderTimeLabel: nil) }
    }

    private enum CodingKeys: String, CodingKey {
        case dateLabel, habits, tasks, habitItems, taskItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateLabel = try container.decodeIfPresent(String.self, forKey: .dateLabel) ?? "今日"
        habits = try container.decodeIfPresent([String].self, forKey: .habits) ?? []
        tasks = try container.decodeIfPresent([String].self, forKey: .tasks) ?? []
        habitItems = try container.decodeIfPresent([TodayWidgetItem].self, forKey: .habitItems) ?? habits.map { TodayWidgetItem(title: $0, reminderTimeLabel: nil) }
        taskItems = try container.decodeIfPresent([TodayWidgetItem].self, forKey: .taskItems) ?? tasks.map { TodayWidgetItem(title: $0, reminderTimeLabel: nil) }
    }
}

private struct Entry: TimelineEntry {
    let date: Date
    let snapshot: TodayWidgetSnapshot
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(
            date: .now,
            snapshot: TodayWidgetSnapshot(
                dateLabel: "今日",
                habits: ["ピアノ"],
                tasks: ["英語"],
                habitItems: [TodayWidgetItem(title: "ピアノ", reminderTimeLabel: "7:00")],
                taskItems: [TodayWidgetItem(title: "英語", reminderTimeLabel: "21:00")]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [Entry(date: .now, snapshot: loadSnapshot())], policy: .after(.now.addingTimeInterval(900))))
    }

    private func loadSnapshot() -> TodayWidgetSnapshot {
        guard let data = UserDefaults(suiteName: WidgetConstants.appGroupIdentifier)?.data(forKey: WidgetConstants.widgetSnapshotKey),
              let snapshot = try? JSONDecoder().decode(TodayWidgetSnapshot.self, from: data) else {
            return TodayWidgetSnapshot(dateLabel: "今日", habits: [], tasks: [])
        }
        return snapshot
    }
}

private struct YasashiiTaskWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: Entry

    private var hasItems: Bool {
        !entry.snapshot.habitItems.isEmpty || !entry.snapshot.taskItems.isEmpty
    }

    private var itemLimit: Int {
        family == .systemSmall ? 2 : 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 9) {
            header

            if hasItems {
                content
            } else {
                emptyState
            }

            Spacer(minLength: 0)
        }
        .padding(family == .systemSmall ? 11 : 14)
        .containerBackground(widgetBackground, for: .widget)
        .widgetURL(WidgetConstants.appURL)
    }

    private var header: some View {
        HStack {
            AppMark(size: family == .systemSmall ? 32 : 36)
            Spacer(minLength: 0)
        }
        .frame(height: family == .systemSmall ? 32 : 36)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            widgetSection("習慣", icon: "leaf.fill", items: entry.snapshot.habitItems)
            widgetSection("タスク", icon: "checkmark.square.fill", items: entry.snapshot.taskItems)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("今日はゆっくり")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text("習慣とタスクを追加すると表示されます")
                .font(itemFont)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.42, green: 0.82, blue: 0.70).opacity(0.75), lineWidth: 1)
        }
    }

    private func widgetSection(_ title: String, icon: String, items: [TodayWidgetItem]) -> some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 3 : 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: family == .systemSmall ? 9 : 10, weight: .bold))
                Text(title)
                    .font(.system(size: family == .systemSmall ? 10 : 11, weight: .black, design: .rounded))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color(red: 0.00, green: 0.55, blue: 0.40))

            if items.isEmpty {
                Text("なし")
                    .font(itemFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: family == .systemSmall ? 2 : 3) {
                    ForEach(Array(items.prefix(itemLimit).enumerated()), id: \.offset) { _, item in
                        itemRow(item)
                    }
                }
            }
        }
        .padding(.horizontal, family == .systemSmall ? 9 : 11)
        .padding(.vertical, family == .systemSmall ? 6 : 8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.42, green: 0.82, blue: 0.70).opacity(0.72), lineWidth: 1)
        }
        .shadow(color: Color(red: 0.03, green: 0.34, blue: 0.25).opacity(0.09), radius: 6, x: 0, y: 3)
    }

    private func itemRow(_ item: TodayWidgetItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Circle()
                .fill(Color(red: 0.00, green: 0.55, blue: 0.40))
                .frame(width: 4, height: 4)
            Text(item.title)
                .font(itemFont)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .allowsTightening(true)
            Spacer(minLength: 4)
            if let reminderTimeLabel = item.reminderTimeLabel, !reminderTimeLabel.isEmpty {
                Text(reminderTimeLabel)
                    .font(timeFont)
                    .foregroundStyle(Color(red: 0.00, green: 0.47, blue: 0.35))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var itemFont: Font {
        .system(size: family == .systemSmall ? 13 : 15, weight: .bold, design: .rounded)
    }

    private var timeFont: Font {
        .system(size: family == .systemSmall ? 10 : 11, weight: .bold, design: .rounded).monospacedDigit()
    }

    private var widgetBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.77, green: 0.98, blue: 0.89),
                Color(red: 0.89, green: 1.00, blue: 0.95),
                Color(red: 0.96, green: 1.00, blue: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct AppMark: View {
    let size: CGFloat

    var body: some View {
        Image("WidgetLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.24)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: Color(red: 0.03, green: 0.34, blue: 0.25).opacity(0.16), radius: 5, x: 0, y: 3)
    }
}

struct YasashiiTaskWidget: Widget {
    let kind = "YasashiiTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YasashiiTaskWidgetView(entry: entry)
        }
        .configurationDisplayName("MY-nichi")
        .description("今日の習慣とタスクを確認します。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct YasashiiTaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        YasashiiTaskWidget()
    }
}
