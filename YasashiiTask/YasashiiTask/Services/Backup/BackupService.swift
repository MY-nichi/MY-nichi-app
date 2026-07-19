import Foundation
import SwiftData

enum BackupError: LocalizedError {
    case invalidFile
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .invalidFile: "バックアップファイルを読み込めませんでした。"
        case .unsupportedVersion: "このバックアップ形式には対応していません。"
        }
    }
}

struct BackupPackage: Codable {
    let version: Int
    let exportedAt: Date
    let habits: [HabitBackup]
    let cards: [TaskCardBackup]
    let checklistItems: [ChecklistItemBackup]
    let completionRecords: [CompletionRecordBackup]
    let settings: [AppSettingsBackup]
}

struct HabitBackup: Codable {
    let id: UUID; let title: String; let detail: String; let category: String
    let iconName: String; let colorHex: String; let startDate: Date; let endDate: Date?
    let activeDays: [Int]; let reminderTime: Date?; let targetCount: Int; let sortOrder: Int
    let isActive: Bool; let isArchived: Bool; let createdAt: Date; let updatedAt: Date
}

struct TaskCardBackup: Codable {
    let id: UUID; let habitID: UUID?; let title: String; let detail: String; let memo: String
    let dueDate: Date?; let startTime: Date?; let endTime: Date?; let priority: String
    let iconName: String; let colorHex: String; let sortOrder: Int; let isCompleted: Bool
    let completedAt: Date?; let repeatRule: String?; let tags: [String]; let createdAt: Date; let updatedAt: Date
}

struct ChecklistItemBackup: Codable {
    let id: UUID; let taskCardID: UUID?; let title: String; let isCompleted: Bool; let sortOrder: Int
}

struct CompletionRecordBackup: Codable {
    let id: UUID; let habitID: UUID?; let taskCardID: UUID?; let targetDate: Date
    let completedAt: Date?; let status: String; let memo: String
}

struct AppSettingsBackup: Codable {
    let id: UUID; let theme: String; let notificationsEnabled: Bool; let hapticsEnabled: Bool
    let backupReminderEnabled: Bool; let lastBackupDate: Date?; let hasCompletedOnboarding: Bool
}

@MainActor
enum BackupService {
    static func makeData(
        habits: [Habit],
        cards: [TaskCard],
        checklistItems: [ChecklistItem],
        completionRecords: [CompletionRecord],
        settings: [AppSettings],
        exportedAt: Date = .now
    ) throws -> Data {
        let package = BackupPackage(
            version: 1,
            exportedAt: exportedAt,
            habits: habits.map { .init(id: $0.id, title: $0.title, detail: $0.detail, category: $0.category, iconName: $0.iconName, colorHex: $0.colorHex, startDate: $0.startDate, endDate: $0.endDate, activeDays: $0.activeDays, reminderTime: $0.reminderTime, targetCount: $0.targetCount, sortOrder: $0.sortOrder, isActive: $0.isActive, isArchived: $0.isArchived, createdAt: $0.createdAt, updatedAt: $0.updatedAt) },
            cards: cards.map { .init(id: $0.id, habitID: $0.habit?.id, title: $0.title, detail: $0.detail, memo: $0.memo, dueDate: $0.dueDate, startTime: $0.startTime, endTime: $0.endTime, priority: $0.priority, iconName: $0.iconName, colorHex: $0.colorHex, sortOrder: $0.sortOrder, isCompleted: $0.isCompleted, completedAt: $0.completedAt, repeatRule: $0.repeatRule, tags: $0.tags, createdAt: $0.createdAt, updatedAt: $0.updatedAt) },
            checklistItems: checklistItems.map { .init(id: $0.id, taskCardID: $0.taskCard?.id, title: $0.title, isCompleted: $0.isCompleted, sortOrder: $0.sortOrder) },
            completionRecords: completionRecords.map { .init(id: $0.id, habitID: $0.habit?.id, taskCardID: $0.taskCard?.id, targetDate: $0.targetDate, completedAt: $0.completedAt, status: $0.status, memo: $0.memo) },
            settings: settings.map { .init(id: $0.id, theme: $0.theme, notificationsEnabled: $0.notificationsEnabled, hapticsEnabled: $0.hapticsEnabled, backupReminderEnabled: $0.backupReminderEnabled, lastBackupDate: $0.lastBackupDate, hasCompletedOnboarding: $0.hasCompletedOnboarding) }
        )
        return try encoder.encode(package)
    }

    static func decode(_ data: Data) throws -> BackupPackage {
        let package: BackupPackage
        do {
            package = try decoder.decode(BackupPackage.self, from: data)
        } catch {
            throw BackupError.invalidFile
        }
        guard package.version == 1 else { throw BackupError.unsupportedVersion }
        try validate(package)
        return package
    }

    static func restore(_ data: Data, using context: ModelContext) throws {
        let package = try decode(data)

        for item in try context.fetch(FetchDescriptor<CompletionRecord>()) {
            context.delete(item)
        }
        for item in try context.fetch(FetchDescriptor<ChecklistItem>()) {
            context.delete(item)
        }
        try context.save()

        for item in try context.fetch(FetchDescriptor<TaskCard>()) {
            context.delete(item)
        }
        try context.save()

        for item in try context.fetch(FetchDescriptor<Habit>()) {
            context.delete(item)
        }
        for item in try context.fetch(FetchDescriptor<AppSettings>()) {
            context.delete(item)
        }
        try context.save()

        var habitsByID: [UUID: Habit] = [:]
        for item in package.habits {
            let habit = Habit(id: item.id, title: item.title, detail: item.detail, category: item.category, iconName: item.iconName, colorHex: item.colorHex, startDate: item.startDate, endDate: item.endDate, activeDays: item.activeDays, reminderTime: item.reminderTime, targetCount: item.targetCount, sortOrder: item.sortOrder, isActive: item.isActive, isArchived: item.isArchived, createdAt: item.createdAt, updatedAt: item.updatedAt)
            context.insert(habit)
            habitsByID[item.id] = habit
        }

        var cardsByID: [UUID: TaskCard] = [:]
        for item in package.cards {
            let card = TaskCard(id: item.id, habit: item.habitID.flatMap { habitsByID[$0] }, title: item.title, detail: item.detail, memo: item.memo, dueDate: item.dueDate, startTime: item.startTime, endTime: item.endTime, priority: item.priority, iconName: item.iconName, colorHex: item.colorHex, sortOrder: item.sortOrder, isCompleted: item.isCompleted, completedAt: item.completedAt, repeatRule: item.repeatRule, tags: item.tags, createdAt: item.createdAt, updatedAt: item.updatedAt)
            context.insert(card)
            cardsByID[item.id] = card
        }

        for item in package.checklistItems {
            context.insert(ChecklistItem(id: item.id, taskCard: item.taskCardID.flatMap { cardsByID[$0] }, title: item.title, isCompleted: item.isCompleted, sortOrder: item.sortOrder))
        }
        for item in package.completionRecords {
            context.insert(CompletionRecord(id: item.id, habit: item.habitID.flatMap { habitsByID[$0] }, taskCard: item.taskCardID.flatMap { cardsByID[$0] }, targetDate: item.targetDate, completedAt: item.completedAt, status: item.status, memo: item.memo))
        }
        for item in package.settings {
            context.insert(AppSettings(id: item.id, theme: item.theme, notificationsEnabled: item.notificationsEnabled, hapticsEnabled: item.hapticsEnabled, backupReminderEnabled: item.backupReminderEnabled, lastBackupDate: item.lastBackupDate, hasCompletedOnboarding: item.hasCompletedOnboarding))
        }
        try context.save()
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func validate(_ package: BackupPackage) throws {
        let habitIDs = Set(package.habits.map(\.id))
        let cardIDs = Set(package.cards.map(\.id))
        guard habitIDs.count == package.habits.count,
              cardIDs.count == package.cards.count,
              Set(package.checklistItems.map(\.id)).count == package.checklistItems.count,
              Set(package.completionRecords.map(\.id)).count == package.completionRecords.count,
              Set(package.settings.map(\.id)).count == package.settings.count else {
            throw BackupError.invalidFile
        }
        guard package.cards.allSatisfy({ item in
                  guard let habitID = item.habitID else { return true }
                  return habitIDs.contains(habitID)
              }),
              package.checklistItems.allSatisfy({ item in
                  guard let taskCardID = item.taskCardID else { return true }
                  return cardIDs.contains(taskCardID)
              }),
              package.completionRecords.allSatisfy({ record in
                  let hasHabit = record.habitID.map(habitIDs.contains) ?? true
                  let hasCard = record.taskCardID.map(cardIDs.contains) ?? true
                  return hasHabit && hasCard
              }) else {
            throw BackupError.invalidFile
        }
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
