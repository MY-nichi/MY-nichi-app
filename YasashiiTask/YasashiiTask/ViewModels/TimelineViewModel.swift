import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class TimelineViewModel {
    var errorMessage: String?

    func timedCards(from cards: [TaskCard]) -> [TaskCard] {
        cards
            .filter { $0.startTime != nil }
            .sorted {
                if $0.startTime == $1.startTime { return $0.sortOrder < $1.sortOrder }
                return ($0.startTime ?? .distantFuture) < ($1.startTime ?? .distantFuture)
            }
    }

    func untimedCards(from cards: [TaskCard]) -> [TaskCard] {
        cards
            .filter { $0.startTime == nil }
            .sorted {
                if $0.sortOrder == $1.sortOrder { return $0.createdAt < $1.createdAt }
                return $0.sortOrder < $1.sortOrder
            }
    }

    func moveCards(
        _ cards: [TaskCard],
        from source: IndexSet,
        to destination: Int,
        using modelContext: ModelContext
    ) {
        var reordered = cards
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, card) in reordered.enumerated() {
            card.sortOrder = index
            card.updatedAt = .now
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "並び順を保存できませんでした。もう一度お試しください。"
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
