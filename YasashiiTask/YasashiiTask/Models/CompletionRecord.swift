import Foundation
import SwiftData

@Model
final class CompletionRecord {
    @Attribute(.unique) var id: UUID
    var targetDate: Date
    var completedAt: Date?
    var status: String
    var memo: String
    var habit: Habit?
    var taskCard: TaskCard?

    init(
        id: UUID = UUID(),
        habit: Habit? = nil,
        taskCard: TaskCard? = nil,
        targetDate: Date,
        completedAt: Date? = nil,
        status: String = "pending",
        memo: String = ""
    ) {
        self.id = id
        self.habit = habit
        self.taskCard = taskCard
        self.targetDate = targetDate
        self.completedAt = completedAt
        self.status = status
        self.memo = memo
    }
}

extension CompletionRecord {
    var achievement: TaskAchievement? {
        get { TaskAchievement(storedStatus: status) }
        set { status = newValue?.rawValue ?? "pending" }
    }

    var isCompletedStatus: Bool {
        achievement != nil
    }
}
