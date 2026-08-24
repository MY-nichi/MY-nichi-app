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
                if $0.reminderTime != $1.reminderTime {
                    return ($0.reminderTime ?? .distantFuture) < ($1.reminderTime ?? .distantFuture)
                }
                if $0.sortOrder == $1.sortOrder { return $0.createdAt < $1.createdAt }
                return $0.sortOrder < $1.sortOrder
            }
    }

    func cardsForToday(from habits: [Habit], date: Date = .now, calendar: Calendar = .current) -> [TaskCard] {
        let todayHabits = habitsForToday(from: habits, date: date, calendar: calendar)
        return scheduledCardsForToday(from: todayHabits.flatMap(\.taskCards), date: date, calendar: calendar)
    }

    func independentCardsForToday(from cards: [TaskCard], date: Date = .now, calendar: Calendar = .current) -> [TaskCard] {
        scheduledCardsForToday(from: cards.filter { $0.habit == nil }, date: date, calendar: calendar)
    }

    private func scheduledCardsForToday(from cards: [TaskCard], date: Date, calendar: Calendar) -> [TaskCard] {
        let cards = cards.filter { card in
            guard card.isScheduled(on: date, calendar: calendar) else { return false }
            if card.repeatRule != nil {
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
            let firstCompleted = isCompleted($0, date: date, calendar: calendar)
            let secondCompleted = isCompleted($1, date: date, calendar: calendar)
            if firstCompleted != secondCompleted { return !firstCompleted }
            if $0.reminderTime != $1.reminderTime {
                return ($0.reminderTime ?? .distantFuture) < ($1.reminderTime ?? .distantFuture)
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    func summary(for cards: [TaskCard], date: Date = .now, calendar: Calendar = .current) -> TodaySummary {
        let startOfToday = calendar.startOfDay(for: date)
        let activeCards = cards.filter { achievement(for: $0, date: date, calendar: calendar) != .rest }
        return TodaySummary(
            completed: activeCards.filter { isCompleted($0, date: date, calendar: calendar) }.count,
            incomplete: activeCards.filter { !isCompleted($0, date: date, calendar: calendar) }.count,
            overdue: activeCards.filter { card in
                guard !isCompleted(card, date: date, calendar: calendar), let dueDate = card.dueDate else { return false }
                return dueDate < startOfToday
            }.count
        )
    }

    func achievement(
        for card: TaskCard,
        date: Date = .now,
        calendar: Calendar = .current
    ) -> TaskAchievement? {
        completionRecord(for: card, date: date, calendar: calendar)?.achievement ??
            (card.repeatRule == nil && card.isCompleted ? .achieved : nil)
    }

    func setAchievement(
        _ achievement: TaskAchievement?,
        of card: TaskCard,
        using modelContext: ModelContext,
        date: Date = .now,
        calendar: Calendar = .current,
        memo: String? = nil
    ) {
        let wasCompleted = card.isCompleted
        let previousCompletedAt = card.completedAt
        let record = completionRecord(for: card, date: date, calendar: calendar)

        let storesGlobalCompletion = card.repeatRule == nil
        card.isCompleted = storesGlobalCompletion && (achievement?.countsAsCompletion ?? false)
        card.completedAt = card.isCompleted ? date : nil
        card.updatedAt = date

        if let achievement {
            if let record {
                record.achievement = achievement
                record.completedAt = achievement.countsAsCompletion ? date : nil
                if let memo { record.memo = memo }
            } else {
                let newRecord = CompletionRecord(
                    habit: card.habit,
                    taskCard: card,
                    targetDate: calendar.startOfDay(for: date),
                    completedAt: achievement.countsAsCompletion ? date : nil,
                    status: achievement.rawValue,
                    memo: memo ?? ""
                )
                modelContext.insert(newRecord)
            }
            recentlyCompletedCardID = achievement.countsAsCompletion ? card.id : nil
        } else {
            record?.achievement = nil
            record?.completedAt = nil
            record?.memo = ""
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

    func achievement(
        for habit: Habit,
        date: Date = .now,
        calendar: Calendar = .current
    ) -> TaskAchievement? {
        completionRecord(for: habit, date: date, calendar: calendar)?.achievement
    }

    func setAchievement(
        _ achievement: TaskAchievement?,
        of habit: Habit,
        using modelContext: ModelContext,
        date: Date = .now,
        calendar: Calendar = .current,
        memo: String? = nil
    ) {
        let record = completionRecord(for: habit, date: date, calendar: calendar)

        if let record {
            record.achievement = achievement
            record.completedAt = achievement?.countsAsCompletion == true ? date : nil
            if let memo { record.memo = memo }
        } else if let achievement {
            modelContext.insert(CompletionRecord(
                habit: habit,
                targetDate: calendar.startOfDay(for: date),
                completedAt: achievement.countsAsCompletion ? date : nil,
                status: achievement.rawValue,
                memo: memo ?? ""
            ))
        }
        habit.updatedAt = date
        recentlyCompletedCardID = achievement?.countsAsCompletion == true ? habit.id : nil

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
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

    func memo(
        for card: TaskCard,
        date: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        completionRecord(for: card, date: date, calendar: calendar)?.memo ?? ""
    }

    func memo(
        for habit: Habit,
        date: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        completionRecord(for: habit, date: date, calendar: calendar)?.memo ?? ""
    }

    func clearCompletionAnimation() {
        recentlyCompletedCardID = nil
    }

    func clearError() {
        errorMessage = nil
    }

    private func isCompleted(
        _ card: TaskCard,
        date: Date,
        calendar: Calendar
    ) -> Bool {
        if let achievement = achievement(for: card, date: date, calendar: calendar) {
            return achievement.countsAsCompletion
        }
        return card.repeatRule == nil && card.isCompleted
    }

    private func completionRecord(
        for card: TaskCard,
        date: Date,
        calendar: Calendar
    ) -> CompletionRecord? {
        card.completionRecords.first { calendar.isDate($0.targetDate, inSameDayAs: date) }
    }

    private func completionRecord(
        for habit: Habit,
        date: Date,
        calendar: Calendar
    ) -> CompletionRecord? {
        habit.completionRecords.first {
            $0.taskCard == nil && calendar.isDate($0.targetDate, inSameDayAs: date)
        }
    }
}

private extension Calendar {
    func endOfDay(for date: Date) -> Date {
        self.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay(for: date)) ?? date
    }
}
