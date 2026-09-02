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

        let habitItems = habits
            .filter { !hasTodayAchievement(for: $0, date: date, calendar: calendar) }
            .sorted { compareReminderOrder($0.reminderTime, $1.reminderTime, firstSortOrder: $0.sortOrder, secondSortOrder: $1.sortOrder, calendar: calendar) }
            .map { habit in
                TodayWidgetItem(title: habit.title, reminderTimeLabel: habit.reminderTime.map { timeFormatter.string(from: $0) })
            }

        let taskItems = cards
            .filter { !hasTodayAchievement(for: $0, date: date, calendar: calendar) }
            .sorted { compareReminderOrder($0.reminderTime, $1.reminderTime, firstSortOrder: $0.sortOrder, secondSortOrder: $1.sortOrder, calendar: calendar) }
            .map { card in
                TodayWidgetItem(title: card.title, reminderTimeLabel: card.reminderTime.map { timeFormatter.string(from: $0) })
            }

        let snapshot = TodayWidgetSnapshot(
            dateLabel: date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(Locale(identifier: "ja_JP"))),
            habits: habitItems.map(\.title),
            tasks: taskItems.map(\.title),
            habitItems: habitItems,
            taskItems: taskItems
        )
        guard let data = try? JSONEncoder().encode(snapshot),
              let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) else { return }
        defaults.set(data, forKey: AppConstants.widgetSnapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func hasTodayAchievement(for habit: Habit, date: Date, calendar: Calendar) -> Bool {
        (habit.completionRecords ?? []).contains {
            $0.taskCard == nil && calendar.isDate($0.targetDate, inSameDayAs: date) && $0.achievement != nil
        }
    }

    private static func hasTodayAchievement(for card: TaskCard, date: Date, calendar: Calendar) -> Bool {
        let hasRecord = (card.completionRecords ?? []).contains {
            calendar.isDate($0.targetDate, inSameDayAs: date) && $0.achievement != nil
        }
        if hasRecord { return true }
        guard card.repeatRule == nil, card.isCompleted, let completedAt = card.completedAt else { return false }
        return calendar.isDate(completedAt, inSameDayAs: date)
    }

    private static func compareReminderOrder(
        _ first: Date?,
        _ second: Date?,
        firstSortOrder: Int,
        secondSortOrder: Int,
        calendar: Calendar
    ) -> Bool {
        let firstValue = reminderSortValue(first, calendar: calendar)
        let secondValue = reminderSortValue(second, calendar: calendar)
        if firstValue != secondValue { return firstValue < secondValue }
        return firstSortOrder < secondSortOrder
    }

    private static func reminderSortValue(_ reminderTime: Date?, calendar: Calendar) -> Int {
        guard let reminderTime else { return Int.max }
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
