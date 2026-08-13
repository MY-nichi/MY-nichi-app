import Foundation
import Observation

struct DailyCompletion: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct HabitProgress: Identifiable {
    let habit: Habit
    let completedCount: Int
    var id: UUID { habit.id }
}

struct ProgressSnapshot {
    let weekCompleted: Int
    let monthCompleted: Int
    let incomplete: Int
    let streak: Int
    let dailyCompletions: [DailyCompletion]
    let habitProgress: [HabitProgress]
}

@MainActor
@Observable
final class ProgressViewModel {
    func snapshot(
        habits: [Habit],
        records: [CompletionRecord],
        todayCards: [TaskCard],
        date: Date = .now,
        calendar: Calendar = .current
    ) -> ProgressSnapshot {
        let completedRecords = records.filter(\.isCompletedStatus)
        let today = calendar.startOfDay(for: date)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? today

        let daily = (0..<7).compactMap { offset -> DailyCompletion? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let count = completedRecords.filter { calendar.isDate($0.targetDate, inSameDayAs: day) }.count
            return DailyCompletion(date: day, count: count)
        }

        let habitProgress = habits
            .filter { !$0.isArchived }
            .map { habit in
                HabitProgress(
                    habit: habit,
                    completedCount: completedRecords.filter { $0.habit?.id == habit.id }.count
                )
            }
            .sorted {
                if $0.completedCount == $1.completedCount { return $0.habit.sortOrder < $1.habit.sortOrder }
                return $0.completedCount > $1.completedCount
            }

        return ProgressSnapshot(
            weekCompleted: completedRecords.filter { $0.targetDate >= weekStart && $0.targetDate < endOfDay(after: today, calendar: calendar) }.count,
            monthCompleted: completedRecords.filter { $0.targetDate >= monthStart && $0.targetDate < endOfDay(after: today, calendar: calendar) }.count,
            incomplete: todayCards.filter { !$0.isCompleted }.count,
            streak: streak(records: completedRecords, date: date, calendar: calendar),
            dailyCompletions: daily,
            habitProgress: habitProgress
        )
    }

    private func streak(records: [CompletionRecord], date: Date, calendar: Calendar) -> Int {
        let completedDays = Set(records.map { calendar.startOfDay(for: $0.targetDate) })
        var result = 0
        var day = calendar.startOfDay(for: date)
        while completedDays.contains(day) {
            result += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return result
    }

    private func endOfDay(after date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
    }
}
