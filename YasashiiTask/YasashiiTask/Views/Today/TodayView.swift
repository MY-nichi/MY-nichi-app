import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var settings: [AppSettings]
    @State private var viewModel = TodayViewModel()
    private let today = Date.now

    private var todayHabits: [Habit] {
        viewModel.habitsForToday(from: habits, date: today)
    }

    private var todayCards: [TaskCard] {
        viewModel.cardsForToday(from: habits, date: today)
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
                NavigationLink {
                    ProgressDashboardView()
                } label: {
                    Label("進捗を見る", systemImage: "chart.bar")
                }
                .accessibilityHint("進捗と振り返りの画面を開きます")
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
            .font(.title3.weight(.semibold))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("今日、\(today.formatted(date: .long, time: .omitted))")
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日の習慣")
                .font(.title2.bold())
            if todayHabits.isEmpty {
                emptyMessage("今日の習慣はありません", icon: "leaf")
            } else {
                ForEach(todayHabits) { habit in
                    NavigationLink {
                        TaskCardListView(habit: habit)
                    } label: {
                        HabitRowView(habit: habit)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日のカード")
                .font(.title2.bold())
            if todayCards.isEmpty {
                emptyMessage("今日のカードはありません", icon: "rectangle.stack")
            } else {
                ForEach(todayCards) { card in
                    TaskCardRowView(card: card) {
                        toggleCompletion(card)
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

    private func toggleCompletion(_ card: TaskCard) {
        withAnimation(.easeInOut(duration: 0.22)) {
            viewModel.toggleCompletion(of: card, using: modelContext, date: today)
        }
        guard card.isCompleted else { return }
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
