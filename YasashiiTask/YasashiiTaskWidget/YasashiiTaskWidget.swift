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
        family == .systemSmall ? 1 : 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 7) {
            header

            if hasItems {
                content
            } else {
                emptyState
            }

            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(
            top: family == .systemSmall ? 16 : 18,
            leading: family == .systemSmall ? 4 : 7,
            bottom: family == .systemSmall ? 7 : 9,
            trailing: family == .systemSmall ? 4 : 7
        ))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(widgetBackground, for: .widget)
        .widgetURL(WidgetConstants.appURL)
    }

    private var header: some View {
        HStack {
            AppMark(size: family == .systemSmall ? 34 : 38)
            Spacer(minLength: 0)
        }
        .frame(height: family == .systemSmall ? 34 : 38)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 7) {
            widgetSection("習慣", icon: "leaf.fill", items: entry.snapshot.habitItems)
            widgetSection("タスク", icon: "checkmark.square.fill", items: entry.snapshot.taskItems)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日はゆっくり")
                .font(.system(size: family == .systemSmall ? 17 : 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("予定はありません")
                .font(.system(size: family == .systemSmall ? 13 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color(red: 0.03, green: 0.34, blue: 0.25).opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private func widgetSection(_ title: String, icon: String, items: [TodayWidgetItem]) -> some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: family == .systemSmall ? 10 : 11, weight: .black))
                Text(title)
                    .font(.system(size: family == .systemSmall ? 10 : 11, weight: .black, design: .rounded))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white.opacity(0.82))

            if items.isEmpty {
                Text("なし")
                    .font(itemFont)
                    .foregroundStyle(.white.opacity(0.80))
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
        .padding(.horizontal, family == .systemSmall ? 12 : 14)
        .padding(.vertical, family == .systemSmall ? 5 : 7)
        .frame(maxWidth: .infinity, minHeight: family == .systemSmall ? 48 : 56, alignment: .topLeading)
        .background(sectionBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(red: 0.03, green: 0.34, blue: 0.25).opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private func itemRow(_ item: TodayWidgetItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(item.title)
                .font(itemFont)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .allowsTightening(true)
            Spacer(minLength: 5)
            if let reminderTimeLabel = item.reminderTimeLabel, !reminderTimeLabel.isEmpty {
                Text(reminderTimeLabel)
                    .font(timeFont)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
    }

    private var itemFont: Font {
        .system(size: family == .systemSmall ? 18 : 20, weight: .black, design: .rounded)
    }

    private var timeFont: Font {
        .system(size: family == .systemSmall ? 12 : 13, weight: .black, design: .rounded).monospacedDigit()
    }

    private var sectionBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.00, green: 0.52, blue: 0.39).opacity(0.88),
                Color(red: 0.00, green: 0.42, blue: 0.33).opacity(0.82)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var widgetBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.70, green: 0.97, blue: 0.86),
                Color(red: 0.84, green: 1.00, blue: 0.93),
                Color(red: 0.92, green: 1.00, blue: 0.87)
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
            .shadow(color: Color(red: 0.03, green: 0.34, blue: 0.25).opacity(0.18), radius: 6, x: 0, y: 3)
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
        .contentMarginsDisabled()
    }
}

@main
struct YasashiiTaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        YasashiiTaskWidget()
    }
}
