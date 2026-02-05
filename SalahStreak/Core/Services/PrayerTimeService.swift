import Foundation
import Adhan

final class PrayerTimeService: PrayerTimeServiceProtocol {

    func prayerWindows(for date: Date, latitude: Double, longitude: Double, method: CalculationMethodType, madhab: MadhabType) -> [PrayerWindow] {
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)

        var params = method.adhanParameters
        params.madhab = madhab == .hanafi ? .hanafi : .shafi

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let prayerTimes = PrayerTimes(coordinates: coordinates, date: dateComponents, calculationParameters: params) else {
            return []
        }

        // Compute next day's fajr for isha window end
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        let nextDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: nextDay)
        let nextPrayerTimes = PrayerTimes(coordinates: coordinates, date: nextDateComponents, calculationParameters: params)

        let ishaEnd = nextPrayerTimes?.fajr ?? Calendar.current.date(byAdding: .hour, value: 6, to: prayerTimes.isha)!

        return [
            PrayerWindow(prayer: .fajr,    start: prayerTimes.fajr,    end: prayerTimes.sunrise,  scheduledTime: prayerTimes.fajr),
            PrayerWindow(prayer: .dhuhr,   start: prayerTimes.dhuhr,   end: prayerTimes.asr,      scheduledTime: prayerTimes.dhuhr),
            PrayerWindow(prayer: .asr,     start: prayerTimes.asr,     end: prayerTimes.maghrib,  scheduledTime: prayerTimes.asr),
            PrayerWindow(prayer: .maghrib, start: prayerTimes.maghrib, end: prayerTimes.isha,     scheduledTime: prayerTimes.maghrib),
            PrayerWindow(prayer: .isha,    start: prayerTimes.isha,    end: ishaEnd,              scheduledTime: prayerTimes.isha),
        ]
    }
}

private extension CalculationMethodType {
    var adhanParameters: CalculationParameters {
        switch self {
        case .muslimWorldLeague:      return CalculationMethod.muslimWorldLeague.params
        case .egyptian:               return CalculationMethod.egyptian.params
        case .umMalaysia:             return CalculationMethod.singapore.params
        case .northAmerica:           return CalculationMethod.northAmerica.params
        case .muslim_league_of_india: return CalculationMethod.karachi.params
        }
    }
}
