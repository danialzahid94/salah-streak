import Foundation
import CoreLocation

enum LocationError: Error {
    case timeout
}

final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Coordinate, Error>?

    var authorizationStatus: LocationAuthorizationStatus {
        switch manager.authorizationStatus {
        case .notDetermined:             return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse: return .granted
        default:                         return .denied
        }
    }

    func requestLocation() async throws -> Coordinate {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.startUpdatingLocation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                guard let self = self, self.continuation != nil else { return }
                self.manager.stopUpdatingLocation()
                self.continuation?.resume(throwing: LocationError.timeout)
                self.continuation = nil
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation()
        continuation?.resume(returning: Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        continuation?.resume(throwing: error)
        continuation = nil
    }

    // MARK: - Reverse geocoding

    func getCityName(for coordinate: Coordinate) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                let city = placemarks?.first?.addressDictionary?["City"] as? String
                    ?? placemarks?.first?.addressDictionary?["Municipality"] as? String
                    ?? placemarks?.first?.addressDictionary?["SubAdministrativeArea"] as? String
                continuation.resume(returning: city)
            }
        }
    }
}
