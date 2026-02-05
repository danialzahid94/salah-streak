import SwiftUI

struct LocationPermissionView: View {
    let onNext: (Coordinate?) -> Void

    @State private var isLoading = false
    @State private var errorMessage: String?

    private let locationService = DependencyContainer.shared.locationService

    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            Spacer()

            Image(systemName: "location.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)

            Text("Set Your Location")
                .font(.system(size: 28, weight: .bold))

            Text("We need your location to calculate accurate prayer times for your area.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.stateMissed)
            }

            VStack(spacing: 12) {
                Button("Allow Location") {
                    requestLocation()
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.vertical, 14)
                .frame(width: 260)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isLoading)

                Button("Enter City Manually") {
                    onNext(nil)
                }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    private func requestLocation() {
        isLoading = true
        Task {
            do {
                let coord = try await locationService.requestLocation()
                onNext(coord)
            } catch {
                errorMessage = "Location access denied. Please enable it in Settings."
            }
            isLoading = false
        }
    }
}
