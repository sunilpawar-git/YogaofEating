import SwiftUI

/// Sub-view for user profile settings containing Personal Details and Health Insights.
/// This consolidates user data editing and health profile display in one place.
struct UserProfileSettingsView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            self.personalDetailsSection
            if self.viewModel.showHealthInsights {
                self.healthInsightsSection
            }
            self.privacySection
        }
        .navigationTitle(Strings.Settings.profileAndHealthTitle)
        #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Personal Details Section

    private var personalDetailsSection: some View {
        Section {
            self.nameRow
            self.genderPicker
            self.ageRow
            self.unitPicker
            self.heightRow
            self.weightRow
            self.activityLevelPicker
        } header: {
            Text(Strings.Settings.personalDetailsSectionHeader)
        } footer: {
            Text(Strings.Settings.personalDetailsFooter)
                .font(FontTheme.caption)
        }
    }

    private var nameRow: some View {
        HStack {
            Text(Strings.Settings.nameLabel)
            Spacer()
            TextField(Strings.Settings.nameLabel, text: self.$viewModel.name)
                .multilineTextAlignment(.trailing)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var genderPicker: some View {
        Picker(Strings.Settings.genderPickerLabel, selection: self.$viewModel.gender) {
            Text(Strings.Settings.genderUnspecified).tag(0)
            Text(Strings.Settings.genderMale).tag(1)
            Text(Strings.Settings.genderFemale).tag(2)
            Text(Strings.Settings.genderOther).tag(3)
        }
    }

    private var ageRow: some View {
        HStack {
            Text(Strings.Settings.ageLabel)
            Spacer()
            TextField(Strings.Settings.ageLabel, text: self.$viewModel.age)
            #if canImport(UIKit)
                .keyboardType(.numberPad)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var unitPicker: some View {
        Picker(Strings.Settings.unitSystemPickerLabel, selection: self.$viewModel.unitSystem) {
            Text(Strings.Settings.unitMetric).tag(0)
            Text(Strings.Settings.unitImperial).tag(1)
        }
    }

    private var heightRow: some View {
        let label = self.viewModel.unitSystem == 0
            ? Strings.Settings.heightLabelMetric
            : Strings.Settings.heightLabelImperial
        return HStack {
            Text(label)
            Spacer()
            TextField(Strings.Settings.heightPlaceholder, text: self.$viewModel.height)
            #if canImport(UIKit)
                .keyboardType(.numbersAndPunctuation)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var weightRow: some View {
        let label = self.viewModel.unitSystem == 0
            ? Strings.Settings.weightLabelMetric
            : Strings.Settings.weightLabelImperial
        return HStack {
            Text(label)
            Spacer()
            TextField(Strings.Settings.weightPlaceholder, text: self.$viewModel.weight)
            #if canImport(UIKit)
                .keyboardType(.decimalPad)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var activityLevelPicker: some View {
        Picker(Strings.Settings.activityLevelPickerLabel, selection: self.$viewModel.activityLevel) {
            ForEach(ActivityLevel.allCases, id: \.self) { level in
                Text(level.displayName).tag(level)
            }
        }
    }

    // MARK: - Health Insights Section

    private var healthInsightsSection: some View {
        Section(Strings.Settings.healthInsightsSectionHeader) {
            if let profile = self.mainViewModel.healthProfileService.getUserHealthProfile() {
                LabeledContent(Strings.Settings.bmiLabel, value: String(format: "%.1f", profile.bmi))
                LabeledContent(Strings.Settings.bmiCategoryLabel, value: profile.bmiCategory.rawValue)
                LabeledContent(Strings.Settings.dailyEnergyLabel, value: "\(Int(profile.tdee)) cal")
                LabeledContent(Strings.Settings.activityLevelPickerLabel, value: profile.activityLevel.displayName)
                LabeledContent(Strings.Settings.riskLevelLabel, value: profile.riskLevel.rawValue)
            } else {
                Text(Strings.Settings.healthInsightsEmptyState)
                    .font(FontTheme.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            Toggle(Strings.Settings.showHealthInsightsToggle, isOn: self.$viewModel.showHealthInsights)
                .tint(.green)
                .accessibilityIdentifier("show-health-insights-toggle")
        } header: {
            Text(Strings.Settings.privacySectionHeader)
        } footer: {
            Text(Strings.Settings.privacyFooter)
                .font(FontTheme.caption)
        }
    }
}
