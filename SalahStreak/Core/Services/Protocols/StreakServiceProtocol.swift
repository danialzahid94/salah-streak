import Foundation

protocol StreakServiceProtocol {
    func processDayEnd(dailyLog: DailyLog, stats: UserStats)
}
