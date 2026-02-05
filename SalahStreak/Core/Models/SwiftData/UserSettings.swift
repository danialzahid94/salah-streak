import Foundation
import SwiftData

@Model
final class UserSettings {
    var calculationMethod: CalculationMethodType = CalculationMethodType.muslimWorldLeague
    var madhab: MadhabType = MadhabType.shafi
    var latitude: Double?
    var longitude: Double?
    var cityName: String?
    var notificationsEnabled: Bool = true

    init() {}
}
