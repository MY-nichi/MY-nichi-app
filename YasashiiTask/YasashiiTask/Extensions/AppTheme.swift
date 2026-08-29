import SwiftUI

enum AppTheme {
    static let tint = Color(red: 0.00, green: 0.55, blue: 0.40)
    static let screenBackground = Color(red: 0.86, green: 1.00, blue: 0.95)
    static let screenBackgroundTop = Color(red: 0.76, green: 0.97, blue: 0.88)
    static let screenBackgroundBottom = Color(red: 0.94, green: 1.00, blue: 0.92)
    static let cardBackground = Color.white
    static let softGreen = Color(red: 0.74, green: 0.96, blue: 0.86)
    static let chipBackground = Color(red: 0.80, green: 0.98, blue: 0.91)
    static let cardStroke = Color(red: 0.42, green: 0.82, blue: 0.70)
    static let cardShadow = Color(red: 0.03, green: 0.34, blue: 0.25).opacity(0.16)

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [screenBackgroundTop, screenBackground, screenBackgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.98), softGreen.opacity(0.98), Color(red: 0.67, green: 0.93, blue: 0.82).opacity(0.80)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func polishedCard(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(
                AppTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.cardStroke.opacity(0.82), lineWidth: 1.2)
            }
            .shadow(color: Color.white.opacity(0.72), radius: 1, x: -1, y: -1)
            .shadow(color: AppTheme.cardShadow, radius: 18, x: 0, y: 9)
    }

    func appScreenBackground() -> some View {
        self.background(AppTheme.screenGradient.ignoresSafeArea())
    }
}
