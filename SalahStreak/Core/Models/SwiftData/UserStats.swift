import Foundation
import SwiftData

@Model
final class UserStats {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var freezesAvailable: Int = 0
    var totalPrayers: Int = 0
    var badgesUnlocked: [String] = []
    var hasCompletedOnboarding: Bool = false
}
