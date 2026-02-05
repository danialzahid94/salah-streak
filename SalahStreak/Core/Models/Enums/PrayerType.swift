import Foundation

enum PrayerType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case fajr, dhuhr, asr, maghrib, isha

    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .fajr:    return "sunrise"
        case .dhuhr:   return "sun.max"
        case .asr:     return "sun.and.horizon"
        case .maghrib: return "sunset"
        case .isha:    return "moon.stars"
        }
    }
}
