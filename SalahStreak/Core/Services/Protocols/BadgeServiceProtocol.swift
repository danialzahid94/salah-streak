import Foundation

protocol BadgeServiceProtocol {
    func checkAndAwardBadges(stats: UserStats, dailyLog: DailyLog) -> [Badge]
}
