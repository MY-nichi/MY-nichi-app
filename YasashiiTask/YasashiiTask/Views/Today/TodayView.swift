import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var cards: [TaskCard]
    @Query private var settings: [AppSettings]
    @State private var viewModel = TodayViewModel()
    @State private var selectedHabit: Habit?
    @State private var selectedCard: TaskCard?
    @State private var isCreatingHabit = false
    @State private var isCreatingCard = false
    private let today = Date.now

    private var todayHabits: [Habit] {
        viewModel.habitsForToday(from: habits, date: today)
    }

    private var todayCards: [TaskCard] {
        viewModel.independentCardsForToday(from: cards, date: today)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    dateHeader
                    TodaySummaryView(summary: viewModel.summary(for: todayCards, date: today))
                    habitsSection
                    cardsSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今日")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ProgressDashboardView()
                    } label: {
                        Label("進捗を見る", systemImage: "chart.bar")
                    }
                    .accessibilityHint("進捗と振り返りの画面を開きます")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("追加", systemImage: "plus") {
                        Button("習慣を追加", systemImage: "leaf") {
                            isCreatingHabit = true
                        }
                        Button("タスクを追加", systemImage: "rectangle.stack") {
                            isCreatingCard = true
                        }
                    }
                }
            }
        }
        .overlay {
            if viewModel.recentlyCompletedCardID != nil {
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .alert("保存できませんでした", isPresented: errorBinding) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーです。")
        }
        .sheet(item: $selectedHabit) { habit in
            AchievementPickerSheet(
                cardTitle: habit.title,
                selectedAchievement: viewModel.achievement(for: habit, date: today)
            ) { achievement in
                setAchievement(achievement, for: habit)
            }
        }
        .sheet(item: $selectedCard) { card in
            AchievementPickerSheet(
                cardTitle: card.title,
                selectedAchievement: viewModel.achievement(for: card, date: today)
            ) { achievement in
                setAchievement(achievement, for: card)
            }
        }
        .sheet(isPresented: $isCreatingHabit) {
            HabitFormView(habit: nil, nextSortOrder: (habits.map(\.sortOrder).max() ?? -1) + 1)
        }
        .sheet(isPresented: $isCreatingCard) {
            TaskCardFormView(card: nil, nextSortOrder: nextIndependentCardSortOrder)
        }
    }

    private var dateHeader: some View {
        Text(today.formatted(
            .dateTime
                .year()
                .month(.wide)
                .day()
                .weekday(.wide)
                .locale(Locale(identifier: "ja_JP"))
        ))
            .font(.title.weight(.semibold))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("今日、\(today.formatted(date: .long, time: .omitted))")
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("習慣")
                .font(.title2.bold())
            if todayHabits.isEmpty {
                emptyMessage("今日の習慣はありません", icon: "leaf")
            } else {
                ForEach(todayHabits) { habit in
                    let achievement = viewModel.achievement(for: habit, date: today)
                    Button {
                        selectedHabit = habit
                    } label: {
                        HabitRowView(
                            habit: habit,
                            achievement: achievement,
                            showsActiveStatus: false,
                            isCompleted: achievement != nil,
                            showsExecutionTime: true
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("できばえスタンプ画面を開きます")
                }
            }
        }
    }

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("タスク")
                .font(.title2.bold())
            if todayCards.isEmpty {
                emptyMessage("今日のタスクはありません", icon: "rectangle.stack")
            } else {
                ForEach(todayCards) { card in
                    TaskCardRowView(
                        card: card,
                        achievement: viewModel.achievement(for: card, date: today),
                        showsDueDate: false,
                        showsExecutionTime: true,
                        strikesThroughCompletedTitle: false,
                        usesSimpleCompletionStatus: true
                    ) {
                        selectedCard = card
                    }
                }
            }
        }
    }

    private func emptyMessage(_ message: String, icon: String) -> some View {
        Label(message, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var nextIndependentCardSortOrder: Int {
        (cards.filter { $0.habit == nil }.map(\.sortOrder).max() ?? -1) + 1
    }

    private var completionOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
            Text("できました")
                .font(.headline)
        }
        .foregroundStyle(.white)
        .padding(24)
        .background(Color(red: 0.06, green: 0.58, blue: 0.42).opacity(0.94), in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("完了しました")
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.clearError() } })
    }

    private func setAchievement(_ achievement: TaskAchievement?, for habit: Habit) {
        withAnimation(.easeInOut(duration: 0.22)) {
            viewModel.setAchievement(achievement, of: habit, using: modelContext, date: today)
        }
        guard achievement != nil else { return }
        if settings.first?.hapticsEnabled ?? true {
            HapticService.playCompletionFeedback()
        }
        Task {
            try? await Task.sleep(for: .milliseconds(750))
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.clearCompletionAnimation()
            }
        }
    }

    private func setAchievement(_ achievement: TaskAchievement?, for card: TaskCard) {
        withAnimation(.easeInOut(duration: 0.22)) {
            viewModel.setAchievement(achievement, of: card, using: modelContext, date: today)
        }
        guard achievement != nil else { return }
        if settings.first?.hapticsEnabled ?? true {
            HapticService.playCompletionFeedback()
        }
        Task {
            try? await Task.sleep(for: .milliseconds(750))
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.clearCompletionAnimation()
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
