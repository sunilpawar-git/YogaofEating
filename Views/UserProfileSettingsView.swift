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
        .navigationTitle("Profile & Health")
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
        } header: {
            Text("Personal Details")
        } footer: {
            Text("This information is used to calculate your health insights and personalize feedback.")
                .font(.caption)
        }
    }

    private var nameRow: some View {
        HStack {
            Text("Name")
            Spacer()
            TextField("Name", text: self.$viewModel.name)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private var genderPicker: some View {
        Picker("Gender", selection: self.$viewModel.gender) {
            Text("Unspecified").tag(0)
            Text("Male").tag(1)
            Text("Female").tag(2)
            Text("Other").tag(3)
        }
    }

    private var ageRow: some View {
        HStack {
            Text("Age")
            Spacer()
            TextField("Age", text: self.$viewModel.age)
            #if canImport(UIKit)
                .keyboardType(.numberPad)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private var unitPicker: some View {
        Picker("Unit System", selection: self.$viewModel.unitSystem) {
            Text("Metric").tag(0)
            Text("Imperial").tag(1)
        }
    }

    private var heightRow: some View {
        HStack {
            Text(self.viewModel.unitSystem == 0 ? "Height (cm)" : "Height (ft/in)")
            Spacer()
            TextField("Height", text: self.$viewModel.height)
            #if canImport(UIKit)
                .keyboardType(.numbersAndPunctuation)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private var weightRow: some View {
        HStack {
            Text(self.viewModel.unitSystem == 0 ? "Weight (kg)" : "Weight (lbs)")
            Spacer()
            TextField("Weight", text: self.$viewModel.weight)
            #if canImport(UIKit)
                .keyboardType(.decimalPad)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Health Insights Section

    private var healthInsightsSection: some View {
        Section("Health Insights") {
            if let profile = self.mainViewModel.healthProfileService.getUserHealthProfile() {
                LabeledContent("BMI", value: String(format: "%.1f", profile.bmi))
                LabeledContent("Category", value: profile.bmiCategory.rawValue)
                LabeledContent("Daily Energy", value: "\(Int(profile.tdee)) cal")
                LabeledContent("Risk Level", value: profile.riskLevel.rawValue)
            } else {
                Text("Complete your personal details above to see health insights")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            Toggle("Show Health Insights", isOn: self.$viewModel.showHealthInsights)
                .tint(.green)
                .accessibilityIdentifier("show-health-insights-toggle")
        } header: {
            Text("Privacy")
        } footer: {
            Text(
                "All health calculations are done on your device."
                    + " Data never leaves your phone except for encrypted cloud sync."
            )
            .font(.caption)
        }
    }
}
