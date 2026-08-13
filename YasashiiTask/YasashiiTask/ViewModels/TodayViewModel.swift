import Foundation
import Observation
import SwiftData

struct TodaySummary {
    let completed: Int
    let incomplete: Int
    let overdue: Int

    var total: Int { completed + incomplete }
    var achievementRate: Int {
        guard total > 0 else { return 0 }
        return Int((Double(completed) / Double(total) * 100).rounded())
    }
}

@MainActor
@Observable
final class TodayViewModel {
    var errorMessage: String?
    var recentlyCompletedCardID: UUID?
    var habitPendingDeletion: Habit?
    var cardPendingDeletion: TaskCard?

    var isDeletionConfirmationPresented: Bool {
        habitPendingDeletion != nil || cardPendingDeletion != nil
    }

    func requestDeletion(of habit: Habit) {
        habitPendingDeletion = habit
    }

    func requestDeletion(of card: TaskCard) {
        cardPendingDeletion = card
    }

    func cancelDeletion() {
        habitPendingDeletion = nil
        cardPendingDeletion = nil
    }

    func deletePendingItem(using modelContext: ModelContext) {
        if let habit = habitPendingDeletion {
            modelContext.delete(habit)
        } else if let card = cardPendingDeletion {
            modelContext.delete(card)
        } else {
            return
        }
        cancelDeletion()

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "削除できませんでした。もう一度お試しください。"
        }
    }

    func habitsForToday(from habits: [Habit], date: Date = .now, calendar: Calendar = .current) -> [Habit] {
        let weekday = calendar.component(.weekday, from: date)
        return habits
            .filter { habit in
                guard habit.isActive, !habit.isArchived else { return false }
                guard date >= calendar.startOfDay(for: habit.startDate) else { return false }
                if let endDate = habit.endDate, date > calendar.endOfDay(for: endDate) { return false }
                return habit.activeDays.isEmpty || habit.activeDays.contains(weekday)
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder { return $0.createdAt < $1.createdAt }
                return $0.sortOrder < $1.sortOrder
            }
    }

    func cardsForToday(from habits: [Habit], date: Date = .now, calendar: Calendar = .current) -> [TaskCard] {
        let todayHabits = habitsForToday(from: habits, date: date, calendar: calendar)
        let cards = todayHabits.flatMap(\.taskCards).filter { card in
            guard card.isScheduled(on: date, calendar: calendar) else { return false }
            if card.repeatRule != nil {
                if card.isCompleted, let completedAt = card.completedAt {
                    return calendar.isDate(completedAt, inSameDayAs: date)
                }
                return true
            }
            if let dueDate = card.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: date) || dueDate < calendar.startOfDay(for: date)
            }
            if card.isCompleted, let completedAt = card.completedAt {
                return calendar.isDate(completedAt, inSameDayAs: date)
            }
            return !card.isCompleted
        }

        return cards.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.startTime != $1.startTime {
                return ($0.startTime ?? .distantFuture) < ($1.startTime ?? .distantFuture)
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    func summary(for cards: [TaskCard], date: Date = .now, calendar: Calendar = .current) -> TodaySummary {
        let startOfToday = calendar.startOfDay(for: date)
        return TodaySummary(
            completed: cards.filter(\.isCompleted).count,
            incomplete: cards.filter { !$0.isCompleted }.count,
            overdue: cards.filter { card in
                guard !card.isCompleted, let dueDate = card.dueDate else { return false }
                return dueDate < startOfToday
            }.count
        )
    }

    func achievement(
        for card: TaskCard,
        date: Date = .now,
        calendar: Calendar = .current
    ) -> TaskAchievement? {
        completionRecord(for: card, date: date, calendar: calendar)?.achievement
            ?? (card.isCompleted ? .achieved : nil)
    }

    func setAchievement(
        _ achievement: TaskAchievement?,
        of card: TaskCard,
        using modelContext: ModelContext,
        date: Date = .now,
        calendar: Calendar = .current
    ) {
        let wasCompleted = card.isCompleted
        let previousCompletedAt = card.completedAt
        let record = completionRecord(for: card, date: date, calendar: calendar)

        card.isCompleted = achievement != nil
        card.completedAt = card.isCompleted ? date : nil
        card.updatedAt = date

        if card.isCompleted {
            if let record {
                record.achievement = achievement
                record.completedAt = date
            } else {
                let newRecord = CompletionRecord(
                    habit: card.habit,
                    taskCard: card,
                    targetDate: calendar.startOfDay(for: date),
                    completedAt: date,
                    status: achievement?.rawValue ?? "pending"
                )
                modelContext.insert(newRecord)
            }
            recentlyCompletedCardID = card.id
        } else {
            record?.achievement = nil
            record?.completedAt = nil
            recentlyCompletedCardID = nil
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            card.isCompleted = wasCompleted
            card.completedAt = previousCompletedAt
            errorMessage = "完了状態を保存できませんでした。もう一度お試しください。"
        }
    }

    func toggleCompletion(
        of card: TaskCard,
        using modelContext: ModelContext,
        date: Date = .now,
        calendar: Calendar = .current
    ) {
        let nextValue: TaskAchievement? = card.isCompleted ? nil : .achieved
        setAchievement(nextValue, of: card, using: modelContext, date: date, calendar: calendar)
    }

    func clearCompletionAnimation() {
        recentlyCompletedCardID = nil
    }

    func clearError() {
        errorMessage = nil
    }

    private func completionRecord(
        for card: TaskCard,
        date: Date,
        calendar: Calendar
    ) -> CompletionRecord? {
        card.completionRecords.first { calendar.isDate($0.targetDate, inSameDayAs: date) }
    }
}

private extension Calendar {
    func endOfDay(for date: Date) -> Date {
        self.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay(for: date)) ?? date
    }
}
