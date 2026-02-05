import Foundation

struct Badge: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
}

enum BadgeID: String {
    case firstPrayer    = "first_prayer"
    case perfectDay     = "perfect_day"
    case weekWarrior    = "week_warrior"
    case monthMaster    = "month_master"
    case earlyBird      = "early_bird"
    case consistent     = "consistent"
}
