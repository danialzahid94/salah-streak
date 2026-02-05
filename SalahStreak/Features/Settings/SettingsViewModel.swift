import Foundation
import SwiftUI
import SwiftData
import UserNotifications
import Combine

@Observable
final class SettingsViewModel {
    // MARK: - Published State
    var calculationMethod: CalculationMethodType = .muslimWorldLeague
    var madhab: MadhabType = .shafi
    var cityName: String = "Not set"
    var coordinates: String = "Not set"
    var notificationsEnabled: Bool = false
    var appVersion: String = "1.0.0"
    
    var showCalculationPicker: Bool = false
    var showMadhabPicker: Bool = false
    
    // MARK: - Private
    private var modelContext: ModelContext?
    private var settings: UserSettings?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    func onAppear(context: ModelContext) {
        self.modelContext = context
        loadData()
        
        Task {
            await loadNotificationState()
        }
    }
    
    func onBecomeActive() {
        Task {
            await loadNotificationState()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserSettings>()
        self.settings = try? context.fetch(descriptor).first
        
        calculationMethod = settings?.calculationMethod ?? .muslimWorldLeague
        madhab = settings?.madhab ?? .shafi
        cityName = settings?.cityName ?? "Not set"
        
        if let lat = settings?.latitude, let lng = settings?.longitude {
            coordinates = "\(String(format: "%.4f", lat)), \(String(format: "%.4f", lng))"
        } else {
            coordinates = "Not set"
        }
    }
    
    @MainActor
    private func loadNotificationState() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = (settings?.notificationsEnabled == true) && (status.authorizationStatus == .authorized)
    }
    
    // MARK: - Actions
    
    func toggleCalculationPicker() {
        showCalculationPicker.toggle()
    }
    
    func toggleMadhabPicker() {
        showMadhabPicker.toggle()
    }
    
    func selectCalculationMethod(_ method: CalculationMethodType) {
        calculationMethod = method
        settings?.calculationMethod = method
        try? modelContext?.save()
        showCalculationPicker = false
    }
    
    func selectMadhab(_ newMadhab: MadhabType) {
        madhab = newMadhab
        settings?.madhab = newMadhab
        try? modelContext?.save()
        showMadhabPicker = false
    }
    
    @MainActor
    func toggleNotifications(_ enabled: Bool) async {
        if enabled {
            await handleEnableNotifications()
        } else {
            await handleDisableNotifications()
        }
    }
    
    // MARK: - Notification Helpers
    
    @MainActor
    private func handleEnableNotifications() async {
        let current = await UNUserNotificationCenter.current().notificationSettings()
        
        switch current.authorizationStatus {
        case .notDetermined:
            let granted = await DependencyContainer.shared.notificationService.requestAuthorization()
            if granted {
                settings?.notificationsEnabled = true
                try? modelContext?.save()
                notificationsEnabled = true
            } else {
                notificationsEnabled = false
            }
            
        case .denied:
            // Open settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                await UIApplication.shared.open(url)
            }
            notificationsEnabled = false
            
        case .authorized, .provisional, .ephemeral:
            settings?.notificationsEnabled = true
            try? modelContext?.save()
            notificationsEnabled = true
            
        @unknown default:
            notificationsEnabled = false
        }
    }
    
    @MainActor
    private func handleDisableNotifications() async {
        settings?.notificationsEnabled = false
        try? modelContext?.save()
        notificationsEnabled = false
    }
}
