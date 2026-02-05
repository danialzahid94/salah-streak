import Foundation

enum MadhabType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case shafi, hanafi

    var displayName: String { rawValue.capitalized }
}
