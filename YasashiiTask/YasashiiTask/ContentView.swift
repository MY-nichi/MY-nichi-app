//
//  ContentView.swift
//  YasashiiTask
//
//  Created by kishiko on 2026/07/18.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var habits: [Habit]
    @Query private var cards: [TaskCard]
    @State private var widgetViewModel = TodayViewModel()
    let startupWarning: String?

    init(startupWarning: String? = nil) {
        self.startupWarning = startupWarning
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "sun.max")
                }

            HabitListView()
                .tabItem {
                    Label("習慣", systemImage: "leaf")
                }

            IndependentTaskListView()
                .tabItem {
                    Label("タスク", systemImage: "checkmark.square")
                }

            HistoryCalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .tint(AppTheme.tint)
        .preferredColorScheme(.light)
        .onAppear(perform: updateWidgetSnapshot)
        .onChange(of: habits.map(\.updatedAt)) { _, _ in updateWidgetSnapshot() }
        .onChange(of: cards.map(\.updatedAt)) { _, _ in updateWidgetSnapshot() }
        .safeAreaInset(edge: .top) {
            if let startupWarning {
                Label(startupWarning, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .accessibilityElement(children: .combine)
            }
        }
    }

    private func updateWidgetSnapshot() {
        WidgetSnapshotService.save(
            habits: widgetViewModel.habitsForToday(from: habits),
            cards: widgetViewModel.independentCardsForToday(from: cards)
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Habit.self,
            TaskCard.self,
            ChecklistItem.self,
            CompletionRecord.self,
            AppSettings.self,
        ], inMemory: true)
}
