import SwiftUI

enum AppTheme {
    static let background = Color(red: 8/255, green: 12/255, blue: 20/255)
    static let surface = Color(red: 12/255, green: 18/255, blue: 32/255)
    static let accent = Color(red: 30/255, green: 64/255, blue: 175/255)
    static let accentLight = Color(red: 37/255, green: 99/255, blue: 235/255)
    static let gold = Color(red: 184/255, green: 149/255, blue: 62/255)
    static let text = Color(red: 232/255, green: 236/255, blue: 244/255)
    static let textSecondary = Color(red: 123/255, green: 138/255, blue: 166/255)
    static let textMuted = Color(red: 74/255, green: 85/255, blue: 104/255)

    static let accentGradient = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let ringGradient = LinearGradient(
        colors: [accent, gold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
