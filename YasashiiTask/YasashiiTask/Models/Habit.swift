import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var category: String
    var iconName: String
    var colorHex: String
    var startDate: Date
    var endDate: Date?
    var activeDays: [Int]
    var reminderTime: Date?
    var targetCount: Int
    var sortOrder: Int
    var isActive: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TaskCard.habit)
    var taskCards: [TaskCard]

    @Relationship(deleteRule: .cascade, inverse: \CompletionRecord.habit)
    var completionRecords: [CompletionRecord]

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        category: String = "",
        iconName: String = "checkmark.circle",
        colorHex: String = "#10B981",
        startDate: Date = .now,
        endDate: Date? = nil,
        activeDays: [Int] = [],
        reminderTime: Date? = nil,
        targetCount: Int = 1,
        sortOrder: Int = 0,
        isActive: Bool = true,
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.iconName = iconName
        self.colorHex = colorHex
        self.startDate = startDate
        self.endDate = endDate
        self.activeDays = activeDays
        self.reminderTime = reminderTime
        self.targetCount = max(1, targetCount)
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.taskCards = []
        self.completionRecords = []
    }
}
