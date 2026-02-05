import Foundation

protocol LocationServiceProtocol {
    var authorizationStatus: LocationAuthorizationStatus { get }
    func requestLocation() async throws -> Coordinate
    func getCityName(for coordinate: Coordinate) async -> String?
}

enum LocationAuthorizationStatus {
    case notDetermined, granted, denied
}

struct Coordinate {
    let latitude: Double
    let longitude: Double
}
