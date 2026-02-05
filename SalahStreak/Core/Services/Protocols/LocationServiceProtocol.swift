import Foundation

protocol LocationServiceProtocol {
    var authorizationStatus: LocationAuthorizationStatus { get }
    func requestLocation() async throws -> Coordinate
}

enum LocationAuthorizationStatus {
    case notDetermined, granted, denied
}

struct Coordinate {
    let latitude: Double
    let longitude: Double
}
