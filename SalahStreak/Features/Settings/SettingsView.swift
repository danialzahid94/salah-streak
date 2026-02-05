import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]

    private var settings: UserSettings? { allSettings.first }

    @State private var showCalculationPicker   = false
    @State private var showMadhabPicker        = false
    @State private var notificationToggleIsOn  = false

    var body: some View {
        NavigationStack {
            List {
                Section("Prayer Times") {
                    settingRow(title: "Calculation Method", value: settings?.calculationMethod.displayName ?? "—") {
                        showCalculationPicker = true
                    }
                    settingRow(title: "Madhab", value: settings?.madhab.displayName ?? "—") {
                        showMadhabPicker = true
                    }
                }

                Section("Location") {
                    HStack {
                        Text("City")
                        Spacer()
                        Text(settings?.cityName ?? "Not set")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Coordinates")
                        Spacer()
                        if let lat = settings?.latitude, let lng = settings?.longitude {
                            Text("\(String(format: "%.4f", lat)), \(String(format: "%.4f", lng))")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 13))
                        } else {
                            Text("Not set").foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notifications") {
                    Toggle("Enabled", isOn: $notificationToggleIsOn)
                        .onChange(of: notificationToggleIsOn) { _, newValue in
                            if newValue {
                                Task { await self.handleEnableNotifications() }
                            } else {
                                settings?.notificationsEnabled = false
                                try? modelContext.save()
                            }
                        }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCalculationPicker) {
                CalculationMethodPickerView(current: settings?.calculationMethod ?? .muslimWorldLeague) { method in
                    settings?.calculationMethod = method
                    try? modelContext.save()
                }
            }
            .sheet(isPresented: $showMadhabPicker) {
                MadhabPickerView(current: settings?.madhab ?? .shafi) { madhab in
                    settings?.madhab = madhab
                    try? modelContext.save()
                }
            }
        }
        .onAppear { Task { await loadNotificationToggleState() } }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await self.loadNotificationToggleState() }
        }
    }

    // MARK: - Notification Helpers

    @MainActor
    private func loadNotificationToggleState() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        notificationToggleIsOn = (settings?.notificationsEnabled == true) && (status.authorizationStatus == .authorized)
    }

    @MainActor
    private func handleEnableNotifications() async {
        let current = await UNUserNotificationCenter.current().notificationSettings()
        switch current.authorizationStatus {
        case .notDetermined:
            let granted = await DependencyContainer.shared.notificationService.requestAuthorization()
            if granted {
                settings?.notificationsEnabled = true
                try? modelContext.save()
            } else {
                notificationToggleIsOn = false
            }
        case .denied:
            notificationToggleIsOn = false
            _ = await UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        case .authorized, .provisional, .ephemeral:
            settings?.notificationsEnabled = true
            try? modelContext.save()
        @unknown default:
            notificationToggleIsOn = false
        }
    }

    private func settingRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .contentShape(.rect)
        .onTapGesture(perform: action)
    }
}

// MARK: - Calculation Method Picker

private struct CalculationMethodPickerView: View {
    let current: CalculationMethodType
    let onSelect: (CalculationMethodType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(CalculationMethodType.allCases) { method in
                    HStack {
                        Text(method.displayName)
                        Spacer()
                        if method == current {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        onSelect(method)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Calculation Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - Madhab Picker

private struct MadhabPickerView: View {
    let current: MadhabType
    let onSelect: (MadhabType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(MadhabType.allCases) { madhab in
                    HStack {
                        Text(madhab.displayName)
                        Spacer()
                        if madhab == current {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        onSelect(madhab)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Madhab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}
