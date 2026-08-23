import Foundation
import Observation

@MainActor
@Observable
final class HabitFormViewModel {
    var title: String
    var detail: String
    var iconName: String
    var customIconText: String
    var colorHex: String
    var startDate: Date
    var hasEndDate: Bool
    var endDate: Date
    var activeDays: Set<Int>
    var targetCount: Int
    var hasDailyTime: Bool
    var dailyStartTime: Date
    var dailyEndTime: Date
    var hasTargetMinutes: Bool
    var targetMinutes: Int
    var hasTargetDays: Bool
    var targetDays: Int
    var hasReminder: Bool
    var reminderTime: Date
    var isActive: Bool
    var errorMessage: String?

    let habit: Habit?
    let nextSortOrder: Int

    init(habit: Habit?, nextSortOrder: Int) {
        self.habit = habit
        self.nextSortOrder = nextSortOrder
        self.title = habit?.title ?? ""
        self.detail = habit?.detail ?? ""
        self.iconName = habit?.iconName ?? "checkmark.circle"
        self.customIconText = habit?.customIconText ?? ""
        self.colorHex = habit?.colorHex ?? "#10B981"
        self.startDate = habit?.startDate ?? .now
        self.hasEndDate = habit?.endDate != nil
        self.endDate = habit?.endDate ?? .now
        self.activeDays = Set(habit?.activeDays ?? [])
        self.targetCount = habit?.targetCount ?? 1
        self.hasDailyTime = habit?.dailyStartTime != nil
        self.dailyStartTime = habit?.dailyStartTime ?? .now
        self.dailyEndTime = habit?.dailyEndTime ?? Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        self.hasTargetMinutes = habit?.targetMinutes != nil
        self.targetMinutes = habit?.targetMinutes ?? 30
        self.hasTargetDays = habit?.targetDays != nil
        self.targetDays = habit?.targetDays ?? 30
        self.hasReminder = habit?.reminderTime != nil
        self.reminderTime = habit?.reminderTime ?? .now
        self.isActive = habit?.isActive ?? true
    }

    var navigationTitle: String {
        habit == nil ? "習慣を作成" : "習慣を編集"
    }

    func save() -> Habit? {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            errorMessage = "習慣名を入力してください。"
            return nil
        }
        guard cleanedTitle.count <= 100 else {
            errorMessage = "習慣名は100文字以内で入力してください。"
            return nil
        }
        guard !hasEndDate || endDate >= startDate else {
            errorMessage = "終了日は開始日以降にしてください。"
            return nil
        }

        if let habit {
            habit.title = cleanedTitle
            habit.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            habit.iconName = iconName
            habit.customIconText = iconName == "sparkles" ? customIconText.trimmingCharacters(in: .whitespacesAndNewlines) : nil
            habit.colorHex = colorHex
            habit.startDate = startDate
            habit.endDate = hasEndDate ? endDate : nil
            habit.activeDays = activeDays.sorted()
            habit.targetCount = max(1, targetCount)
            habit.dailyStartTime = nil
            habit.dailyEndTime = nil
            habit.targetMinutes = hasTargetMinutes ? max(1, targetMinutes) : nil
            habit.targetDays = hasTargetDays ? max(1, targetDays) : nil
            habit.reminderTime = hasReminder ? reminderTime : nil
            habit.isActive = isActive
            habit.updatedAt = .now
            return habit
        }

        return Habit(
            title: cleanedTitle,
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            iconName: iconName,
            customIconText: iconName == "sparkles" ? customIconText.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            colorHex: colorHex,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            activeDays: activeDays.sorted(),
            reminderTime: hasReminder ? reminderTime : nil,
            targetCount: max(1, targetCount),
            dailyStartTime: nil,
            dailyEndTime: nil,
            targetMinutes: hasTargetMinutes ? max(1, targetMinutes) : nil,
            targetDays: hasTargetDays ? max(1, targetDays) : nil,
            sortOrder: nextSortOrder,
            isActive: isActive
        )
    }

    func toggleDay(_ weekday: Int) {
        if activeDays.contains(weekday) {
            activeDays.remove(weekday)
        } else {
            activeDays.insert(weekday)
        }
    }
}
