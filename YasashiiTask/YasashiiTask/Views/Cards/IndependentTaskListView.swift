import SwiftData
import SwiftUI

struct IndependentTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [TaskCard]
    @State private var viewModel = TaskCardsViewModel()
    @State private var cardBeingEdited: TaskCard?
    @State private var isCreatingCard = false

    private var cards: [TaskCard] {
        viewModel.sortedCards(from: allCards.filter { $0.habit == nil })
    }

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "タスクはまだありません",
                        systemImage: "checkmark.square",
                        description: Text("今日タブからタスクを作成できます。")
                    )
                } else {
                    List {
                        ForEach(cards) { card in
                            Button {
                                cardBeingEdited = card
                            } label: {
                                TaskCardRowView(
                                    card: card,
                                    showsDueDate: false,
                                    showsSchedule: true,
                                    strikesThroughCompletedTitle: false
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("削除", systemImage: "trash", role: .destructive) {
                                    viewModel.requestDeletion(of: card)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("タスク")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("タスクを追加", systemImage: "plus") {
                        isCreatingCard = true
                    }
                    .accessibilityHint("新しいタスクの入力画面を開きます")
                }
            }
            .background(AppTheme.screenBackground)
            .sheet(isPresented: $isCreatingCard) {
                TaskCardFormView(card: nil, nextSortOrder: viewModel.nextSortOrder(from: cards))
            }
            .sheet(item: $cardBeingEdited) { card in
                TaskCardFormView(card: card, nextSortOrder: card.sortOrder)
            }
            .confirmationDialog(
                "タスクを削除しますか？",
                isPresented: deletionBinding,
                titleVisibility: .visible
            ) {
                Button("削除する", role: .destructive) {
                    viewModel.deletePendingCard(using: modelContext)
                }
                Button("キャンセル", role: .cancel) {
                    viewModel.cancelDeletion()
                }
            }
            .alert("削除できませんでした", isPresented: errorBinding) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーです。")
            }
        }
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
    IndependentTaskListView()
        .modelContainer(for: [Habit.self, TaskCard.self, ChecklistItem.self, CompletionRecord.self, AppSettings.self], inMemory: true)
}
