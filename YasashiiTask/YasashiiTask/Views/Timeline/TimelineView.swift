import SwiftData
import SwiftUI

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @State private var todayViewModel = TodayViewModel()
    @State private var viewModel = TimelineViewModel()
    @State private var now = Date.now
    @State private var editMode: EditMode = .inactive

    private var cards: [TaskCard] {
        todayViewModel.cardsForToday(from: habits, date: now)
    }

    private var timedCards: [TaskCard] { viewModel.timedCards(from: cards) }
    private var untimedCards: [TaskCard] { viewModel.untimedCards(from: cards) }

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    emptyState
                } else {
                    timelineList
                }
            }
            .navigationTitle("タイムライン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(editMode == .active ? "完了" : "並び替え") {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .appScreenBackground()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                now = .now
            }
        }
        .alert("保存できませんでした", isPresented: errorBinding) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーです。")
        }
    }

    private var timelineList: some View {
        List {
            Section {
                currentTimeLine
            }

            if !timedCards.isEmpty {
                Section("時刻あり") {
                    ForEach(timedCards) { card in
                        TimelineCardRow(card: card)
                    }
                    .onMove { source, destination in
                        viewModel.moveCards(timedCards, from: source, to: destination, using: modelContext)
                    }
                }
            }

            if !untimedCards.isEmpty {
                Section("時刻未設定") {
                    ForEach(untimedCards) { card in
                        TimelineCardRow(card: card)
                    }
                    .onMove { source, destination in
                        viewModel.moveCards(untimedCards, from: source, to: destination, using: modelContext)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityLabel("今日のタイムライン")
    }

    private var currentTimeLine: some View {
        HStack(spacing: 10) {
            Text(now.formatted(date: .omitted, time: .shortened))
                .font(.caption.monospacedDigit().bold())
            Rectangle()
                .fill(AppTheme.tint)
                .frame(height: 2)
            Text("現在")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(AppTheme.tint)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("現在時刻、\(now.formatted(date: .omitted, time: .shortened))")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("今日のカードはありません", systemImage: "clock")
        } description: {
            Text("習慣にカードを追加すると、ここに時間順で表示されます。")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.clearError() } })
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
