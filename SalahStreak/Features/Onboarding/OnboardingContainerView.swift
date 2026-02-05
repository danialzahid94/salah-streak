import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var location: Coordinate?

    var body: some View {
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
                    finishOnboarding(notificationsEnabled: notificationsEnabled)
                })
            }
        }
        .transition(.opacity)
    }

    private func finishOnboarding(notificationsEnabled: Bool) {
        let statsRepo    = UserStatsRepository(context: modelContext)
        let stats        = try? statsRepo.fetchOrCreate()
        stats?.hasCompletedOnboarding = true

        let settingsRepo = statsRepo
        let settings     = try? settingsRepo.fetchOrCreateSettings()
        settings?.notificationsEnabled = notificationsEnabled

        if let loc = location {
            settings?.latitude  = loc.latitude
            settings?.longitude = loc.longitude
        }

        try? modelContext.save()
    }
}
