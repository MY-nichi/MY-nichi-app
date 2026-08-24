import Foundation
import UserNotifications

enum NotificationService {
    @MainActor
    static func updateReminder(for card: TaskCard, hapticsEnabled: Bool = true) async {
        let cardID = card.id
        let title = card.title
        let detail = card.detail
        let reminderTime = card.reminderTime
        let repeatRule = card.repeatRule
        let repeatWeekdays = card.repeatWeekdays
        let referenceDate = card.dueDate ?? card.createdAt
        let center = UNUserNotificationCenter.current()
        let prefix = "task-card-\(cardID.uuidString)-"
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        guard let reminderTime else { return }
        do {
            guard try await center.requestAuthorization(options: [.alert, .sound, .badge]) else { return }
            let calendar = Calendar.current
            let time = calendar.dateComponents([.hour, .minute], from: reminderTime)
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = detail.isEmpty ? "今日のタスクの時間です。" : detail
            content.sound = hapticsEnabled ? .default : nil

            switch repeatRule {
            case "weekdaySelection":
                try await addWeeklyRequests(repeatWeekdays, time: time, prefix: prefix, content: content, center: center)
            case "weekdays":
                try await addWeeklyRequests([2, 3, 4, 5, 6], time: time, prefix: prefix, content: content, center: center)
            case "weekends":
                try await addWeeklyRequests([1, 7], time: time, prefix: prefix, content: content, center: center)
            case "weekly":
                let weekdays = repeatWeekdays.isEmpty ? [calendar.component(.weekday, from: referenceDate)] : repeatWeekdays
                try await addWeeklyRequests(weekdays, time: time, prefix: prefix, content: content, center: center)
            case "biweekly":
                let weekdays = repeatWeekdays.isEmpty ? [calendar.component(.weekday, from: referenceDate)] : repeatWeekdays
                for weekday in weekdays {
                    var fireDate = nextBiweeklyDate(from: referenceDate, weekday: weekday, time: time, calendar: calendar)
                    if fireDate <= .now {
                        fireDate = calendar.date(byAdding: .day, value: 14, to: fireDate) ?? fireDate
                    }
                    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                    try await addRequest(prefix + "biweekly-\(weekday)", components: components, repeats: false, content: content, center: center)
                }
            case "monthly":
                let weekdays = repeatWeekdays.isEmpty ? [calendar.component(.weekday, from: referenceDate)] : repeatWeekdays
                for weekday in weekdays {
                    var components = time
                    components.weekday = weekday
                    components.weekOfMonth = calendar.component(.weekOfMonth, from: referenceDate)
                    try await addRequest(prefix + "monthly-\(weekday)", components: components, repeats: true, content: content, center: center)
                }
            case "daily":
                try await addRequest(prefix + "daily", components: time, repeats: true, content: content, center: center)
            default:
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
                dateComponents.hour = time.hour
                dateComponents.minute = time.minute
                var fireDate = calendar.date(from: dateComponents) ?? reminderTime
                if fireDate <= .now, card.dueDate == nil {
                    fireDate = calendar.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
                }
                let oneTimeComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                try await addRequest(prefix + "once", components: oneTimeComponents, repeats: false, content: content, center: center)
            }
        } catch {
            // 通知が許可されなくても、カード自体の保存は成功させます。
        }
    }

    @MainActor
    static func updateReminder(for habit: Habit, hapticsEnabled: Bool = true) async {
        let habitID = habit.id
        let title = habit.title
        let detail = habit.detail
        let reminderTime = habit.reminderTime
        let activeDays = habit.activeDays
        let center = UNUserNotificationCenter.current()
        let prefix = "habit-\(habitID.uuidString)-"
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        guard habit.isActive, !habit.isArchived, let reminderTime else { return }
        do {
            guard try await center.requestAuthorization(options: [.alert, .sound, .badge]) else { return }
            let calendar = Calendar.current
            let time = calendar.dateComponents([.hour, .minute], from: reminderTime)
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = detail.isEmpty ? "習慣の時間です。" : detail
            content.sound = hapticsEnabled ? .default : nil

            if activeDays.isEmpty {
                try await addRequest(prefix + "daily", components: time, repeats: true, content: content, center: center)
            } else {
                try await addWeeklyRequests(activeDays, time: time, prefix: prefix, content: content, center: center)
            }
        } catch {
            // 通知が許可されなくても、習慣自体の保存は成功させます。
        }
    }

    static func removeTaskReminder(for cardID: UUID) {
        removeRequests(prefix: "task-card-\(cardID.uuidString)-")
    }

    static func removeHabitReminder(for habitID: UUID) {
        removeRequests(prefix: "habit-\(habitID.uuidString)-")
    }

    private static func removeRequests(prefix: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let identifiers = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    private static func addWeeklyRequests(
        _ weekdays: [Int],
        time: DateComponents,
        prefix: String,
        content: UNNotificationContent,
        center: UNUserNotificationCenter
    ) async throws {
        for weekday in weekdays {
            var components = time
            components.weekday = weekday
            try await addRequest(prefix + String(weekday), components: components, repeats: true, content: content, center: center)
        }
    }

    private static func addRequest(
        _ identifier: String,
        components: DateComponents,
        repeats: Bool,
        content: UNNotificationContent,
        center: UNUserNotificationCenter
    ) async throws {
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private static func nextBiweeklyDate(
        from referenceDate: Date,
        weekday: Int,
        time: DateComponents,
        calendar: Calendar
    ) -> Date {
        var candidate = calendar.startOfDay(for: referenceDate)
        while true {
            if calendar.component(.weekday, from: candidate) == weekday,
               let dayDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: referenceDate), to: candidate).day,
               dayDifference >= 0,
               (dayDifference / 7).isMultiple(of: 2) {
                var components = calendar.dateComponents([.year, .month, .day], from: candidate)
                components.hour = time.hour
                components.minute = time.minute
                let fireDate = calendar.date(from: components) ?? candidate
                if fireDate > .now { return fireDate }
            }
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
    }
}
