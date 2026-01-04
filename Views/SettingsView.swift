import HealthKit
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mainViewModel: MainViewModel
    @StateObject private var viewModel: SettingsViewModel
    @ObservedObject private var authService = AuthService.shared
    @State private var showingClearConfirmation = false

    init(mainViewModel: MainViewModel) {
        self._mainViewModel = EnvironmentObject()
        self._viewModel = StateObject(
            wrappedValue: SettingsViewModel(historicalService: mainViewModel.historicalService)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                self.userDataSection
                self.personalDetailsSection
                self.appearanceSection
                self.notificationsSection
                self.sensorySection
                self.personalizationSection
                if self.viewModel.showHealthInsights {
                    self.healthInsightsSection
                }
                self.privacySection
                self.integrationsSection
                self.dataManagementSection
                self.supportSection
            }
            .navigationTitle("Settings")
            #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar { self.toolbarContent }
                .alert("Clear All Data?", isPresented: self.$showingClearConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) { self.mainViewModel.resetDay() }
                } message: {
                    Text("This will delete all your logged meals and reset the Smiley. Cannot be undone.")
                }
        }
    }

    // MARK: - Sections

    private var userDataSection: some View {
        Section("User Data") {
            if let user = self.authService.currentUser {
                self.signedInUserView(user: user)
                self.syncButton
            } else {
                self.signInButton
            }
            self.heatmapLink
        }
    }

    private func signedInUserView(user: any AuthUser) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.displayName ?? "User")
                    .font(.headline)
                Text(user.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Sign Out") {
                self.authService.signOut()
            }
            .foregroundColor(.red)
        }
    }

    private var syncButton: some View {
        VStack(spacing: 0) {
            Button(action: { self.viewModel.performCloudSync() }) {
                HStack {
                    switch self.viewModel.syncStatus {
                    case .idle:
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                    case .syncing:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .error:
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }

                    Text(self.viewModel.syncStatusText)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(self.syncBackgroundColor)
                .cornerRadius(8)
                .animation(.easeInOut(duration: 0.3), value: self.viewModel.syncStatus)
            }
            .buttonStyle(.borderless)
            .disabled(self.viewModel.syncStatus == .syncing)
            .accessibilityLabel(self.viewModel.syncAccessibilityLabel)
            .accessibilityHint(self.viewModel.syncAccessibilityHint)
            .padding(.horizontal, 16)

            Divider()
                .background(Color.secondary.opacity(0.3))
                .padding(.top, 8)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
    }

    private var syncBackgroundColor: Color {
        switch self.viewModel.syncStatus {
        case .idle: Color.blue.opacity(0.1)
        case .syncing: Color.blue.opacity(0.2)
        case .success: Color.green.opacity(0.15)
        case .error: Color.red.opacity(0.1)
        }
    }

    private var signInButton: some View {
        Button(action: {
            Task { try? await self.authService.signInWithGoogle() }
        }) {
            HStack {
                Image(systemName: "person.crop.circle.badge.plus")
                Text("Login with Google")
            }
        }
    }

    private var heatmapLink: some View {
        NavigationLink {
            YearlyCalendarView(
                viewModel: YearlyCalendarViewModel(historicalService: self.mainViewModel.historicalService)
            )
        } label: {
            Label("Yearly Heatmap", systemImage: "calendar.badge.clock")
        }
        .accessibilityIdentifier("yearly-heatmap-link")
    }

    private var personalDetailsSection: some View {
        Section("Personal Details") {
            self.nameRow
            self.genderPicker
            self.ageRow
            self.unitPicker
            self.heightRow
            self.weightRow
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

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Morning Nudge", isOn: self.$viewModel.isMorningNudgeEnabled)
                .accessibilityIdentifier("morning-nudge-toggle")
            Toggle("Meal Reminders", isOn: self.$viewModel.areMealRemindersEnabled)
                .accessibilityIdentifier("meal-reminders-toggle")
        }
    }

    private var sensorySection: some View {
        Section("Sensory Feedback") {
            Toggle("Haptic Nudges", isOn: self.$viewModel.areHapticsEnabled)
                .accessibilityIdentifier("haptics-toggle")
            Toggle("Sound Effects", isOn: self.$viewModel.isSoundEnabled)
                .accessibilityIdentifier("sounds-toggle")
        }
    }

    private var personalizationSection: some View {
        Section {
            Toggle("Personalized Feedback", isOn: self.$viewModel.isPersonalizedFeedbackEnabled)
                .tint(.green)
                .accessibilityIdentifier("personalized-feedback-toggle")
        } header: {
            Text("Personalization")
        } footer: {
            Text(
                "Get meal feedback tailored to your health profile. More sensitive warnings for users with higher BMI or health risks."
            )
            .font(.caption)
        }
    }

    private var healthInsightsSection: some View {
        Section("Health Insights") {
            if let profile = self.mainViewModel.healthProfileService.getUserHealthProfile() {
                LabeledContent("BMI", value: String(format: "%.1f", profile.bmi))
                LabeledContent("Category", value: profile.bmiCategory.rawValue)
                LabeledContent("Daily Energy", value: "\(Int(profile.tdee)) cal")
                LabeledContent("Risk Level", value: profile.riskLevel.rawValue)
            } else {
                Text("Complete your personal details to see health insights")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var privacySection: some View {
        Section {
            Toggle("Show Health Insights", isOn: self.$viewModel.showHealthInsights)
                .tint(.green)
                .accessibilityIdentifier("show-health-insights-toggle")
        } header: {
            Text("Privacy")
        } footer: {
            Text(
                "All health calculations are done on your device. Data never leaves your phone except for encrypted cloud sync."
            )
            .font(.caption)
        }
    }

    private var integrationsSection: some View {
        Section("Integrations") {
            Toggle("Sync Body Metrics (Apple Health)", isOn: self.$viewModel.isHealthSyncEnabled)
                .accessibilityIdentifier("health-sync-toggle")
        }
    }

    private var dataManagementSection: some View {
        Section("Data Management") {
            Button(role: .destructive) {
                self.showingClearConfirmation = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
        }
    }

    private var supportSection: some View {
        Section {
            NavigationLink("FAQ & Help") { FAQView() }
            Link(destination: self.privacyURL) {
                Label("Privacy Policy", systemImage: "lock.shield")
            }
            Link(destination: self.termsURL) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            Button { /* Rate app */ } label: {
                Label("Rate Yoga of Eating", systemImage: "star")
            }
        } header: {
            Text("Support & Legal")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Yoga of Eating v\(self.appVersion) (\(self.appBuild))")
                Text("© 2025 Sunil")
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if canImport(UIKit)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { self.dismiss() }
            }
        #elseif canImport(AppKit)
            ToolbarItem(placement: .automatic) {
                Button("Done") { self.dismiss() }
            }
        #endif
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var privacyURL: URL {
        URL(string: "https://example.com/privacy") ?? URL(fileURLWithPath: "")
    }

    private var termsURL: URL {
        URL(string: "https://example.com/terms") ?? URL(fileURLWithPath: "")
    }
}
