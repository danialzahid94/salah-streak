import Foundation

final class BadgeService: BadgeServiceProtocol {

    private static let allBadges: [(id: BadgeID, title: String, description: String, icon: String)] = [
        (.firstPrayer,  "First Prayer",  "Complete your very first prayer.",             "star"),
        (.perfectDay,   "Perfect Day",   "Complete all 5 prayers in a single day.",     "checkmark.seal"),
        (.weekWarrior,  "Week Warrior",  "Maintain a 7-day streak.",                    "flame"),
        (.monthMaster,  "Month Master",  "Maintain a 30-day streak.",                   "trophy"),
        (.earlyBird,    "Early Bird",    "Complete 10 Fajr prayers on time.",           "sunrise"),
        (.consistent,   "Consistent",    "Complete 50 total prayers.",                  "heart.fill"),
    ]

    func checkAndAwardBadges(stats: UserStats, dailyLog: DailyLog) -> [Badge] {
        var newlyAwarded: [Badge] = []

        for def in Self.allBadges {
            let alreadyOwned = stats.badgesUnlocked.contains(def.id.rawValue)
            let unlocked = alreadyOwned || isUnlocked(def.id, stats: stats, dailyLog: dailyLog)

            if unlocked && !alreadyOwned {
                stats.badgesUnlocked.append(def.id.rawValue)
                newlyAwarded.append(Badge(id: def.id.rawValue, title: def.title, description: def.description, icon: def.icon, isUnlocked: true))
            }
        }
        return newlyAwarded
    }

    // MARK: - Private

    private func isUnlocked(_ id: BadgeID, stats: UserStats, dailyLog: DailyLog) -> Bool {
        switch id {
        case .firstPrayer:  return stats.totalPrayers >= 1
        case .perfectDay:   return dailyLog.isPerfect
        case .weekWarrior:  return stats.currentStreak >= 7
        case .monthMaster:  return stats.currentStreak >= 30
        case .earlyBird:    return false  // tracked separately via stats extension
        case .consistent:   return stats.totalPrayers >= 50
        }
    }
}
