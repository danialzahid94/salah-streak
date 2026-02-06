import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var date: Date  // start of day
    @Relationship(deleteRule: .cascade)
    var entries: [PrayerEntry] = []
    var streakProtected: Bool = false
    var createdAt: Date = Date()

    var isPerfect: Bool { entries.filter { $0.status == .done }.count == 5 }
    var completedCount: Int { entries.filter { $0.status == .done || $0.status == .qada }.count }
    var isStreakSafe: Bool { entries.count == 5 && entries.allSatisfy { $0.status == .done || $0.status == .qada } }

    init(date: Date) {
        self.date = date
    }
}
