import Foundation
import UserNotifications

final class NotificationService: NotificationServiceProtocol {

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func registerCategories() {
        let markDone = UNNotificationAction(identifier: "MARK_DONE", title: "Mark Done")
        let snooze   = UNNotificationAction(identifier: "SNOOZE",    title: "Snooze 20m")
        let category = UNNotificationCategory(
            identifier: "PRAYER_REMINDER",
            actions: [markDone, snooze],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    func schedulePrayerNotifications(for windows: [PrayerWindow], on date: Date) {
        let dateString = DateFormatter.shared.string(from: date)

        for window in windows {
            let duration = window.end.timeIntervalSince(window.start)
            let cascadePoints: [Double] = [0.0, 0.25, 0.50, 0.85]

            for (index, fraction) in cascadePoints.enumerated() {
                let fireAt = window.start.addingTimeInterval(duration * fraction)

                // Enforce 30-minute minimum before window end for last notification
                if index == cascadePoints.count - 1 {
                    let remaining = window.end.timeIntervalSince(fireAt)
                    if remaining < 1800 { continue }
                }

                // Don't schedule notifications in the past
                if fireAt <= Date() { continue }

                let identifier = "\(window.prayer.rawValue)_\(dateString)_\(index)"
                scheduleNotification(
                    identifier: identifier,
                    prayer: window.prayer,
                    fireAt: fireAt,
                    cascadeIndex: index
                )
            }
        }
    }

    func cancelNotifications(for prayer: PrayerType, on date: Date) {
        let dateString = DateFormatter.shared.string(from: date)
        let identifiers = (0..<4).map { "\(prayer.rawValue)_\(dateString)_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Private

    private func scheduleNotification(identifier: String, prayer: PrayerType, fireAt: Date, cascadeIndex: Int) {
        let content = UNMutableNotificationContent()

        let messages: [String] = [
            "It's time for \(prayer.displayName) prayer.",
            "Don't forget your \(prayer.displayName) prayer.",
            "\(prayer.displayName) prayer — don't let it slip.",
            "Last reminder: \(prayer.displayName) prayer ends soon."
        ]
        content.title = "SalahStreak"
        content.body = messages[cascadeIndex]
        content.sound = .default
        content.categoryIdentifier = "PRAYER_REMINDER"
        content.userInfo = ["prayer": prayer.rawValue]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireAt),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
}

private extension DateFormatter {
    static let shared: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
