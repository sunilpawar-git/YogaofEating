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
                    Button("Clear", role: .destructive) { self.mainViewModel.resetDay() }
                } message: {
                    Text("This will delete all your logged meals and reset the Smiley. Cannot be undone.")
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
