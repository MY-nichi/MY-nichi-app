import SwiftData
import SwiftUI

struct TaskCardListView: View {
    @Environment(\.modelContext) private var modelContext
    let habit: Habit
    @State private var viewModel = TaskCardsViewModel()
    @State private var cardBeingEdited: TaskCard?
    @State private var isCreatingCard = false

    private var cards: [TaskCard] {
        viewModel.sortedCards(from: habit.taskCards)
    }

    var body: some View {
        Group {
            if cards.isEmpty {
                emptyState
            } else {
                cardList
            }
        }
        .navigationTitle(habit.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("カードを追加", systemImage: "plus") {
                    isCreatingCard = true
                }
                .accessibilityHint("新しいカードの入力画面を開きます")
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $isCreatingCard) {
            TaskCardFormView(
                habit: habit,
                card: nil,
                nextSortOrder: viewModel.nextSortOrder(from: habit.taskCards)
            )
        }
        .sheet(item: $cardBeingEdited) { card in
            TaskCardFormView(habit: habit, card: card, nextSortOrder: card.sortOrder)
        }
        .confirmationDialog(
            "カードを削除しますか？",
            isPresented: deletionBinding,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                viewModel.deletePendingCard(using: modelContext)
            }
            Button("キャンセル", role: .cancel) {
                viewModel.cancelDeletion()
            }
        } message: {
            Text("チェックリストと完了履歴も削除されます。この操作は元に戻せません。")
        }
        .alert("保存できませんでした", isPresented: errorBinding) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーです。")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("カードはまだありません", systemImage: "rectangle.stack")
        } description: {
            Text("右上の＋ボタンから、この習慣にカードを追加できます。")
        }
        .accessibilityElement(children: .combine)
    }

    private var cardList: some View {
        List {
            ForEach(cards) { card in
                TaskCardRowView(card: card)
                    .onTapGesture {
                        cardBeingEdited = card
                    }
                    .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("削除", systemImage: "trash", role: .destructive) {
                            viewModel.requestDeletion(of: card)
                        }
                    }
                    .accessibilityAction(named: "編集") {
                        cardBeingEdited = card
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .accessibilityLabel("\(habit.title)のカード一覧")
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.cardPendingDeletion != nil },
            set: { if !$0 { viewModel.cancelDeletion() } }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
}

#Preview {
    NavigationStack {
        TaskCardListView(habit: Habit(title: "朝の習慣"))
    }
    .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
