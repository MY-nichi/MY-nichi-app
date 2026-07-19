//
//  YasashiiTaskTests.swift
//  YasashiiTaskTests
//
//  Created by kishiko on 2026/07/18.
//

import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import YasashiiTask

struct YasashiiTaskTests {

    @Test func habitUsesSafeDefaults() {
        let habit = Habit(title: "朝のストレッチ", targetCount: 0)

        #expect(habit.title == "朝のストレッチ")
        #expect(habit.targetCount == 1)
        #expect(habit.isActive)
        #expect(!habit.isArchived)
    }

    @Test func taskCardCanBelongToHabit() {
        let habit = Habit(title: "英語学習")
        let card = TaskCard(habit: habit, title: "単語を10個覚える")

        #expect(card.habit?.id == habit.id)
        #expect(!card.isCompleted)
        #expect(card.priority == "normal")
    }

    @Test func appSettingsProtectPrivacyByDefault() {
        let settings = AppSettings()

        #expect(!settings.notificationsEnabled)
        #expect(settings.hapticsEnabled)
        #expect(settings.theme == "system")
    }

    @Test @MainActor func habitListHidesArchivedItemsAndUsesSortOrder() {
        let later = Habit(title: "2番目", sortOrder: 2)
        let first = Habit(title: "1番目", sortOrder: 1)
        let archived = Habit(title: "非表示", sortOrder: 0, isArchived: true)
        let viewModel = HabitsViewModel()

        let result = viewModel.visibleHabits(from: [later, archived, first])

        #expect(result.map(\.title) == ["1番目", "2番目"])
    }

    @Test @MainActor func habitFormRequiresTitle() {
        let viewModel = HabitFormViewModel(habit: nil, nextSortOrder: 3)

        #expect(viewModel.save() == nil)
        #expect(viewModel.errorMessage == "習慣名を入力してください。")
    }

    @Test @MainActor func habitFormCreatesAndEditsHabit() {
        let newForm = HabitFormViewModel(habit: nil, nextSortOrder: 3)
        newForm.title = " 朝の読書 "
        newForm.category = "学習"
        newForm.activeDays = [2, 4, 6]

        let habit = newForm.save()
        #expect(habit?.title == "朝の読書")
        #expect(habit?.sortOrder == 3)
        #expect(habit?.activeDays == [2, 4, 6])

        let editForm = HabitFormViewModel(habit: habit, nextSortOrder: 3)
        editForm.title = "夜の読書"
        _ = editForm.save()
        #expect(habit?.title == "夜の読書")
    }

    @Test @MainActor func cardListShowsIncompleteCardsFirst() {
        let habit = Habit(title: "学習")
        let completed = TaskCard(habit: habit, title: "完了", sortOrder: 0, isCompleted: true)
        let second = TaskCard(habit: habit, title: "未完了2", sortOrder: 2)
        let first = TaskCard(habit: habit, title: "未完了1", sortOrder: 1)
        let viewModel = TaskCardsViewModel()

        let result = viewModel.sortedCards(from: [completed, second, first])

        #expect(result.map(\.title) == ["未完了1", "未完了2", "完了"])
    }

    @Test @MainActor func cardFormCreatesAndEditsCard() {
        let habit = Habit(title: "散歩")
        let form = TaskCardFormViewModel(habit: habit, card: nil, nextSortOrder: 2)
        form.title = " 公園を一周する "
        form.tagsText = "運動、屋外"
        form.checklistDrafts = [ChecklistDraft(title: "水を持つ")]

        let card = form.save()

        #expect(card?.title == "公園を一周する")
        #expect(card?.sortOrder == 2)
        #expect(card?.tags == ["運動", "屋外"])
        #expect(card?.checklistItems.first?.title == "水を持つ")

        let editForm = TaskCardFormViewModel(habit: habit, card: card, nextSortOrder: 2)
        editForm.title = "近所を一周する"
        _ = editForm.save()
        #expect(card?.title == "近所を一周する")
    }

    @Test @MainActor func todayFiltersHabitsByWeekdayAndSummarizesCards() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: 1_721_260_800)
        let weekday = calendar.component(.weekday, from: date)
        let todayHabit = Habit(title: "今日", startDate: date, activeDays: [weekday])
        let otherHabit = Habit(
            title: "別の曜日",
            startDate: date,
            activeDays: [weekday == 7 ? 1 : weekday + 1]
        )
        let incomplete = TaskCard(habit: todayHabit, title: "未完了")
        let completed = TaskCard(habit: todayHabit, title: "完了", isCompleted: true, completedAt: date)
        todayHabit.taskCards = [incomplete, completed]
        let viewModel = TodayViewModel()

        let habits = viewModel.habitsForToday(from: [otherHabit, todayHabit], date: date, calendar: calendar)
        let cards = viewModel.cardsForToday(from: [otherHabit, todayHabit], date: date, calendar: calendar)
        let summary = viewModel.summary(for: cards, date: date, calendar: calendar)

        #expect(habits.map(\.title) == ["今日"])
        #expect(cards.count == 2)
        #expect(summary.completed == 1)
        #expect(summary.incomplete == 1)
        #expect(summary.achievementRate == 50)
    }

    @Test @MainActor func completionCanBeToggledAndRecorded() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Habit.self,
            TaskCard.self,
            ChecklistItem.self,
            CompletionRecord.self,
            AppSettings.self,
            configurations: configuration
        )
        let context = container.mainContext
        let habit = Habit(title: "散歩")
        let card = TaskCard(habit: habit, title: "公園を歩く")
        habit.taskCards = [card]
        context.insert(habit)
        let viewModel = TodayViewModel()
        let date = Date(timeIntervalSince1970: 1_721_260_800)

        viewModel.toggleCompletion(of: card, using: context, date: date)
        #expect(card.isCompleted)
        #expect(card.completedAt == date)
        #expect(card.completionRecords.first?.status == "completed")

        viewModel.toggleCompletion(of: card, using: context, date: date)
        #expect(!card.isCompleted)
        #expect(card.completedAt == nil)
        #expect(card.completionRecords.first?.status == "pending")
    }

    @Test @MainActor func timelineSortsTimesAndSeparatesUntimedCards() {
        let calendar = Calendar(identifier: .gregorian)
        let morning = calendar.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 8))!
        let evening = calendar.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 18))!
        let late = TaskCard(title: "夕方", startTime: evening)
        let untimed = TaskCard(title: "時刻なし")
        let early = TaskCard(title: "朝", startTime: morning)
        let viewModel = TimelineViewModel()

        #expect(viewModel.timedCards(from: [late, untimed, early]).map(\.title) == ["朝", "夕方"])
        #expect(viewModel.untimedCards(from: [late, untimed, early]).map(\.title) == ["時刻なし"])
    }

    @Test @MainActor func calendarBuildsMonthAndFindsCompletedRecords() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 7, day: 18))!
        let viewModel = CalendarViewModel(date: date, calendar: calendar)
        let completed = CompletionRecord(targetDate: date, completedAt: date, status: "completed")
        let pending = CompletionRecord(targetDate: date, status: "pending")

        let cells = viewModel.monthCells(calendar: calendar)
        let records = viewModel.completedRecords(on: date, from: [pending, completed], calendar: calendar)

        #expect(cells.compactMap { $0 }.count == 31)
        #expect(cells.count % 7 == 0)
        #expect(records.count == 1)
        #expect(viewModel.hasCompletion(on: date, records: [completed], calendar: calendar))
    }

    @Test @MainActor func progressCalculatesCountsAndStreak() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = calendar.date(from: DateComponents(year: 2026, month: 7, day: 19))!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let habit = Habit(title: "散歩")
        let todayRecord = CompletionRecord(habit: habit, targetDate: today, completedAt: today, status: "completed")
        let yesterdayRecord = CompletionRecord(habit: habit, targetDate: yesterday, completedAt: yesterday, status: "completed")
        let incomplete = TaskCard(habit: habit, title: "未完了")
        let viewModel = ProgressViewModel()

        let snapshot = viewModel.snapshot(
            habits: [habit],
            records: [todayRecord, yesterdayRecord],
            todayCards: [incomplete],
            date: today,
            calendar: calendar
        )

        #expect(snapshot.weekCompleted == 2)
        #expect(snapshot.monthCompleted == 2)
        #expect(snapshot.incomplete == 1)
        #expect(snapshot.streak == 2)
        #expect(snapshot.habitProgress.first?.completedCount == 2)
    }

    @Test @MainActor func backupEncodesAndDecodesData() throws {
        let habit = Habit(title: "散歩")
        let card = TaskCard(habit: habit, title: "公園を歩く", tags: ["運動"])
        habit.taskCards = [card]

        let data = try BackupService.makeData(habits: [habit], cards: [card], checklistItems: [], completionRecords: [], settings: [])
        let package = try BackupService.decode(data)

        #expect(package.version == 1)
        #expect(package.habits.first?.title == "散歩")
        #expect(package.cards.first?.title == "公園を歩く")
        #expect(package.cards.first?.habitID == habit.id)
        #expect(package.cards.first?.tags == ["運動"])
    }

    @Test @MainActor func invalidBackupDoesNotDecode() {
        #expect(throws: BackupError.self) {
            _ = try BackupService.decode(Data("not-json".utf8))
        }
    }

    @Test @MainActor func backupReplacesRelatedData() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Habit.self,
            TaskCard.self,
            ChecklistItem.self,
            CompletionRecord.self,
            AppSettings.self,
            configurations: configuration
        )
        let context = container.mainContext
        let oldHabit = Habit(title: "古い習慣")
        let oldCard = TaskCard(habit: oldHabit, title: "古いカード", isCompleted: true)
        let oldRecord = CompletionRecord(habit: oldHabit, taskCard: oldCard, targetDate: .now, completedAt: .now, status: "completed")
        context.insert(oldHabit)
        context.insert(oldCard)
        context.insert(oldRecord)
        try context.save()

        let newHabit = Habit(title: "復元した習慣")
        let newCard = TaskCard(habit: newHabit, title: "復元したカード")
        let data = try BackupService.makeData(habits: [newHabit], cards: [newCard], checklistItems: [], completionRecords: [], settings: [])

        try BackupService.restore(data, using: context)

        #expect(try context.fetch(FetchDescriptor<Habit>()).map(\.title) == ["復元した習慣"])
        #expect(try context.fetch(FetchDescriptor<TaskCard>()).map(\.title) == ["復元したカード"])
        #expect(try context.fetch(FetchDescriptor<CompletionRecord>()).isEmpty)
    }

    @Test @MainActor func settingsMapsThemesToColorSchemes() {
        let viewModel = SettingsViewModel()

        #expect(viewModel.colorScheme(for: "system") == nil)
        #expect(viewModel.colorScheme(for: "light") == .light)
        #expect(viewModel.colorScheme(for: "dark") == .dark)
    }

    @Test @MainActor func formsRejectNamesOverOneHundredCharacters() {
        let longName = String(repeating: "あ", count: 101)
        let habitForm = HabitFormViewModel(habit: nil, nextSortOrder: 0)
        habitForm.title = longName
        let cardForm = TaskCardFormViewModel(habit: Habit(title: "習慣"), card: nil, nextSortOrder: 0)
        cardForm.title = longName

        #expect(habitForm.save() == nil)
        #expect(habitForm.errorMessage == "習慣名は100文字以内で入力してください。")
        #expect(cardForm.save() == nil)
        #expect(cardForm.errorMessage == "カード名は100文字以内で入力してください。")
    }

}
