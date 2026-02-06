import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date = Date()  // start of day
    @Relationship(deleteRule: .cascade)
    var entries: [PrayerEntry]? = []
    var streakProtected: Bool = false
    var createdAt: Date = Date()

    var safeEntries: [PrayerEntry] { entries ?? [] }
    var isPerfect: Bool { safeEntries.filter { $0.status == .done }.count == 5 }
    var completedCount: Int { safeEntries.filter { $0.status == .done || $0.status == .qada }.count }
    var isStreakSafe: Bool { safeEntries.count == 5 && safeEntries.allSatisfy { $0.status == .done || $0.status == .qada } }

    init(date: Date) {
        self.date = date
    }
}
