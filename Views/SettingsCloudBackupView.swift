import SwiftUI

/// Full-page Cloud Backup sub-screen for Settings.
///
/// Reuses `SettingsCloudSection` for the sync/restore controls and adds
/// a human-readable description so users understand what the backup covers.
struct SettingsCloudBackupView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            self.descriptionSection
            self.actionsSection
        }
        .navigationTitle(Strings.Settings.cloudBackupTitle)
        #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Sections

    private var descriptionSection: some View {
        Section {
            Text(Strings.Settings.cloudBackupDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var actionsSection: some View {
        Section {
            SettingsCloudSection(viewModel: self.viewModel)
        }
    }
}
