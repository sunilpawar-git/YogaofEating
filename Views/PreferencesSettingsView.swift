import SwiftUI

/// Sub-view for app preferences containing Appearance, Notifications, Sensory Feedback, and Integrations.
/// This consolidates all app behavior settings in one place.
struct PreferencesSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            self.appearanceSection
            self.notificationsSection
            self.sensorySection
            self.integrationsSection
        }
        .navigationTitle("Preferences")
        #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: self.$viewModel.theme) {
                Text("System").tag(0)
                Text("Light").tag(1)
                Text("Dark").tag(2)
            }
            .accessibilityIdentifier("theme-picker")
            .accessibilityLabel("Theme")
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle("Morning Nudge", isOn: self.$viewModel.isMorningNudgeEnabled)
                .accessibilityIdentifier("morning-nudge-toggle")
            Toggle("Meal Reminders", isOn: self.$viewModel.areMealRemindersEnabled)
                .accessibilityIdentifier("meal-reminders-toggle")
        } header: {
            Text("Notifications")
        } footer: {
            Text("Morning nudge at 8am, meal reminders at 8am, 1pm, and 8pm.")
                .font(.caption)
        }
    }

    // MARK: - Sensory Feedback Section

    private var sensorySection: some View {
        Section("Sensory Feedback") {
            Toggle("Haptic Nudges", isOn: self.$viewModel.areHapticsEnabled)
                .accessibilityIdentifier("haptics-toggle")
            Toggle("Sound Effects", isOn: self.$viewModel.isSoundEnabled)
                .accessibilityIdentifier("sounds-toggle")
        }
    }

    // MARK: - Integrations Section

    private var integrationsSection: some View {
        Section {
            Toggle("Sync Body Metrics (Apple Health)", isOn: self.$viewModel.isHealthSyncEnabled)
                .accessibilityIdentifier("health-sync-toggle")
        } header: {
            Text("Integrations")
        } footer: {
            Text("When enabled, your height, weight, age, and gender will be synced from Apple Health.")
                .font(.caption)
        }
    }
}
