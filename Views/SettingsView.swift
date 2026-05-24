import StoreKit
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mainViewModel: MainViewModel
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingClearConfirmation = false
    @State private var showingSignOutConfirmation = false

    init(mainViewModel: MainViewModel) {
        self._mainViewModel = EnvironmentObject()
        self._viewModel = StateObject(
            wrappedValue: SettingsViewModel(historicalService: mainViewModel.historicalService)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                self.accountSection
                self.navigationLinksSection
                self.historySection
                self.supportSection
                self.dangerZoneSection
            }
            .navigationTitle(Strings.Settings.navigationTitle)
            #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar { self.toolbarContent }
                .alert(
                    Strings.Settings.clearAllDataAlertTitle,
                    isPresented: self.$showingClearConfirmation
                ) {
                    Button(Strings.Common.cancel, role: .cancel) {}
                    Button(Strings.Settings.clearAllDataDestructiveButton, role: .destructive) {
                        self.mainViewModel.deleteAllData()
                    }
                } message: {
                    Text(Strings.Settings.clearAllDataAlertMessage)
                }
                .alert(
                    Strings.Settings.signOutAlertTitle,
                    isPresented: self.$showingSignOutConfirmation
                ) {
                    Button(Strings.Common.cancel, role: .cancel) {}
                    Button(Strings.Settings.signOutTitle, role: .destructive) {
                        self.viewModel.signOut()
                    }
                } message: {
                    Text(Strings.Settings.signOutConfirmationMessage)
                }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section(Strings.Settings.accountHeader) {
            if let user = self.viewModel.currentUser {
                self.signedInUserView(user: user)
                NavigationLink {
                    SettingsCloudBackupView(viewModel: self.viewModel)
                } label: {
                    Label(Strings.Settings.cloudBackupTitle, systemImage: "icloud")
                }
                .accessibilityIdentifier("cloud-backup-link")
            } else {
                self.signInButton
            }
        }
    }

    private func signedInUserView(user: any AuthUser) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.displayName ?? "User")
                    .font(FontTheme.displayName)
                Text(user.email ?? "")
                    .font(FontTheme.displaySubtitle)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var signInButton: some View {
        Button(action: {
            Task { await self.viewModel.signInWithGoogle() }
        }) {
            HStack {
                Image(systemName: "person.crop.circle.badge.plus")
                Text(Strings.Settings.loginWithGoogleTitle)
            }
        }
    }

    // MARK: - Navigation Links Section

    private var navigationLinksSection: some View {
        Section {
            NavigationLink {
                UserProfileSettingsView(viewModel: self.viewModel)
                    .environmentObject(self.mainViewModel)
            } label: {
                Label(Strings.Settings.profileHealthTitle, systemImage: "person.crop.circle")
            }
            .accessibilityIdentifier("profile-settings-link")

            NavigationLink {
                PreferencesSettingsView(viewModel: self.viewModel)
            } label: {
                Label(Strings.Settings.preferencesTitle, systemImage: "gearshape")
            }
            .accessibilityIdentifier("preferences-settings-link")

            Button {
                #if canImport(UIKit)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                #endif
            } label: {
                Label(Strings.Settings.manageHealthAccessTitle, systemImage: "heart.text.square")
            }
            .accessibilityIdentifier("manage-health-access-link")
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        Section(Strings.Settings.historyHeader) {
            NavigationLink {
                YearlyCalendarView(
                    viewModel: YearlyCalendarViewModel(
                        historicalService: self.mainViewModel.historicalService
                    )
                )
            } label: {
                Label(Strings.Settings.yearlyHeatmapTitle, systemImage: "calendar.badge.clock")
            }
            .accessibilityIdentifier("yearly-heatmap-link")
        }
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        Section(Strings.Settings.dangerZoneHeader) {
            if self.viewModel.currentUser != nil {
                Button(role: .destructive) {
                    self.showingSignOutConfirmation = true
                } label: {
                    Label(
                        Strings.Settings.signOutTitle,
                        systemImage: "rectangle.portrait.and.arrow.right"
                    )
                }
                .accessibilityIdentifier("sign-out-button")
            }
            Button(role: .destructive) {
                self.showingClearConfirmation = true
            } label: {
                Label(Strings.Settings.clearAllDataTitle, systemImage: "trash")
            }
            .accessibilityIdentifier("clear-all-data-button")
        }
    }

    // MARK: - Support & Legal Section

    private var supportSection: some View {
        Section {
            NavigationLink {
                FAQView()
            } label: {
                Label(Strings.Settings.faqTitle, systemImage: "questionmark.circle")
            }
            NavigationLink {
                LegalDocumentView(
                    title: Strings.Settings.privacyPolicyTitle,
                    textContent: Strings.Settings.privacyPolicyText
                )
            } label: {
                Label(Strings.Settings.privacyPolicyTitle, systemImage: "lock.shield")
            }
            NavigationLink {
                LegalDocumentView(
                    title: Strings.Settings.termsTitle,
                    textContent: Strings.Settings.termsOfServiceText
                )
            } label: {
                Label(Strings.Settings.termsTitle, systemImage: "doc.text")
            }
            Button {
                #if canImport(UIKit)
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                    {
                        AppStore.requestReview(in: scene)
                    }
                #endif
            } label: {
                Label(Strings.Settings.rateTitle, systemImage: "star")
            }
        } header: {
            Text(Strings.Settings.supportHeader)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Settings.versionFooter(version: self.appVersion, build: self.appBuild))
                Text(Strings.Settings.copyrightFooter(
                    year: Calendar.current.component(.year, from: Date())
                ))
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if canImport(UIKit)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Strings.Settings.doneButton) { self.dismiss() }
            }
        #elseif canImport(AppKit)
            ToolbarItem(placement: .automatic) {
                Button(Strings.Settings.doneButton) { self.dismiss() }
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
}
