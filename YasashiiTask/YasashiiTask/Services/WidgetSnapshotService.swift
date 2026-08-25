import Foundation
import WidgetKit

struct TodayWidgetSnapshot: Codable {
    var dateLabel: String
    var habits: [String]
    var tasks: [String]
}

@MainActor
enum WidgetSnapshotService {
    static func save(habits: [Habit], cards: [TaskCard], date: Date = .now, calendar: Calendar = .current) {
        let snapshot = TodayWidgetSnapshot(
            dateLabel: date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(Locale(identifier: "ja_JP"))),
            habits: habits.map(\.title),
            tasks: cards.map(\.title)
        )
        guard let data = try? JSONEncoder().encode(snapshot),
              let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) else { return }
        defaults.set(data, forKey: AppConstants.widgetSnapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
