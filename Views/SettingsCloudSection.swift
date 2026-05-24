import SwiftUI

/// The cloud-sync and restore buttons shown in Settings when a user is signed in.
///
/// Extracted from `SettingsView` to:
/// - Keep `SettingsView.swift` under the 300-line limit
/// - Collocate sync and restore UI in one coherent component
///
/// Uses standard Form/List row buttons (no custom background or corner radius).
/// The row itself is the interactive element — the List handles background,
/// separators, and tap highlights natively.
struct SettingsCloudSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Group {
            self.syncButton
            self.restoreButton
        }
    }

    // MARK: - Sync Button

    private var syncButton: some View {
        Button(action: { self.viewModel.performCloudSync() }) {
            Label {
                Text(self.viewModel.syncStatusText)
            } icon: {
                self.syncStatusIcon
            }
        }
        .disabled(self.viewModel.syncStatus == .syncing)
        .animation(.easeInOut(duration: 0.3), value: self.viewModel.syncStatus)
        .accessibilityLabel(self.viewModel.syncAccessibilityLabel)
        .accessibilityHint(self.viewModel.syncAccessibilityHint)
    }

    @ViewBuilder
    private var syncStatusIcon: some View {
        switch self.viewModel.syncStatus {
        case .idle:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(AppTheme.CloudSync.syncButtonColor)
        case .syncing:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(AppTheme.CloudSync.progressViewScale)
                .tint(AppTheme.CloudSync.syncButtonColor)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.CloudSync.successColor)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.CloudSync.errorColor)
        }
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button(action: { self.viewModel.performCloudRestore() }) {
            Label {
                Text(self.viewModel.restoreStatusText)
            } icon: {
                self.restoreStatusIcon
            }
        }
        .disabled(self.viewModel.restoreStatus == .restoring)
        .animation(.easeInOut(duration: 0.3), value: self.viewModel.restoreStatus)
        .accessibilityLabel(self.viewModel.restoreAccessibilityLabel)
        .accessibilityHint(self.viewModel.restoreAccessibilityHint)
    }

    @ViewBuilder
    private var restoreStatusIcon: some View {
        switch self.viewModel.restoreStatus {
        case .idle:
            Image(systemName: "icloud.and.arrow.down")
                .foregroundStyle(AppTheme.CloudSync.syncButtonColor)
        case .restoring:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(AppTheme.CloudSync.progressViewScale)
                .tint(AppTheme.CloudSync.syncButtonColor)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.CloudSync.successColor)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.CloudSync.errorColor)
        }
    }
}
