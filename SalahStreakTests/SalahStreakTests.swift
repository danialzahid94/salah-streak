//
//  SalahStreakTests.swift
//  SalahStreakTests
//
//  Created by Danial Zahid on 2026-02-05.
//

import Testing
import Foundation
@testable import SalahStreak

// MARK: - PrayerTimeService Tests

struct PrayerTimeServiceTests {

    let service = PrayerTimeService()

    @Test func returnsExactlyFivePrayerWindows() {
        let windows = service.prayerWindows(
            for: Date(),
            latitude: 21.4225,   // Mecca
            longitude: 39.8262,
            method: .muslimWorldLeague,
            madhab: .shafi
        )
        #expect(windows.count == 5)
    }

    @Test func prayerWindowsAreChrono() {
        let windows = service.prayerWindows(
            for: Date(),
            latitude: 40.7128,   // New York
            longitude: -74.0060,
            method: .northAmerica,
            madhab: .shafi
        )
        for i in 0..<(windows.count - 1) {
            #expect(windows[i].scheduledTime < windows[i + 1].scheduledTime)
        }
    }

    @Test func windowStartBeforeEnd() {
        let windows = service.prayerWindows(
            for: Date(),
            latitude: 51.5074,   // London
            longitude: -0.1278,
            method: .muslimWorldLeague,
            madhab: .hanafi
        )
        for w in windows {
            #expect(w.start < w.end)
        }
    }

    @Test func hanafi_asr_later_than_shafi() {
        let date = Date()
        let lat = 48.8566   // Paris
        let lng = 2.3522

        let shafi = service.prayerWindows(for: date, latitude: lat, longitude: lng, method: .muslimWorldLeague, madhab: .shafi)
        let hanafi = service.prayerWindows(for: date, latitude: lat, longitude: lng, method: .muslimWorldLeague, madhab: .hanafi)

        guard let shafAsr  = shafi.first(where:  { $0.prayer == .asr }),
              let hanAsr   = hanafi.first(where: { $0.prayer == .asr }) else {
            #expect(Bool(false), "Asr window not found")
            return
        }
        // Hanafi Asr is always equal or later than Shafi
        #expect(hanAsr.scheduledTime >= shafAsr.scheduledTime)
    }

    @Test func prayerTypesMatch() {
        let windows = service.prayerWindows(
            for: Date(),
            latitude: 0, longitude: 0,
            method: .muslimWorldLeague,
            madhab: .shafi
        )
        let expected: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        #expect(windows.map { $0.prayer } == expected)
    }
}

// MARK: - StreakService Tests

struct StreakServiceTests {

    let service = StreakService()

    @Test func perfectDayIncrementsStreak() {
        let stats = UserStats()
        stats.currentStreak = 3
        stats.bestStreak = 5

        let log = makeDailyLog(completedCount: 5)
        service.processDayEnd(dailyLog: log, stats: stats)

        #expect(stats.currentStreak == 4)
        #expect(stats.bestStreak == 5)  // still 5
    }

    @Test func perfectDayUpdatesBestStreak() {
        let stats = UserStats()
        stats.currentStreak = 7
        stats.bestStreak = 7

        let log = makeDailyLog(completedCount: 5)
        service.processDayEnd(dailyLog: log, stats: stats)

        #expect(stats.currentStreak == 8)
        #expect(stats.bestStreak == 8)
    }

    @Test func imperfectDayWithFreezeSurvives() {
        let stats = UserStats()
        stats.currentStreak = 5
        stats.freezesAvailable = 1

        let log = makeDailyLog(completedCount: 3)
        service.processDayEnd(dailyLog: log, stats: stats)

        #expect(stats.currentStreak == 5)
        #expect(stats.freezesAvailable == 0)
        #expect(log.streakProtected == true)
    }

    @Test func imperfectDayWithoutFreezeResetsStreak() {
        let stats = UserStats()
        stats.currentStreak = 10
        stats.freezesAvailable = 0

        let log = makeDailyLog(completedCount: 2)
        service.processDayEnd(dailyLog: log, stats: stats)

        #expect(stats.currentStreak == 0)
    }

    @Test func freezeAwardedEvery7Days() {
        let stats = UserStats()
        stats.currentStreak = 6
        stats.freezesAvailable = 0

        let log = makeDailyLog(completedCount: 5)
        service.processDayEnd(dailyLog: log, stats: stats)

        // streak becomes 7 → freeze awarded
        #expect(stats.currentStreak == 7)
        #expect(stats.freezesAvailable == 1)
    }

    // MARK: - Qada Tests

    @Test func qadaDayKeepsStreakWithoutFreeze() {
        let stats = UserStats()
        stats.currentStreak = 5
        stats.freezesAvailable = 0

        let log = makeDailyLog(doneCount: 3, qadaCount: 2)
        service.processDayEnd(dailyLog: log, stats: stats)

        // Streak survives even with 0 freezes
        #expect(stats.currentStreak == 5)
        #expect(log.streakProtected == true)
    }

    @Test func qadaDayDoesNotIncrementStreak() {
        let stats = UserStats()
        stats.currentStreak = 5
        stats.bestStreak = 5

        let log = makeDailyLog(doneCount: 3, qadaCount: 2)
        service.processDayEnd(dailyLog: log, stats: stats)

        // Streak stays the same (no increment)
        #expect(stats.currentStreak == 5)
        #expect(stats.bestStreak == 5)
    }

    @Test func qadaDayDoesNotConsumeFreeze() {
        let stats = UserStats()
        stats.currentStreak = 5
        stats.freezesAvailable = 2

        let log = makeDailyLog(doneCount: 3, qadaCount: 2)
        service.processDayEnd(dailyLog: log, stats: stats)

        // Freezes unchanged
        #expect(stats.freezesAvailable == 2)
        #expect(log.streakProtected == true)
    }

    // MARK: - Helpers

    /// Creates a DailyLog with the specified number of .done entries (no SwiftData context needed for unit logic).
    private func makeDailyLog(completedCount: Int) -> DailyLog {
        makeDailyLog(doneCount: completedCount, qadaCount: 0)
    }

    private func makeDailyLog(doneCount: Int, qadaCount: Int) -> DailyLog {
        let log = DailyLog(date: Calendar.current.startOfDay(for: Date()))
        let allPrayers = PrayerType.allCases
        for (i, prayer) in allPrayers.enumerated() {
            let entry = PrayerEntry(
                prayer: prayer,
                scheduledDate: Date(),
                windowStart: Date().addingTimeInterval(Double(i) * 3600),
                windowEnd:   Date().addingTimeInterval(Double(i) * 3600 + 3600)
            )
            if i < doneCount {
                entry.status = .done
            } else if i < doneCount + qadaCount {
                entry.status = .qada
            } else {
                entry.status = .pending
            }
            log.entries.append(entry)
        }
        return log
    }
}

// MARK: - PrayerType Tests

struct PrayerTypeTests {

    @Test func allCasesCount() {
        #expect(PrayerType.allCases.count == 5)
    }

    @Test func displayNameCapitalized() {
        for prayer in PrayerType.allCases {
            #expect(prayer.displayName == prayer.rawValue.capitalized)
        }
    }

    @Test func iconNonEmpty() {
        for prayer in PrayerType.allCases {
            #expect(!prayer.icon.isEmpty)
        }
    }
}

// MARK: - Badge Tests

struct BadgeServiceTests {

    let service = BadgeService()

    @Test func firstPrayerBadgeAwarded() {
        let stats = UserStats()
        stats.totalPrayers = 1

        let log = DailyLog(date: Calendar.current.startOfDay(for: Date()))
        let awarded = service.checkAndAwardBadges(stats: stats, dailyLog: log)

        #expect(awarded.contains(where: { $0.id == "first_prayer" }))
        #expect(stats.badgesUnlocked.contains("first_prayer"))
    }

    @Test func consistentBadgeAt50Prayers() {
        let stats = UserStats()
        stats.totalPrayers = 50

        let log = DailyLog(date: Calendar.current.startOfDay(for: Date()))
        let awarded = service.checkAndAwardBadges(stats: stats, dailyLog: log)

        #expect(awarded.contains(where: { $0.id == "consistent" }))
    }

    @Test func noDuplicateBadges() {
        let stats = UserStats()
        stats.totalPrayers = 1
        stats.badgesUnlocked = ["first_prayer"]

        let log = DailyLog(date: Calendar.current.startOfDay(for: Date()))
        let awarded = service.checkAndAwardBadges(stats: stats, dailyLog: log)

        // first_prayer already owned — should not be re-awarded
        #expect(!awarded.contains(where: { $0.id == "first_prayer" }))
    }
}

// MARK: - DailyLog Tests

struct DailyLogTests {

    @Test func isPerfectExcludesQada() {
        let log = makeDailyLog(doneCount: 4, qadaCount: 1)
        #expect(log.isPerfect == false)
    }

    @Test func isStreakSafeIncludesQada() {
        let log = makeDailyLog(doneCount: 3, qadaCount: 2)
        #expect(log.isStreakSafe == true)
    }

    @Test func completedCountIncludesQada() {
        let log = makeDailyLog(doneCount: 3, qadaCount: 2)
        #expect(log.completedCount == 5)
    }

    @Test func isStreakSafeRequiresAllAccountedFor() {
        let log = makeDailyLog(doneCount: 3, qadaCount: 1)
        // 1 prayer still pending → not streak safe
        #expect(log.isStreakSafe == false)
    }

    private func makeDailyLog(doneCount: Int, qadaCount: Int) -> DailyLog {
        let log = DailyLog(date: Calendar.current.startOfDay(for: Date()))
        let allPrayers = PrayerType.allCases
        for (i, prayer) in allPrayers.enumerated() {
            let entry = PrayerEntry(
                prayer: prayer,
                scheduledDate: Date(),
                windowStart: Date().addingTimeInterval(Double(i) * 3600),
                windowEnd:   Date().addingTimeInterval(Double(i) * 3600 + 3600)
            )
            if i < doneCount {
                entry.status = .done
            } else if i < doneCount + qadaCount {
                entry.status = .qada
            } else {
                entry.status = .pending
            }
            log.entries.append(entry)
        }
        return log
    }
}

// MARK: - WidgetPrayerData Tests

struct WidgetPrayerDataTests {

    @Test func currentPrayerReturnsActivePending() {
        let now = Date()
        let data = WidgetPrayerData(
            prayers: [
                WidgetPrayerData.WidgetPrayerEntry(prayer: "fajr",    status: "done",    scheduledTime: now.addingTimeInterval(-7200), windowEnd: now.addingTimeInterval(-3600)),
                WidgetPrayerData.WidgetPrayerEntry(prayer: "dhuhr",   status: "pending", scheduledTime: now.addingTimeInterval(-600),  windowEnd: now.addingTimeInterval(3600)),
            ],
            currentStreak: 5,
            updatedAt: now
        )
        #expect(data.currentPrayer?.prayer == "dhuhr")
    }

    @Test func completedCountCorrect() {
        let data = WidgetPrayerData(
            prayers: [
                WidgetPrayerData.WidgetPrayerEntry(prayer: "fajr",    status: "done",    scheduledTime: Date(), windowEnd: Date()),
                WidgetPrayerData.WidgetPrayerEntry(prayer: "dhuhr",   status: "done",    scheduledTime: Date(), windowEnd: Date()),
                WidgetPrayerData.WidgetPrayerEntry(prayer: "asr",     status: "pending", scheduledTime: Date(), windowEnd: Date()),
                WidgetPrayerData.WidgetPrayerEntry(prayer: "maghrib", status: "pending", scheduledTime: Date(), windowEnd: Date()),
                WidgetPrayerData.WidgetPrayerEntry(prayer: "isha",    status: "pending", scheduledTime: Date(), windowEnd: Date()),
            ],
            currentStreak: 3,
            updatedAt: Date()
        )
        #expect(data.completedCount == 2)
    }

    @Test func roundTripSerialization() throws {
        let original = WidgetPrayerData(
            prayers: [
                WidgetPrayerData.WidgetPrayerEntry(prayer: "fajr", status: "done", scheduledTime: Date(), windowEnd: Date()),
            ],
            currentStreak: 7,
            updatedAt: Date()
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetPrayerData.self, from: encoded)
        #expect(decoded.currentStreak == 7)
        #expect(decoded.prayers.count == 1)
    }
}
