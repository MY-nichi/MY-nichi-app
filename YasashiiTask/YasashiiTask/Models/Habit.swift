import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var title: String = ""
    var detail: String = ""
    var category: String = ""
    var iconName: String = "checkmark.circle"
    var customIconText: String?
    var colorHex: String = "#10B981"
    var startDate: Date = Date()
    var endDate: Date?
    var activeDays: [Int] = []
    var reminderTime: Date?
    var targetCount: Int = 1
    var dailyStartTime: Date?
    var dailyEndTime: Date?
    var targetMinutes: Int?
    var targetDays: Int?
    var sortOrder: Int = 0
    var isActive: Bool = true
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \TaskCard.habit)
    var taskCards: [TaskCard]? = []

    @Relationship(deleteRule: .cascade, inverse: \CompletionRecord.habit)
    var completionRecords: [CompletionRecord]? = []

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        category: String = "",
        iconName: String = "checkmark.circle",
        customIconText: String? = nil,
        colorHex: String = "#10B981",
        startDate: Date = Date(),
        endDate: Date? = nil,
        activeDays: [Int] = [],
        reminderTime: Date? = nil,
        targetCount: Int = 1,
        dailyStartTime: Date? = nil,
        dailyEndTime: Date? = nil,
        targetMinutes: Int? = nil,
        targetDays: Int? = nil,
        sortOrder: Int = 0,
        isActive: Bool = true,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.iconName = iconName
        self.customIconText = customIconText
        self.colorHex = colorHex
        self.startDate = startDate
        self.endDate = endDate
        self.activeDays = activeDays
        self.reminderTime = reminderTime
        self.targetCount = max(1, targetCount)
        self.dailyStartTime = dailyStartTime
        self.dailyEndTime = dailyEndTime
        self.targetMinutes = targetMinutes
        self.targetDays = targetDays
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.taskCards = []
        self.completionRecords = []
    }

    var plannedDurationMinutes: Int? {
        guard let dailyStartTime, let dailyEndTime else { return nil }
        let minutes = Int(dailyEndTime.timeIntervalSince(dailyStartTime) / 60)
        return minutes >= 0 ? minutes : minutes + (24 * 60)
    }
}
