import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Prayer Times") {
                    settingRow(title: "Calculation Method", value: viewModel.calculationMethod.displayName) {
                        viewModel.toggleCalculationPicker()
                    }
                    settingRow(title: "Madhab", value: viewModel.madhab.displayName) {
                        viewModel.toggleMadhabPicker()
                    }
                }

                Section("Location") {
                    HStack {
                        Text("City")
                        Spacer()
                        Text(viewModel.cityName)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Coordinates")
                        Spacer()
                        Text(viewModel.coordinates)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 13))
                    }
                }

                Section("Notifications") {
                    Toggle("Enabled", isOn: Binding(
                        get: { viewModel.notificationsEnabled },
                        set: { newValue in
                            Task {
                                await viewModel.toggleNotifications(newValue)
                            }
                        }
                    ))
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion).foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showCalculationPicker) {
                CalculationMethodPickerView(
                    current: viewModel.calculationMethod,
                    onSelect: { method in
                        viewModel.selectCalculationMethod(method)
                    }
                )
            }
            .sheet(isPresented: $viewModel.showMadhabPicker) {
                MadhabPickerView(
                    current: viewModel.madhab,
                    onSelect: { madhab in
                        viewModel.selectMadhab(madhab)
                    }
                )
            }
        }
        .onAppear {
            viewModel.onAppear(context: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.onBecomeActive()
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
