import Foundation

enum Route: Hashable {
    case dashboard
    case prayerDetail(UUID)
    case badges
    case badgeDetail(String)          // Badge id
    case stats
    case historicalView(Date)
    case settings
    case calculationMethod
    case notificationPreferences
    case onboarding
    case locationPermission
    case madhabSelection
    case goalSelection
}
