import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var sortOrder: Int = 0
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
