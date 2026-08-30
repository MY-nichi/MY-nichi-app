import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var cards: [TaskCard]
    @Query private var settings: [AppSettings]
    @State private var viewModel = TodayViewModel()
    @State private var selectedHabitID: UUID?
    @State private var selectedCardID: UUID?
    @State private var isCreatingHabit = false
    @State private var isCreatingCard = false
    @AppStorage(AdRemovalStore.adsRemovedDefaultsKey) private var adsRemoved = false
    private let today = Date.now

    private var todayHabits: [Habit] {
        viewModel.habitsForToday(from: habits, date: today)
    }

    private var todayCards: [TaskCard] {
        viewModel.independentCardsForToday(from: cards, date: today)
    }

    private var displayName: String? {
        let name = settings.first?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? nil : name
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    dateHeader
                    TodaySummaryView(summary: viewModel.summary(for: todayCards, date: today), compact: true)
                    habitsSection
                    cardsSection
                    adMobFooter
                }
                .padding(16)
            }
            .appScreenBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: selectedHabitBinding) {
            if let habit = selectedHabit {
                AchievementPickerSheet(
                    cardTitle: habit.title,
                    selectedAchievement: viewModel.achievement(for: habit, date: today),
                    memo: viewModel.memo(for: habit, date: today)
                ) { achievement, memo in
                    setAchievement(achievement, memo: memo, for: habit)
                }
            }
        }
        .sheet(isPresented: selectedCardBinding) {
            if let card = selectedCard {
                AchievementPickerSheet(
                    cardTitle: card.title,
                    selectedAchievement: viewModel.achievement(for: card, date: today),
                    memo: viewModel.memo(for: card, date: today)
                ) { achievement, memo in
                    setAchievement(achievement, memo: memo, for: card)
                }
            }
        }
        .sheet(isPresented: $isCreatingHabit) {
            HabitFormView(habit: nil, nextSortOrder: (habits.map(\.sortOrder).max() ?? -1) + 1)
        }
        .sheet(isPresented: $isCreatingCard) {
            TaskCardFormView(card: nil, nextSortOrder: nextIndependentCardSortOrder)
        }
        .onAppear(perform: updateWidgetSnapshot)
        .onChange(of: todayHabits.map(\.updatedAt)) { _, _ in updateWidgetSnapshot() }
        .onChange(of: todayCards.map(\.updatedAt)) { _, _ in updateWidgetSnapshot() }
    }

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                HStack {
                    NavigationLink {
                        ProgressDashboardView()
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.tint)
                            .frame(width: 46, height: 46)
                            .background(.white.opacity(0.72), in: Circle())
                    }
                    .accessibilityLabel("進捗を見る")
                    .accessibilityHint("進捗と振り返りの画面を開きます")

                    Spacer()

                    Menu {
                        Button("習慣を追加", systemImage: "leaf") {
                            isCreatingHabit = true
                        }
                        Button("タスクを追加", systemImage: "rectangle.stack") {
                            isCreatingCard = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppTheme.tint)
                            .frame(width: 46, height: 46)
                            .background(.white.opacity(0.72), in: Circle())
                    }
                    .accessibilityLabel("追加")
                }

                HStack(spacing: 5) {
                    Text("今日")
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            }

            HStack(spacing: 12) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.tint, AppTheme.softGreen)

                VStack(alignment: .leading, spacing: 3) {
                    if let displayName {
                        Text("\(displayName)さん")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.tint)
                    }
                    Text(today.formatted(
                        .dateTime
                            .year()
                            .month(.wide)
                            .day()
                            .weekday(.wide)
                            .locale(Locale(identifier: "ja_JP"))
                    ))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日、\(today.formatted(date: .long, time: .omitted))")
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("習慣", systemImage: "leaf.fill")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.tint)
            if todayHabits.isEmpty {
                emptyMessage("今日の習慣はありません", icon: "leaf")
            } else {
                ForEach(todayHabits) { habit in
                    let achievement = viewModel.achievement(for: habit, date: today)
                    Button {
                        selectedHabitID = habit.id
                    } label: {
                        HabitRowView(
                            habit: habit,
                            achievement: achievement,
                            showsActiveStatus: false,
                            isCompleted: achievement != nil,
                            showsExecutionTime: true,
                            achievementMemo: viewModel.memo(for: habit, date: today),
                            compact: true
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
            Label("タスク", systemImage: "checkmark.square.fill")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.tint)
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
                        usesSimpleCompletionStatus: true,
                        achievementMemo: viewModel.memo(for: card, date: today),
                        compact: true
                    ) {
                        selectedCardID = card.id
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var adMobFooter: some View {
        if !adsRemoved {
            HStack {
                Spacer()
                AdMobBannerView()
                    .frame(width: 320, height: 50)
                Spacer()
            }
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
    }

    private func emptyMessage(_ message: String, icon: String) -> some View {
        Label(message, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .polishedCard(cornerRadius: 16)
    }

    private var nextIndependentCardSortOrder: Int {
        (cards.filter { $0.habit == nil }.map(\.sortOrder).max() ?? -1) + 1
    }

    private var selectedHabit: Habit? {
        guard let selectedHabitID else { return nil }
        return todayHabits.first { $0.id == selectedHabitID } ?? habits.first { $0.id == selectedHabitID }
    }

    private var selectedCard: TaskCard? {
        guard let selectedCardID else { return nil }
        return todayCards.first { $0.id == selectedCardID } ?? cards.first { $0.id == selectedCardID }
    }

    private var selectedHabitBinding: Binding<Bool> {
        Binding(
            get: { selectedHabitID != nil },
            set: { if !$0 { selectedHabitID = nil } }
        )
    }

    private var selectedCardBinding: Binding<Bool> {
        Binding(
            get: { selectedCardID != nil },
            set: { if !$0 { selectedCardID = nil } }
        )
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
        .background(AppTheme.tint.opacity(0.94), in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("完了しました")
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.clearError() } })
    }

    private func setAchievement(_ achievement: TaskAchievement?, memo: String, for habit: Habit) {
        withAnimation(.easeInOut(duration: 0.22)) {
            viewModel.setAchievement(achievement, of: habit, using: modelContext, date: today, memo: memo)
        }
        updateWidgetSnapshot()
        guard achievement?.countsAsCompletion == true else { return }
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

    private func setAchievement(_ achievement: TaskAchievement?, memo: String, for card: TaskCard) {
        withAnimation(.easeInOut(duration: 0.22)) {
            viewModel.setAchievement(achievement, of: card, using: modelContext, date: today, memo: memo)
        }
        updateWidgetSnapshot()
        guard achievement?.countsAsCompletion == true else { return }
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

    private func updateWidgetSnapshot() {
        WidgetSnapshotService.save(habits: todayHabits, cards: todayCards, date: today)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
