import Foundation
import Observation

struct ChecklistDraft: Identifiable, Equatable {
    let id: UUID
    var title: String

    init(id: UUID = UUID(), title: String = "") {
        self.id = id
        self.title = title
    }
}

@MainActor
@Observable
final class TaskCardFormViewModel {
    var title: String
    var detail: String
    var memo: String
    var hasDueDate: Bool
    var dueDate: Date
    var hasStartTime: Bool
    var startTime: Date
    var hasEndTime: Bool
    var endTime: Date
    var priority: String
    var iconName: String
    var colorHex: String
    var repeatRule: String
    var hasReminder: Bool
    var reminderTime: Date
    var tagsText: String
    var checklistDrafts: [ChecklistDraft]
    var errorMessage: String?

    let habit: Habit?
    let card: TaskCard?
    let nextSortOrder: Int

    init(habit: Habit?, card: TaskCard?, nextSortOrder: Int) {
        self.habit = habit
        self.card = card
        self.nextSortOrder = nextSortOrder
        self.title = card?.title ?? ""
        self.detail = card?.detail ?? ""
        self.memo = card?.memo ?? ""
        self.hasDueDate = card?.dueDate != nil
        self.dueDate = card?.dueDate ?? .now
        self.hasStartTime = card?.startTime != nil
        self.startTime = card?.startTime ?? .now
        self.hasEndTime = card?.endTime != nil
        self.endTime = card?.endTime ?? .now
        self.priority = card?.priority ?? "normal"
        self.iconName = card?.iconName ?? "rectangle.stack"
        self.colorHex = card?.colorHex ?? habit?.colorHex ?? "#10B981"
        self.repeatRule = card?.repeatRule ?? "none"
        self.hasReminder = card?.reminderTime != nil
        self.reminderTime = card?.reminderTime ?? .now
        self.tagsText = card?.tags.joined(separator: "、") ?? ""
        self.checklistDrafts = (card?.checklistItems ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { ChecklistDraft(id: $0.id, title: $0.title) }
    }

    var navigationTitle: String {
        card == nil ? "タスクを作成" : "タスクを編集"
    }

    func addChecklistDraft() {
        checklistDrafts.append(ChecklistDraft())
    }

    func removeChecklistDraft(id: UUID) {
        checklistDrafts.removeAll { $0.id == id }
    }

    func save() -> TaskCard? {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            errorMessage = "タスク名を入力してください。"
            return nil
        }
        guard cleanedTitle.count <= 100 else {
            errorMessage = "タスク名は100文字以内で入力してください。"
            return nil
        }
        let target = card ?? TaskCard(habit: habit, title: cleanedTitle, sortOrder: nextSortOrder)
        target.habit = habit
        target.title = cleanedTitle
        target.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        target.memo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        target.dueDate = hasDueDate ? dueDate : nil
        target.startTime = nil
        target.endTime = nil
        target.priority = priority
        target.iconName = iconName
        target.colorHex = colorHex
        target.repeatRule = repeatRule == "none" ? nil : repeatRule
        target.reminderTime = hasReminder ? reminderTime : nil
        target.tags = parsedTags
        target.updatedAt = .now
        updateChecklist(for: target)
        return target
    }

    private var parsedTags: [String] {
        tagsText
            .components(separatedBy: CharacterSet(charactersIn: ",、"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func updateChecklist(for target: TaskCard) {
        target.checklistItems.removeAll()
        let titles = checklistDrafts
            .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        target.checklistItems = titles.enumerated().map { index, title in
            ChecklistItem(taskCard: target, title: title, sortOrder: index)
        }
    }
}
