import Foundation
import SwiftData

@Model
final class PrayerEntry {
    var id: UUID = UUID()
    var prayer: PrayerType = PrayerType.fajr
    var scheduledDate: Date = Date()
    var windowStart: Date = Date()
    var windowEnd: Date = Date()
    var performedAt: Date?
    var status: PrayerStatus = PrayerStatus.pending
    var source: EntrySource = EntrySource.app
    var latitude: Double?
    var longitude: Double?

    @Relationship(inverse: \DailyLog.entries)
    var dailyLog: DailyLog?

    init(prayer: PrayerType, scheduledDate: Date, windowStart: Date, windowEnd: Date) {
        self.prayer = prayer
        self.scheduledDate = scheduledDate
        self.windowStart = windowStart
        self.windowEnd = windowEnd
    }
}
