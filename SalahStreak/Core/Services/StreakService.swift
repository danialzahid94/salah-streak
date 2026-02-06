import Foundation

final class StreakService: StreakServiceProtocol {

    /// Call this at end-of-day (midnight or next-app-open) for the completed day.
    func processDayEnd(dailyLog: DailyLog, stats: UserStats) {
        if dailyLog.isPerfect {
            stats.currentStreak += 1
            if stats.currentStreak > stats.bestStreak {
                stats.bestStreak = stats.currentStreak
            }
            // Award a freeze every 7 consecutive perfect days
            if stats.currentStreak % 7 == 0 {
                stats.freezesAvailable += 1
            }
        } else if dailyLog.isStreakSafe {
            // Qada day: streak survives without consuming a freeze
            dailyLog.streakProtected = true
        } else {
            if stats.freezesAvailable > 0 {
                stats.freezesAvailable -= 1
                dailyLog.streakProtected = true
                // Streak survives — do nothing else
            } else {
                stats.currentStreak = 0
            }
        }
    }
}
