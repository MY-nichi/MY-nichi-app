import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID = UUID()
    var theme: String = "system"
    var notificationsEnabled: Bool = false
    var hapticsEnabled: Bool = true
    var backupReminderEnabled: Bool = false
    var lastBackupDate: Date?
    var hasCompletedOnboarding: Bool = false
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
