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

    func requestDeletion(of habit: Habit) {
        habitPendingDeletion = habit
    }

    func cancelDeletion() {
        habitPendingDeletion = nil
    }

    func deletePendingHabit(using modelContext: ModelContext) {
        guard let habit = habitPendingDeletion else { return }

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
}
