import Foundation

protocol PrayerTimeServiceProtocol {
    func prayerWindows(for date: Date, latitude: Double, longitude: Double, method: CalculationMethodType, madhab: MadhabType) -> [PrayerWindow]
}
