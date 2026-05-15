import SwiftUI

/// The cloud-sync and restore buttons shown in Settings when a user is signed in.
///
/// Extracted from `SettingsView` to:
/// - Keep `SettingsView.swift` under the 300-line limit
/// - Collocate sync and restore UI in one coherent component
struct SettingsCloudSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            self.syncButton
            self.restoreButton
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
    }

    // MARK: - Sync Button

    private var syncButton: some View {
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
        .padding(.horizontal, 16)
        .accessibilityLabel(self.viewModel.syncAccessibilityLabel)
        .accessibilityHint(self.viewModel.syncAccessibilityHint)
    }

    private var syncBackgroundColor: Color {
        switch self.viewModel.syncStatus {
        case .idle: AppTheme.CloudSync.idleBackground
        case .syncing: AppTheme.CloudSync.activeBackground
        case .success: AppTheme.CloudSync.successBackground
        case .error: AppTheme.CloudSync.errorBackground
        }
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button(action: { self.viewModel.performCloudRestore() }) {
            HStack {
                switch self.viewModel.restoreStatus {
                case .idle:
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundColor(.blue)
                case .restoring:
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
                Text(self.viewModel.restoreStatusText)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(self.restoreBackgroundColor)
            .cornerRadius(8)
            .animation(.easeInOut(duration: 0.3), value: self.viewModel.restoreStatus)
        }
        .buttonStyle(.borderless)
        .disabled(self.viewModel.restoreStatus == .restoring)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .accessibilityLabel(self.viewModel.restoreAccessibilityLabel)
        .accessibilityHint(self.viewModel.restoreAccessibilityHint)
    }

    private var restoreBackgroundColor: Color {
        switch self.viewModel.restoreStatus {
        case .idle: AppTheme.CloudSync.idleBackground
        case .restoring: AppTheme.CloudSync.activeBackground
        case .success: AppTheme.CloudSync.successBackground
        case .error: AppTheme.CloudSync.errorBackground
        }
    }
}
