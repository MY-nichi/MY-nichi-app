import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class HabitsViewModel {
    var habitPendingDeletion: Habit?
    var errorMessage: String?

    func visibleHabits(from habits: [Habit]) -> [Habit] {
        habits
            .filter { !$0.isArchived }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.createdAt < $1.createdAt
                }
                return $0.sortOrder < $1.sortOrder
            }
    }

    func nextSortOrder(from habits: [Habit]) -> Int {
        (habits.map(\.sortOrder).max() ?? -1) + 1
    }

    func streakCount(for habit: Habit, date: Date = .now, calendar: Calendar = .current) -> Int {
        var count = 0
        var currentDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: habit.startDate)
        let today = calendar.startOfDay(for: .now)

        while currentDate >= startDate {
            if isScheduled(habit, on: currentDate, calendar: calendar) {
                if let achievement = achievement(for: habit, on: currentDate, calendar: calendar) {
                    if achievement == .rest {
                        currentDate = previousDay(before: currentDate, calendar: calendar)
                        continue
                    }
                    if achievement.countsAsCompletion {
                        count += 1
                    } else {
                        break
                    }
                } else if calendar.isDate(currentDate, inSameDayAs: today) {
                    currentDate = previousDay(before: currentDate, calendar: calendar)
                    continue
                } else {
                    break
                }
            }
            currentDate = previousDay(before: currentDate, calendar: calendar)
        }

        return count
    }

    func requestDeletion(of habit: Habit) {
        habitPendingDeletion = habit
    }

    func cancelDeletion() {
        habitPendingDeletion = nil
    }

    func deletePendingHabit(using modelContext: ModelContext) {
        guard let habit = habitPendingDeletion else { return }

        NotificationService.removeHabitReminder(for: habit.id)
        modelContext.delete(habit)
        habitPendingDeletion = nil

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "習慣を削除できませんでした。もう一度お試しください。"
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func achievement(for habit: Habit, on date: Date, calendar: Calendar) -> TaskAchievement? {
        (habit.completionRecords ?? []).first {
            $0.taskCard == nil && calendar.isDate($0.targetDate, inSameDayAs: date)
        }?.achievement
    }

    private func isScheduled(_ habit: Habit, on date: Date, calendar: Calendar) -> Bool {
        guard habit.isActive, !habit.isArchived else { return false }
        guard date >= calendar.startOfDay(for: habit.startDate) else { return false }
        if let endDate = habit.endDate, date > calendar.startOfDay(for: endDate) { return false }
        let weekday = calendar.component(.weekday, from: date)
        return habit.activeDays.isEmpty || habit.activeDays.contains(weekday)
    }

    private func previousDay(before date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -1, to: date) ?? date
    }
}
