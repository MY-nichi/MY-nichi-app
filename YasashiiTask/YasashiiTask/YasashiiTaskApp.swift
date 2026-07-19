//
//  YasashiiTaskApp.swift
//  YasashiiTask
//
//  Created by kishiko on 2026/07/18.
//

import SwiftUI
import SwiftData

@main
struct YasashiiTaskApp: App {
    private let dataStore = AppDataStore.make()

    var body: some Scene {
        WindowGroup {
            ContentView(startupWarning: dataStore.warning)
        }
        .modelContainer(dataStore.container)
    }
}

private struct AppDataStore {
    let container: ModelContainer
    let warning: String?

    static func make() -> AppDataStore {
        let schema = Schema([
            Habit.self,
            TaskCard.self,
            ChecklistItem.self,
            CompletionRecord.self,
            AppSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return AppDataStore(
                container: try ModelContainer(for: schema, configurations: [modelConfiguration]),
                warning: nil
            )
        } catch {
            let temporaryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return AppDataStore(
                    container: try ModelContainer(for: schema, configurations: [temporaryConfiguration]),
                    warning: "端末内のデータを読み込めないため、一時保存モードで起動しています。アプリを終了すると今回の変更は消えます。"
                )
            } catch {
                fatalError("一時保存モードも開始できませんでした。")
            }
        }
    }
}
