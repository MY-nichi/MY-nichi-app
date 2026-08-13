import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var theme: String
    var notificationsEnabled: Bool
    var hapticsEnabled: Bool
    var backupReminderEnabled: Bool
    var lastBackupDate: Date?
    var hasCompletedOnboarding: Bool
    var displayName: String?

    init(
        id: UUID = UUID(),
        theme: String = "system",
        notificationsEnabled: Bool = false,
        hapticsEnabled: Bool = true,
        backupReminderEnabled: Bool = false,
        lastBackupDate: Date? = nil,
        hasCompletedOnboarding: Bool = false,
        displayName: String? = nil
    ) {
        self.id = id
        self.theme = theme
        self.notificationsEnabled = notificationsEnabled
        self.hapticsEnabled = hapticsEnabled
        self.backupReminderEnabled = backupReminderEnabled
        self.lastBackupDate = lastBackupDate
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.displayName = displayName
    }
}
