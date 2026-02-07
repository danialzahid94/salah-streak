import Foundation

enum MadhabType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case hanafi, shafi

    var displayName: String { rawValue.capitalized }
}
