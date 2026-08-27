import SwiftData
import SwiftUI

struct HistoryCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [CompletionRecord]
    @Query private var habits: [Habit]
    @Query private var cards: [TaskCard]
    @State private var viewModel = CalendarViewModel()
    @State private var selectedHabit: Habit?
    @State private var selectedCard: TaskCard?
    @State private var errorMessage: String?

    private let calendar = Calendar.current
    private let emerald = AppTheme.tint
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

    private var selectedHabits: [Habit] {
        let selectedDay = calendar.startOfDay(for: viewModel.selectedDate)
        return habits
            .filter { habit in
                guard habit.isActive, !habit.isArchived else { return false }
                guard selectedDay >= calendar.startOfDay(for: habit.startDate) else { return false }
                if let endDate = habit.endDate,
                   selectedDay > calendar.startOfDay(for: endDate) {
                    return false
                }
                let weekday = calendar.component(.weekday, from: selectedDay)
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

    private var selectedTasks: [TaskCard] {
        cards
            .filter { card in
                if card.repeatRule != nil {
                    return card.isScheduled(on: viewModel.selectedDate, calendar: calendar)
                }
                guard let dueDate = card.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: viewModel.selectedDate)
            }
            .sorted {
                if $0.reminderTime != $1.reminderTime {
                    return ($0.reminderTime ?? .distantFuture) < ($1.reminderTime ?? .distantFuture)
                }
                return $0.sortOrder < $1.sortOrder
            }
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
            .background(AppTheme.screenBackground)
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $selectedHabit) { habit in
            AchievementPickerSheet(
                cardTitle: habit.title,
                selectedAchievement: achievement(for: habit),
                memo: record(for: habit)?.memo ?? "",
                showsNavigationTitle: false
            ) { achievement, memo in
                setAchievement(achievement, memo: memo, for: habit)
            }
        }
        .sheet(item: $selectedCard) { card in
            AchievementPickerSheet(
                cardTitle: card.title,
                selectedAchievement: achievement(for: card),
                memo: record(for: card)?.memo ?? "",
                showsNavigationTitle: false
            ) { achievement, memo in
                setAchievement(achievement, memo: memo, for: card)
            }
        }
        .alert("保存できませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
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
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private func dayButton(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday = calendar.isDateInToday(date)
        let completedRecords = viewModel.completedRecords(on: date, from: records, calendar: calendar)
        let latestAchievement = completedRecords
            .sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
            .last?
            .achievement

        return Button {
            viewModel.selectedDate = date
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                if let latestAchievement {
                    AchievementFaceIcon(achievement: latestAchievement, compact: true, size: 18)
                } else {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .foregroundStyle(Color.clear)
                }
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
        .accessibilityValue(latestAchievement.map { "\($0.title)の記録あり" } ?? "完了記録なし")
    }

    private var selectedDayDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.selectedDate.formatted(
                .dateTime.month(.wide).day().weekday(.wide).locale(Locale(identifier: "ja_JP"))
            ))
            .font(.title3.bold())

            Text("習慣")
                .font(.headline)
            if selectedHabits.isEmpty {
                Label("この日の習慣はありません", systemImage: "leaf")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(selectedHabits) { habit in
                    let achievement = achievement(for: habit)
                    Button {
                        selectedHabit = habit
                    } label: {
                        HabitRowView(
                            habit: habit,
                            achievement: achievement,
                            showsActiveStatus: false,
                            isCompleted: achievement != nil,
                            showsExecutionTime: true,
                            achievementMemo: record(for: habit)?.memo ?? ""
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("押すと、できばえスタンプを変更できます")
                }
            }

            Text("タスク")
                .font(.headline)
            if selectedTasks.isEmpty {
                Label("この日のタスクはありません", systemImage: "rectangle.stack")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(selectedTasks) { card in
                    TaskCardRowView(
                        card: card,
                        achievement: achievement(for: card),
                        showsDueDate: false,
                        showsExecutionTime: true,
                        strikesThroughCompletedTitle: false,
                        usesSimpleCompletionStatus: true,
                        achievementMemo: record(for: card)?.memo ?? ""
                    ) {
                        selectedCard = card
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func achievement(for habit: Habit) -> TaskAchievement? {
        record(for: habit)?.achievement
    }

    private func achievement(for card: TaskCard) -> TaskAchievement? {
        record(for: card)?.achievement
    }

    private func setAchievement(_ achievement: TaskAchievement?, memo: String, for habit: Habit) {
        if let record = record(for: habit) {
            record.achievement = achievement
            record.completedAt = achievement?.countsAsCompletion == true ? viewModel.selectedDate : nil
            record.memo = achievement == nil ? "" : memo
        } else if let achievement {
            modelContext.insert(CompletionRecord(
                habit: habit,
                targetDate: calendar.startOfDay(for: viewModel.selectedDate),
                completedAt: achievement.countsAsCompletion ? viewModel.selectedDate : nil,
                status: achievement.rawValue,
                memo: memo
            ))
        }
        saveAchievement()
    }

    private func setAchievement(_ achievement: TaskAchievement?, memo: String, for card: TaskCard) {
        if let record = record(for: card) {
            record.achievement = achievement
            record.completedAt = achievement?.countsAsCompletion == true ? viewModel.selectedDate : nil
            record.memo = achievement == nil ? "" : memo
        } else if let achievement {
            modelContext.insert(CompletionRecord(
                habit: card.habit,
                taskCard: card,
                targetDate: calendar.startOfDay(for: viewModel.selectedDate),
                completedAt: achievement.countsAsCompletion ? viewModel.selectedDate : nil,
                status: achievement.rawValue,
                memo: memo
            ))
        }
        let storesGlobalCompletion = card.repeatRule == nil
        card.isCompleted = storesGlobalCompletion && (achievement?.countsAsCompletion ?? false)
        card.completedAt = card.isCompleted ? viewModel.selectedDate : nil
        card.updatedAt = .now
        saveAchievement()
    }

    private func saveAchievement() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func record(for habit: Habit) -> CompletionRecord? {
        records.first {
            $0.habit == habit && $0.taskCard == nil &&
                calendar.isDate($0.targetDate, inSameDayAs: viewModel.selectedDate)
        }
    }

    private func record(for card: TaskCard) -> CompletionRecord? {
        records.first {
            $0.taskCard == card && calendar.isDate($0.targetDate, inSameDayAs: viewModel.selectedDate)
        }
    }
}

#Preview {
    HistoryCalendarView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
