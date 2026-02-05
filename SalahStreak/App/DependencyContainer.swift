import Foundation

/// Lightweight service locator — swap implementations for testing.
final class DependencyContainer {
    static let shared = DependencyContainer()

    lazy var prayerTimeService: PrayerTimeServiceProtocol = PrayerTimeService()
    lazy var notificationService: NotificationServiceProtocol = NotificationService()
    lazy var locationService: LocationServiceProtocol = LocationService()
    lazy var streakService: StreakServiceProtocol = StreakService()
    lazy var badgeService: BadgeServiceProtocol = BadgeService()

    private init() {}
}
