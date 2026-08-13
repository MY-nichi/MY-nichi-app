import Foundation
import Observation

@MainActor
@Observable
final class CalendarViewModel {
    var displayedMonth: Date
    var selectedDate: Date

    init(date: Date = .now, calendar: Calendar = .current) {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        self.displayedMonth = start
        self.selectedDate = date
    }

    func monthCells(calendar: Calendar = .current) -> [Date?] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        let leadingEmptyCount = calendar.component(.weekday, from: firstDay) - 1
        var cells = Array<Date?>(repeating: nil, count: leadingEmptyCount)
        cells.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        })
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    func moveMonth(by value: Int, calendar: Calendar = .current) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = newMonth
        selectedDate = newMonth
    }

    func completedRecords(
        on date: Date,
        from records: [CompletionRecord],
        calendar: Calendar = .current
    ) -> [CompletionRecord] {
        records
            .filter { $0.isCompletedStatus && calendar.isDate($0.targetDate, inSameDayAs: date) }
            .sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
    }

    func hasCompletion(
        on date: Date,
        records: [CompletionRecord],
        calendar: Calendar = .current
    ) -> Bool {
        !completedRecords(on: date, from: records, calendar: calendar).isEmpty
    }
}
