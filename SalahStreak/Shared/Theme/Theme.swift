import SwiftUI

enum Theme {
    // MARK: - Colors
    static let accent       = Color("AccentColor")
    static let background   = Color(.systemBackground)
    static let cardBG       = Color.secondary.opacity(0.12)

    static let stateDone    = Color.green
    static let stateActive  = Color.blue
    static let stateWarning = Color.orange
    static let stateMissed  = Color.red
    static let stateFuture  = Color.gray

    // MARK: - Spacing
    static let spacing: CGFloat      = 16
    static let spacingSmall: CGFloat = 8
    static let spacingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 16
}
