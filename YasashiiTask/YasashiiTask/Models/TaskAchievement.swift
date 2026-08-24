import SwiftUI

enum TaskAchievement: String, CaseIterable, Identifiable {
    case excellent = "excellent"
    case needsPractice = "needsPractice"
    case achieved = "achieved"
    case rest = "rest"

    var id: String { rawValue }

    var mark: String {
        switch self {
        case .needsPractice: "🙂"
        case .achieved: "😌"
        case .excellent: "😄"
        case .rest: "😴"
        }
    }

    var title: String {
        switch self {
        case .needsPractice: "まあまあ"
        case .achieved: "できた"
        case .excellent: "よくできた"
        case .rest: "今日はお休み"
        }
    }

    var color: Color {
        switch self {
        case .needsPractice: Color(red: 0.92, green: 0.65, blue: 0.08)
        case .achieved: Color(red: 0.00, green: 0.55, blue: 0.38)
        case .excellent: Color(red: 0.94, green: 0.34, blue: 0.55)
        case .rest: Color(red: 0.42, green: 0.48, blue: 0.62)
        }
    }

    var countsAsCompletion: Bool {
        self != .rest
    }

    init?(storedStatus: String) {
        if storedStatus == "completed" {
            self = .achieved
        } else {
            self.init(rawValue: storedStatus)
        }
    }
}
