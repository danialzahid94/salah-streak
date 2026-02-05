import Foundation

enum CalculationMethodType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case muslimWorldLeague
    case egyptian
    case umMalaysia
    case northAmerica
    case muslim_league_of_india

    var displayName: String {
        switch self {
        case .muslimWorldLeague:      return "Muslim World League"
        case .egyptian:               return "Egyptian General Authority"
        case .umMalaysia:             return "UM Malaysia"
        case .northAmerica:           return "North America (ISNA)"
        case .muslim_league_of_india: return "Muslim League of India"
        }
    }
}
