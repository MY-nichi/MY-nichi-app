//
//  ContentView.swift
//  YasashiiTask
//
//  Created by kishiko on 2026/07/18.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settings: [AppSettings]
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
        .tint(Color(red: 0.00, green: 0.45, blue: 0.30))
        .preferredColorScheme(preferredColorScheme)
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

    private var preferredColorScheme: ColorScheme? {
        switch settings.first?.theme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
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
