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
                habitReflectionSection
                habitsSection
            }
            .padding(16)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("進捗・振り返り")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var encouragement: some View {
        Label("今日までの積み重ねを、ゆっくり振り返りましょう", systemImage: "leaf.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.tint)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
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
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近7日間")
                .font(.title2.bold())
            WeeklyProgressChart(values: snapshot.dailyCompletions)
                .padding(16)
                .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var habitReflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週の振り返り")
                .font(.title2.bold())
            if reflectedHabits.isEmpty {
                Label("習慣を記録すると振り返りが表示されます", systemImage: "sparkles")
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text("習慣")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 104, alignment: .leading)
                            ForEach(reflectionDates, id: \.self) { date in
                                Text(dayLabel(for: date))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 34)
                            }
                        }
                        ForEach(reflectedHabits) { habit in
                            HStack(spacing: 8) {
                                Text(habit.title)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .frame(width: 104, alignment: .leading)
                                ForEach(reflectionDates, id: \.self) { date in
                                    reflectionStamp(for: habit, on: date)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            }
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
                        Group {
                            if progress.habit.iconName == "sparkles",
                               let customText = progress.habit.customIconText,
                               !customText.isEmpty {
                                Text(customText)
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            } else {
                                Image(systemName: progress.habit.iconName)
                            }
                        }
                            .foregroundStyle(AppTheme.tint)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        Text(progress.habit.title)
                            .font(.headline)
                        Spacer()
                        Text("\(progress.completedCount)回完了")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var reflectedHabits: [Habit] {
        habits
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var reflectionDates: [Date] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - 6, to: todayStart)
        }
    }

    private func reflectionStamp(for habit: Habit, on date: Date) -> some View {
        let achievement = records.first {
            $0.habit?.id == habit.id && Calendar.current.isDate($0.targetDate, inSameDayAs: date)
        }?.achievement

        return Group {
            if let achievement {
                AchievementFaceIcon(achievement: achievement, compact: true, size: 30)
            } else {
                Text("・")
                    .font(.title3)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.chipBackground.opacity(0.14), in: Circle())
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityLabel(achievement?.title ?? "記録なし")
    }

    private func dayLabel(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let weekday = Calendar.current.component(.weekday, from: date)
        let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
        return "\(day)\n\(weekdaySymbols[max(0, weekday - 1)])"
    }
}

#Preview {
    NavigationStack { ProgressDashboardView() }
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
