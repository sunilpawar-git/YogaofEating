import HealthKit
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
struct SettingsView: View {
    @Environment(\.dismiss)
    var dismiss
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
                self.navigationSection
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
                    Button("Clear", role: .destructive) { self.mainViewModel.deleteAllData() }
                } message: {
                    Text(
                        "This will permanently delete all logged meals, history, and user settings."
                            + " This action cannot be undone."
                    )
                }
        }
    }

    // MARK: - Navigation Section

    private var navigationSection: some View {
        Section {
            NavigationLink {
                UserProfileSettingsView(viewModel: self.viewModel)
                    .environmentObject(self.mainViewModel)
            } label: {
                Label("Profile & Health", systemImage: "person.crop.circle")
            }
            .accessibilityIdentifier("profile-settings-link")

            NavigationLink {
                PreferencesSettingsView(viewModel: self.viewModel)
            } label: {
                Label("Preferences", systemImage: "gearshape")
            }
            .accessibilityIdentifier("preferences-settings-link")
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
            Button(action: { self.viewModel.performCloudSync() }, label: {
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
            })
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
        }, label: {
            HStack {
                Image(systemName: "person.crop.circle.badge.plus")
                Text("Login with Google")
            }
        })
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

    // MARK: - Sections moved to sub-views

    // personalDetailsSection, healthInsightsSection, privacySection -> UserProfileSettingsView
    // appearanceSection, notificationsSection, sensorySection, integrationsSection -> PreferencesSettingsView

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
            NavigationLink {
                FAQView()
            } label: {
                Label("FAQ & Help", systemImage: "questionmark.circle")
            }
            NavigationLink {
                LegalDocumentView(title: "Privacy Policy", textContent: self.privacyPolicyText)
            } label: {
                Label("Privacy Policy", systemImage: "lock.shield")
            }
            NavigationLink {
                LegalDocumentView(title: "Terms of Service", textContent: self.termsOfServiceText)
            } label: {
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

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
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

    private var privacyPolicyText: String {
        """
        Privacy Policy

        Last Updated: January 2026

        1. Overview
        Yoga of Eating respects your privacy. We prioritize local data storage and transparency.

        2. Data Collection
        - Personal Data: We collect your name and email only if you choose to sign in.
        - Health Data: We sync with HealthKit only with your explicit permission.
        - Usage Data: Basic app usage metrics may be collected anonymously.

        3. AI & Analysis
        - Your meal entries are processed effectively by Google Gemini AI to provide nutritional insights.
        - We do not use your personal data to train public AI models.

        4. Cloud Sync
        - If you enable Cloud Sync, your data is encrypted and stored on Google Firebase.
        - You can delete your account and data at any time.

        5. Contact
        For any questions, please check the FAQ or contact support.
        """
    }

    private var termsOfServiceText: String {
        """
        Terms of Service

        Last Updated: January 2026

        1. Acceptance
        By using Yoga of Eating, you agree to these terms.

        2. Usage
        - You agree to use the app for personal, non-commercial purposes.
        - You will not use the app for any illegal activities.

        3. Medical Disclaimer
        - This app is NOT a medical device.
        - The AI insights are for informational purposes only.
        - Consult a healthcare professional for medical advice.

        4. Termination
        We reserve the right to terminate accounts that violate these terms.

        5. Changes
        We may update these terms from time to time. Continued use implies acceptance.
        """
    }
}
