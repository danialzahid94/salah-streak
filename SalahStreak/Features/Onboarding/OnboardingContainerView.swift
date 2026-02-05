import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var location: Coordinate?

    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                .padding(.top, 12)
                .padding(.horizontal)

            ZStack {
                switch currentStep {
                case 0:
                    LocationPermissionView(onNext: { loc in
                        self.location = loc
                        currentStep = 1
                    })
                case 1:
                    MadhabSelectionView(onNext: { _ in currentStep = 2 })
                default:
                    GoalSelectionView(onFinish: { notificationsEnabled in
                        Task {
                            await self.finishOnboarding(notificationsEnabled: notificationsEnabled)
                        }
                    })
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    @MainActor
    private func finishOnboarding(notificationsEnabled: Bool) async {
        let statsRepo    = UserStatsRepository(context: modelContext)
        let stats        = try? statsRepo.fetchOrCreate()
        stats?.hasCompletedOnboarding = true

        let settings     = try? statsRepo.fetchOrCreateSettings()
        settings?.notificationsEnabled = notificationsEnabled

        if notificationsEnabled {
            _ = await DependencyContainer.shared.notificationService.requestAuthorization()
        }

        if let loc = location {
            settings?.latitude  = loc.latitude
            settings?.longitude = loc.longitude
            let cityName = await DependencyContainer.shared.locationService.getCityName(for: loc)
            settings?.cityName = cityName
        }

        try? modelContext.save()
    }
}

// MARK: - Progress Bar

private struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? Color.accentColor : Color(.systemGray4))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
