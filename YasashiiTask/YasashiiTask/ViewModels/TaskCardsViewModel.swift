import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TaskCardsViewModel {
    var cardPendingDeletion: TaskCard?
    var errorMessage: String?

    func sortedCards(from cards: [TaskCard]) -> [TaskCard] {
        cards.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.createdAt < $1.createdAt
        }
    }

    func nextSortOrder(from cards: [TaskCard]) -> Int {
        (cards.map(\.sortOrder).max() ?? -1) + 1
    }

    func requestDeletion(of card: TaskCard) {
        cardPendingDeletion = card
    }

    func cancelDeletion() {
        cardPendingDeletion = nil
    }

    func deletePendingCard(using modelContext: ModelContext) {
        guard let card = cardPendingDeletion else { return }
        NotificationService.removeTaskReminder(for: card.id)
        modelContext.delete(card)
        cardPendingDeletion = nil

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "カードを削除できませんでした。もう一度お試しください。"
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
