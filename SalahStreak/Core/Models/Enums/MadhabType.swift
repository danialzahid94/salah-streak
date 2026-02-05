import Foundation

enum MadhabType: String, Codable, CaseIterable {
    case shafi, hanafi

    var displayName: String { rawValue.capitalized }
}
