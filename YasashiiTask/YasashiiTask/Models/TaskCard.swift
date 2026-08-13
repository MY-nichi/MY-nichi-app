import Foundation
import SwiftData

@Model
final class TaskCard {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var memo: String
    var dueDate: Date?
    var startTime: Date?
    var endTime: Date?
    var priority: String
    var iconName: String
    var colorHex: String
    var sortOrder: Int
    var isCompleted: Bool
    var completedAt: Date?
    var repeatRule: String?
    var reminderTime: Date?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var habit: Habit?

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.taskCard)
    var checklistItems: [ChecklistItem]

    @Relationship(deleteRule: .cascade, inverse: \CompletionRecord.taskCard)
    var completionRecords: [CompletionRecord]

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
        reminderTime: Date? = nil,
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
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

        switch repeatRule {
        case "daily":
            return true
        case "weekdays":
            return (2...6).contains(weekday)
        case "weekends":
            return weekday == 1 || weekday == 7
        case "weekly":
            return weekday == calendar.component(.weekday, from: referenceDate)
        case "monthly":
            return calendar.component(.day, from: date) == calendar.component(.day, from: referenceDate)
        default:
            guard let dueDate else { return true }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
}
