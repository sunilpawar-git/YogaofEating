import Foundation
import OSLog
#if canImport(UIKit)
    import UIKit
#endif

private let restoreLogger = Logger(subsystem: "com.yogaofeating", category: "Settings.Restore")

/// Cloud restore logic for `SettingsViewModel`.
/// Extracted to keep each extension file under the 250-line warning limit.
extension SettingsViewModel {
    // MARK: - Restore Entry Point

    /// Manually restores data from Firebase.
    ///
    /// Clears the `hasDeletedAllData` flag synchronously before launching the async
    /// Task so that callers can verify the flag state immediately after this call.
    /// This is intentional — the guard is a deliberate opt-out, and the user tapping
    /// "Restore from Cloud" is an explicit opt back in.
    func performCloudRestore() {
        // Clear the deletion flag synchronously — the user's explicit tap is consent to restore.
        self.userDefaults.removeObject(forKey: StorageKeys.hasDeletedAllData)

        self.restoreTask?.cancel()
        self.restoreTask = Task {
            self.restoreStatus = .restoring

            do {
                try await self.historicalService.restoreFromFirebase()
                if !Task.isCancelled {
                    await self.handleRestoreSuccess()
                }
            } catch {
                if !Task.isCancelled {
                    await self.handleRestoreError(error)
                }
            }
        }
    }

    // MARK: - Result Handlers

    func handleRestoreSuccess() async {
        self.restoreStatus = .success
        restoreLogger.info("Manual cloud restore succeeded")

        #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        try? await Task.sleep(nanoseconds: self.syncSuccessDisplayDuration)

        if !Task.isCancelled {
            self.restoreStatus = .idle
        }
    }

    func handleRestoreError(_ error: Error) async {
        // Use the typed AppError description when available (e.g. restorePartialData has a
        // specific "Some data could not be restored" message). Fall back to a generic string.
        let userMessage = (error as? AppError)?.errorDescription
            ?? Strings.Settings.restoreFailedGeneric
        self.restoreStatus = .error(userMessage)
        restoreLogger.error("Manual cloud restore failed: \(error.localizedDescription, privacy: .public)")

        #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif

        try? await Task.sleep(nanoseconds: self.syncErrorDisplayDuration)

        if !Task.isCancelled {
            self.restoreStatus = .idle
        }
    }

    // MARK: - Display Helpers

    var restoreStatusText: String {
        switch self.restoreStatus {
        case .idle: Strings.Settings.restoreButtonIdle
        case .restoring: Strings.Settings.restoreButtonRestoring
        case .success: Strings.Settings.restoreButtonSuccess
        case .error: Strings.Settings.restoreButtonError
        }
    }

    var restoreAccessibilityLabel: String {
        switch self.restoreStatus {
        case .idle: Strings.Settings.restoreAccessibilityLabelIdle
        case .restoring: Strings.Settings.restoreAccessibilityLabelRestoring
        case .success: Strings.Settings.restoreAccessibilityLabelSuccess
        case let .error(message): Strings.Settings.restoreAccessibilityLabelErrorPrefix + message
        }
    }

    var restoreAccessibilityHint: String {
        switch self.restoreStatus {
        case .idle: Strings.Settings.restoreAccessibilityHintIdle
        case .restoring: Strings.Settings.restoreAccessibilityHintRestoring
        case .success: Strings.Settings.restoreAccessibilityHintSuccess
        case .error: Strings.Settings.restoreAccessibilityHintError
        }
    }
}
