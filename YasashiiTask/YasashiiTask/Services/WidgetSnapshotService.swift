import Foundation
import WidgetKit

struct TodayWidgetItem: Codable {
    var title: String
    var reminderTimeLabel: String?
}

struct TodayWidgetSnapshot: Codable {
    var dateLabel: String
    var habits: [String]
    var tasks: [String]
    var habitItems: [TodayWidgetItem]
    var taskItems: [TodayWidgetItem]
}

@MainActor
enum WidgetSnapshotService {
    static func save(habits: [Habit], cards: [TaskCard], date: Date = .now, calendar: Calendar = .current) {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ja_JP")
        timeFormatter.dateFormat = "H:mm"
        let snapshot = TodayWidgetSnapshot(
            dateLabel: date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(Locale(identifier: "ja_JP"))),
            habits: habits.map(\.title),
            tasks: cards.map(\.title),
            habitItems: habits.map { habit in
                TodayWidgetItem(title: habit.title, reminderTimeLabel: habit.reminderTime.map { timeFormatter.string(from: $0) })
            },
            taskItems: cards.map { card in
                TodayWidgetItem(title: card.title, reminderTimeLabel: card.reminderTime.map { timeFormatter.string(from: $0) })
            }
        )
        guard let data = try? JSONEncoder().encode(snapshot),
              let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) else { return }
        defaults.set(data, forKey: AppConstants.widgetSnapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
