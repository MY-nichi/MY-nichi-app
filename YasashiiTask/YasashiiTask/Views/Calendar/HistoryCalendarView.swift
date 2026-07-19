import SwiftData
import SwiftUI

struct HistoryCalendarView: View {
    @Query private var records: [CompletionRecord]
    @State private var viewModel = CalendarViewModel()

    private let calendar = Calendar.current
    private let emerald = Color(red: 0.06, green: 0.58, blue: 0.42)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

    private var selectedRecords: [CompletionRecord] {
        viewModel.completedRecords(on: viewModel.selectedDate, from: records, calendar: calendar)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthHeader
                    calendarGrid
                    selectedDayDetails
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("カレンダー")
        }
    }

    private var monthHeader: some View {
        HStack {
            Button("前の月", systemImage: "chevron.left") {
                viewModel.moveMonth(by: -1, calendar: calendar)
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("前の月")

            Spacer()
            Text(viewModel.displayedMonth.formatted(
                .dateTime.year().month(.wide).locale(Locale(identifier: "ja_JP"))
            ))
            .font(.title2.bold())
            Spacer()

            Button("次の月", systemImage: "chevron.right") {
                viewModel.moveMonth(by: 1, calendar: calendar)
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("次の月")
        }
        .padding(.horizontal, 8)
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(viewModel.monthCells(calendar: calendar).enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayButton(date)
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func dayButton(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isCompleted = viewModel.hasCompletion(on: date, records: records, calendar: calendar)

        return Button {
            viewModel.selectedDate = date
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
                    .foregroundStyle(isCompleted ? (isSelected ? Color.white : emerald) : Color.clear)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? emerald : Color.clear, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 12).stroke(emerald, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(.dateTime.month().day().locale(Locale(identifier: "ja_JP"))))
        .accessibilityValue(isCompleted ? "完了記録あり" : "完了記録なし")
    }

    private var selectedDayDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.selectedDate.formatted(
                .dateTime.month(.wide).day().weekday(.wide).locale(Locale(identifier: "ja_JP"))
            ))
            .font(.title3.bold())

            if selectedRecords.isEmpty {
                Label("この日の完了記録はありません", systemImage: "tray")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(selectedRecords) { record in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(emerald)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.taskCard?.title ?? record.habit?.title ?? "完了した項目")
                                .font(.headline)
                            if let habitTitle = record.habit?.title {
                                Text(habitTitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let completedAt = record.completedAt {
                            Text(completedAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HistoryCalendarView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
