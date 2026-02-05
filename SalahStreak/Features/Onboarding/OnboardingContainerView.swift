import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            OnboardingProgressBar(currentStep: viewModel.currentStep, totalSteps: totalSteps)
                .padding(.top, 12)
                .padding(.horizontal)

            ZStack {
                switch viewModel.currentStep {
                case 0:
                    LocationPermissionView(onNext: { loc in
                        Task {
                            await viewModel.handleLocationPermission(coordinate: loc)
                        }
                    })
                case 1:
                    MadhabSelectionView(onNext: { madhab in
                        viewModel.handleMadhabSelection(madhab)
                    })
                default:
                    GoalSelectionView(onFinish: { notificationsEnabled in
                        Task {
                            await viewModel.finishOnboarding()
                        }
                    })
                }
            }
            .frame(maxHeight: .infinity)
        }
        .onAppear {
            viewModel.onAppear(context: modelContext)
        }
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
