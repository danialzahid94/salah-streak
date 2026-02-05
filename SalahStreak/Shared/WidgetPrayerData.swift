import Foundation

/// Shared data structure persisted in App Group UserDefaults for widget access.
struct WidgetPrayerData: Codable {
    let prayers: [WidgetPrayerEntry]
    let currentStreak: Int
    let updatedAt: Date

    struct WidgetPrayerEntry: Codable {
        let prayer: String      // PrayerType raw value
        let status: String      // PrayerStatus raw value
        let scheduledTime: Date
        let windowEnd: Date
    }

    // MARK: - Persistence

    static let userDefaultsKey = "com.danial.SalahStreak.widgetData"
    static let appGroupID      = "group.com.danial.SalahStreak"

    static var shared: WidgetPrayerData? {
        get {
            guard let defaults = UserDefaults(suiteName: appGroupID),
                  let data = defaults.data(forKey: userDefaultsKey) else { return nil }
            return try? JSONDecoder().decode(WidgetPrayerData.self, from: data)
        }
        set {
            guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
            defaults.set(try? JSONEncoder().encode(newValue), forKey: userDefaultsKey)
        }
    }

    // MARK: - Helpers

    var currentPrayer: WidgetPrayerEntry? {
        let now = Date()
        return prayers.first { $0.status == "pending" && now < $0.windowEnd }
    }

    var completedCount: Int {
        prayers.filter { $0.status == "done" }.count
    }
}
