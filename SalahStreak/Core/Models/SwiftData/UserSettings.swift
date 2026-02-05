import Foundation
import SwiftData

@Model
final class UserSettings {
    var calculationMethod: CalculationMethodType = .muslimWorldLeague
    var madhab: MadhabType = .shafi
    var latitude: Double?
    var longitude: Double?
    var cityName: String?
    var notificationsEnabled: Bool = true
}
