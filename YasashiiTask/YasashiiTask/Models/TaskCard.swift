import Foundation
import SwiftData

@Model
final class TaskCard {
    var id: UUID = UUID()
    var title: String = ""
    var detail: String = ""
    var memo: String = ""
    var dueDate: Date?
    var startTime: Date?
    var endTime: Date?
    var priority: String = "normal"
    var iconName: String = "rectangle.stack"
    var colorHex: String = "#10B981"
    var sortOrder: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date?
    var repeatRule: String?
    var repeatWeekdays: [Int] = []
    var reminderTime: Date?
    var tags: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var habit: Habit?

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.taskCard)
    var checklistItems: [ChecklistItem]? = []

    @Relationship(deleteRule: .cascade, inverse: \CompletionRecord.taskCard)
    var completionRecords: [CompletionRecord]? = []

    init(
        id: UUID = UUID(),
        habit: Habit? = nil,
        title: String,
        detail: String = "",
        memo: String = "",
        dueDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        priority: String = "normal",
        iconName: String = "rectangle.stack",
        colorHex: String = "#10B981",
        sortOrder: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        repeatRule: String? = nil,
        repeatWeekdays: [Int] = [],
        reminderTime: Date? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.habit = habit
        self.title = title
        self.detail = detail
        self.memo = memo
        self.dueDate = dueDate
        self.startTime = startTime
        self.endTime = endTime
        self.priority = priority
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.repeatRule = repeatRule
        self.repeatWeekdays = repeatWeekdays
        self.reminderTime = reminderTime
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.checklistItems = []
        self.completionRecords = []
    }

    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        let referenceDate = dueDate ?? createdAt
        let weekday = calendar.component(.weekday, from: date)
        let selectedWeekdays = repeatWeekdays.isEmpty ? [calendar.component(.weekday, from: referenceDate)] : repeatWeekdays

        switch repeatRule {
        case "daily":
            return true
        case "weekdaySelection":
            return repeatWeekdays.contains(weekday)
        case "weekdays":
            return (2...6).contains(weekday)
        case "weekends":
            return weekday == 1 || weekday == 7
        case "weekly":
            return selectedWeekdays.contains(weekday)
        case "biweekly":
            guard selectedWeekdays.contains(weekday),
                  let dayDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: referenceDate), to: calendar.startOfDay(for: date)).day,
                  dayDifference >= 0 else { return false }
            return (dayDifference / 7).isMultiple(of: 2)
        case "monthly":
            return selectedWeekdays.contains(weekday) &&
                calendar.component(.weekOfMonth, from: date) == calendar.component(.weekOfMonth, from: referenceDate)
        default:
            guard let dueDate else { return true }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
}
