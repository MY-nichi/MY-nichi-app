import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var errorMessage: String?

    func ensureSettings(_ settings: [AppSettings], using context: ModelContext) {
        guard settings.isEmpty else { return }
        context.insert(AppSettings())
        save(using: context)
    }

    func save(using context: ModelContext) {
        do {
            try context.save()
        } catch {
            context.rollback()
            errorMessage = "設定を保存できませんでした。もう一度お試しください。"
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func colorScheme(for theme: String) -> ColorScheme? {
        switch theme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}
