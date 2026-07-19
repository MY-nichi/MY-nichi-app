import SwiftData
import SwiftUI

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @State private var viewModel = HabitsViewModel()
    @State private var habitBeingEdited: Habit?
    @State private var isCreatingHabit = false

    private var visibleHabits: [Habit] {
        viewModel.visibleHabits(from: habits)
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleHabits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .navigationTitle("習慣")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        BackupRestoreView()
                    } label: {
                        Label("バックアップ", systemImage: "externaldrive")
                    }
                    .accessibilityHint("バックアップと復元の画面を開きます")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("習慣を追加", systemImage: "plus") {
                        isCreatingHabit = true
                    }
                    .accessibilityHint("新しい習慣の入力画面を開きます")
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $isCreatingHabit) {
            HabitFormView(habit: nil, nextSortOrder: viewModel.nextSortOrder(from: habits))
        }
        .sheet(item: $habitBeingEdited) { habit in
            HabitFormView(habit: habit, nextSortOrder: habit.sortOrder)
        }
        .confirmationDialog(
            "習慣を削除しますか？",
            isPresented: Binding(
                get: { viewModel.habitPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.cancelDeletion()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                viewModel.deletePendingHabit(using: modelContext)
            }
            Button("キャンセル", role: .cancel) {
                viewModel.cancelDeletion()
            }
        } message: {
            Text("関連するカードと完了履歴も削除されます。この操作は元に戻せません。")
        }
        .alert(
            "保存できませんでした",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearError()
                    }
                }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーです。")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("習慣はまだありません", systemImage: "leaf")
        } description: {
            Text("右上の＋ボタンから、続けたい習慣を登録できます。")
        }
        .accessibilityElement(children: .combine)
    }

    private var habitList: some View {
        List {
            ForEach(visibleHabits) { habit in
                NavigationLink {
                    TaskCardListView(habit: habit)
                } label: {
                    HabitRowView(habit: habit)
                }
                    .buttonStyle(.plain)
                    .listRowInsets(
                        EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16)
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("削除", systemImage: "trash", role: .destructive) {
                            viewModel.requestDeletion(of: habit)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button("編集", systemImage: "pencil") {
                            habitBeingEdited = habit
                        }
                        .tint(.blue)
                    }
                    .accessibilityAction(named: "編集") {
                        habitBeingEdited = habit
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .accessibilityLabel("習慣一覧")
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: [
            Habit.self,
            TaskCard.self,
            ChecklistItem.self,
            CompletionRecord.self,
            AppSettings.self,
        ], inMemory: true)
}
