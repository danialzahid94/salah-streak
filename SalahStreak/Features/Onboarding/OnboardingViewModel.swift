import Foundation
import SwiftUI
import SwiftData
import Combine

@Observable
final class OnboardingViewModel {
    // MARK: - Published State
    var currentStep: Int = 0
    var location: Coordinate?
    var selectedMadhab: MadhabType = .hanafi
    var selectedCalculationMethod: CalculationMethodType = .northAmerica
    var notificationsEnabled: Bool = false
    
    // MARK: - Private
    private var modelContext: ModelContext?
    private let totalSteps = 3
    private let locationService = DependencyContainer.shared.locationService
    private let notificationService = DependencyContainer.shared.notificationService
    
    // MARK: - Lifecycle
    
    func onAppear(context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }
    
    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }
    
    func moveToStep(_ step: Int) {
        guard step >= 0 && step < totalSteps else { return }
        currentStep = step
    }
    
    // MARK: - Actions
    
    func handleLocationPermission(coordinate: Coordinate?) async {
        self.location = coordinate
        nextStep()
    }
    
    func handleMadhabSelection(_ madhab: MadhabType) {
        self.selectedMadhab = madhab
        nextStep()
    }
    
    func handleGoalSelection(calculationMethod: CalculationMethodType, enableNotifications: Bool) {
        self.selectedCalculationMethod = calculationMethod
        self.notificationsEnabled = enableNotifications
    }
    
    @MainActor
    func finishOnboarding() async {
        guard let context = modelContext else { return }
        
        let statsRepo = UserStatsRepository(context: context)
        let stats = try? statsRepo.fetchOrCreate()
        stats?.hasCompletedOnboarding = true
        
        let settings = try? statsRepo.fetchOrCreateSettings()
        settings?.madhab = selectedMadhab
        settings?.calculationMethod = selectedCalculationMethod
        settings?.notificationsEnabled = notificationsEnabled
        
        if notificationsEnabled {
            _ = await notificationService.requestAuthorization()
        }
        
        if let loc = location {
            settings?.latitude = loc.latitude
            settings?.longitude = loc.longitude
            let cityName = await locationService.getCityName(for: loc)
            settings?.cityName = cityName
        }
        
        try? context.save()
    }
    
    // MARK: - Helpers
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
}
