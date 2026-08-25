import SwiftUI
import WidgetKit

private enum WidgetConstants {
    static let appGroupIdentifier = "group.jp.kishiko.YasashiiTask"
    static let widgetSnapshotKey = "todayWidgetSnapshot"
    static let appURL = URL(string: "mynichi://today")
}

private struct TodayWidgetSnapshot: Codable {
    var dateLabel: String
    var habits: [String]
    var tasks: [String]
}

private struct Entry: TimelineEntry {
    let date: Date
    let snapshot: TodayWidgetSnapshot
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, snapshot: TodayWidgetSnapshot(dateLabel: "今日", habits: ["習慣"], tasks: ["タスク"]))
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
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.snapshot.dateLabel)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            widgetSection("習慣", items: entry.snapshot.habits)
            widgetSection("タスク", items: entry.snapshot.tasks)
            Spacer(minLength: 0)
        }
        .containerBackground(Color(red: 0.92, green: 0.99, blue: 0.97), for: .widget)
        .widgetURL(WidgetConstants.appURL)
    }

    private func widgetSection(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2.bold())
            if items.isEmpty {
                Text("なし").font(.caption2).foregroundStyle(.secondary)
            } else {
                ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, item in
                    Text("・\(item)")
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        }
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
