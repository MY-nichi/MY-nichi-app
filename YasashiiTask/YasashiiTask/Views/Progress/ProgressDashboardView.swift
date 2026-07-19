import SwiftData
import SwiftUI

struct ProgressDashboardView: View {
    @Query private var habits: [Habit]
    @Query private var records: [CompletionRecord]
    @State private var progressViewModel = ProgressViewModel()
    @State private var todayViewModel = TodayViewModel()
    private let today = Date.now

    private var snapshot: ProgressSnapshot {
        progressViewModel.snapshot(
            habits: habits,
            records: records,
            todayCards: todayViewModel.cardsForToday(from: habits, date: today),
            date: today
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                encouragement
                summaryGrid
                weeklySection
                habitsSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("進捗・振り返り")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var encouragement: some View {
        Label("今日までの積み重ねを、ゆっくり振り返りましょう", systemImage: "leaf.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(red: 0.06, green: 0.58, blue: 0.42))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.06, green: 0.58, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard("今週の完了", value: snapshot.weekCompleted, unit: "件", icon: "calendar.badge.checkmark")
            summaryCard("今月の完了", value: snapshot.monthCompleted, unit: "件", icon: "calendar")
            summaryCard("今日の未完了", value: snapshot.incomplete, unit: "件", icon: "circle")
            summaryCard("連続達成", value: snapshot.streak, unit: "日", icon: "flame")
        }
    }

    private func summaryCard(_ title: String, value: Int, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)\(unit)")
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近7日間")
                .font(.title2.bold())
            WeeklyProgressChart(values: snapshot.dailyCompletions)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("習慣ごとの実績")
                .font(.title2.bold())
            if snapshot.habitProgress.isEmpty {
                Label("習慣を作ると実績が表示されます", systemImage: "leaf")
                    .foregroundStyle(.secondary)
                    .padding(16)
            } else {
                ForEach(snapshot.habitProgress) { progress in
                    HStack(spacing: 12) {
                        Image(systemName: progress.habit.iconName)
                            .foregroundStyle(Color(red: 0.06, green: 0.58, blue: 0.42))
                            .frame(width: 36, height: 36)
                            .background(Color(red: 0.06, green: 0.58, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        Text(progress.habit.title)
                            .font(.headline)
                        Spacer()
                        Text("\(progress.completedCount)回完了")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ProgressDashboardView() }
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
