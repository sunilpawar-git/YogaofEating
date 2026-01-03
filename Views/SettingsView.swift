import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MainViewModel

    @AppStorage("user_name") private var name: String = "Sunil"
    @AppStorage("user_height") private var height: String = "175"
    @AppStorage("user_weight") private var weight: String = "75"
    @AppStorage("user_gender") private var gender: Int = 0
    @AppStorage("user_age") private var age: String = "30"
    @AppStorage("app_theme") private var theme: Int = 0
    @AppStorage("unit_system") private var unitSystem: Int = 0
    @AppStorage("smart_smiley_enabled") private var isSmartSmileyEnabled: Bool = true
    @AppStorage("morning_nudge_enabled") private var isMorningNudgeEnabled: Bool = true
    @AppStorage("meal_reminders_enabled") private var areMealRemindersEnabled: Bool = true
    @AppStorage("haptics_enabled") private var areHapticsEnabled: Bool = true
    @AppStorage("sound_enabled") private var isSoundEnabled: Bool = true
    @AppStorage("health_sync_enabled") private var isHealthSyncEnabled: Bool = false

    @ObservedObject private var authService = AuthService.shared
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                self.userDataSection
                self.personalDetailsSection
                self.appearanceSection
                self.notificationsSection
                self.sensorySection
                self.integrationsSection
                self.aiSection
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
                    Button("Clear", role: .destructive) { self.viewModel.resetDay() }
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
        Button(action: { self.performSync() }) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Sync with Cloud")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.borderless)
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
            YearlyCalendarView(viewModel: YearlyCalendarViewModel(historicalService: self.viewModel.historicalService))
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
            TextField("Name", text: self.$name)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private var genderPicker: some View {
        Picker("Gender", selection: self.$gender) {
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
            TextField("Age", text: self.$age)
            #if canImport(UIKit)
                .keyboardType(.numberPad)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private var unitPicker: some View {
        Picker("Unit System", selection: self.$unitSystem) {
            Text("Metric").tag(0)
            Text("Imperial").tag(1)
        }
    }

    private var heightRow: some View {
        HStack {
            Text(self.unitSystem == 0 ? "Height (cm)" : "Height (ft/in)")
            Spacer()
            TextField("Height", text: self.$height)
            #if canImport(UIKit)
                .keyboardType(.numbersAndPunctuation)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private var weightRow: some View {
        HStack {
            Text(self.unitSystem == 0 ? "Weight (kg)" : "Weight (lbs)")
            Spacer()
            TextField("Weight", text: self.$weight)
            #if canImport(UIKit)
                .keyboardType(.decimalPad)
            #endif
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: self.$theme) {
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
            Toggle("Morning Nudge", isOn: self.$isMorningNudgeEnabled)
                .accessibilityIdentifier("morning-nudge-toggle")
                .onChange(of: self.isMorningNudgeEnabled) { _, enabled in
                    self.handleMorningNudgeChange(enabled)
                }
            Toggle("Meal Reminders", isOn: self.$areMealRemindersEnabled)
                .accessibilityIdentifier("meal-reminders-toggle")
        }
    }

    private var sensorySection: some View {
        Section("Sensory Feedback") {
            Toggle("Haptic Nudges", isOn: self.$areHapticsEnabled)
                .accessibilityIdentifier("haptics-toggle")
            Toggle("Sound Effects", isOn: self.$isSoundEnabled)
                .accessibilityIdentifier("sounds-toggle")
        }
    }

    private var integrationsSection: some View {
        Section("Integrations") {
            Toggle("Apple Health (HealthKit)", isOn: self.$isHealthSyncEnabled)
        }
    }

    private var aiSection: some View {
        Section("AI & Logic") {
            Toggle("Smart Smiley (AI Influence)", isOn: self.$isSmartSmileyEnabled)
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

    // MARK: - Actions

    private func performSync() {
        Task {
            do {
                try await self.viewModel.historicalService.syncToFirebase()
            } catch {
                print("❌ Cloud sync failed: \(error)")
            }
        }
    }

    private func handleMorningNudgeChange(_ enabled: Bool) {
        if enabled {
            NotificationManager.shared.scheduleMorningNudge()
        } else {
            NotificationManager.shared.cancelAllNotifications()
        }
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
