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
        .navigationTitle(Strings.Settings.preferencesTitle)
        #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section(Strings.Settings.appearanceSectionHeader) {
            Picker(Strings.Settings.themeAccessibilityLabel, selection: self.$viewModel.theme) {
                Text(Strings.Settings.themeSystem).tag(0)
                Text(Strings.Settings.themeLight).tag(1)
                Text(Strings.Settings.themeDark).tag(2)
            }
            .accessibilityIdentifier("theme-picker")
            .accessibilityLabel(Strings.Settings.themeAccessibilityLabel)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle(Strings.Settings.morningNudgeToggle, isOn: self.$viewModel.isMorningNudgeEnabled)
                .accessibilityIdentifier("morning-nudge-toggle")
            if self.viewModel.isMorningNudgeEnabled {
                DatePicker(
                    Strings.Settings.morningBriefingTimeLabel,
                    selection: self.$viewModel.morningBriefingTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .accessibilityIdentifier("morning-briefing-time-picker")
            }
            Toggle(Strings.Settings.mealRemindersToggle, isOn: self.$viewModel.areMealRemindersEnabled)
                .accessibilityIdentifier("meal-reminders-toggle")
        } header: {
            Text(Strings.Settings.notificationsSectionHeader)
        } footer: {
            Text(Strings.Settings.notificationsFooter(briefingTime: self.formattedBriefingTime))
                .font(FontTheme.caption)
        }
    }

    private var formattedBriefingTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: self.viewModel.morningBriefingTime)
    }

    // MARK: - Sensory Feedback Section

    private var sensorySection: some View {
        Section(Strings.Settings.sensoryFeedbackSectionHeader) {
            Toggle(Strings.Settings.hapticNudgesToggle, isOn: self.$viewModel.areHapticsEnabled)
                .accessibilityIdentifier("haptics-toggle")
            Toggle(Strings.Settings.soundEffectsToggle, isOn: self.$viewModel.isSoundEnabled)
                .accessibilityIdentifier("sounds-toggle")
        }
    }

    // MARK: - Integrations Section

    private var integrationsSection: some View {
        Section {
            Toggle(Strings.Settings.appleHealthToggle, isOn: self.$viewModel.isHealthSyncEnabled)
                .accessibilityIdentifier("health-sync-toggle")
        } header: {
            Text(Strings.Settings.integrationsSectionHeader)
        } footer: {
            Text(Strings.Settings.appleHealthFooter)
                .font(FontTheme.caption)
        }
    }
}
