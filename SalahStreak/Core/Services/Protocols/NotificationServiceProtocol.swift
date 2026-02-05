import Foundation

protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func schedulePrayerNotifications(for windows: [PrayerWindow], on date: Date)
    func cancelNotifications(for prayer: PrayerType, on date: Date)
    func cancelAllNotifications()
}
