import SwiftUI

enum TaskAchievement: String, CaseIterable, Identifiable {
    case needsPractice = "needsPractice"
    case achieved = "achieved"
    case excellent = "excellent"

    var id: String { rawValue }

    var mark: String {
        switch self {
        case .needsPractice: "△"
        case .achieved: "○"
        case .excellent: "◎"
        }
    }

    var title: String {
        switch self {
        case .needsPractice: "もうちょっと"
        case .achieved: "できた"
        case .excellent: "よくできた"
        }
    }

    var color: Color {
        switch self {
        case .needsPractice: Color(red: 0.92, green: 0.65, blue: 0.08)
        case .achieved: Color(red: 0.00, green: 0.55, blue: 0.38)
        case .excellent: Color(red: 0.94, green: 0.34, blue: 0.55)
        }
    }

    init?(storedStatus: String) {
        if storedStatus == "completed" {
            self = .achieved
        } else {
            self.init(rawValue: storedStatus)
        }
    }
}
