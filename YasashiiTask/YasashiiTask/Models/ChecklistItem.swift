import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var taskCard: TaskCard?

    init(
        id: UUID = UUID(),
        taskCard: TaskCard? = nil,
        title: String,
        isCompleted: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.taskCard = taskCard
        self.title = title
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
    }
}
