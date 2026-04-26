import Foundation
#if canImport(UIKit)
    import UIKit
#endif

extension SettingsViewModel {
    func performCloudSync() {
        self.syncTask?.cancel()
        self.syncTask = Task {
            await self.performSyncWithRetry()
        }
    }

    func cancelCloudSync() {
        self.syncTask?.cancel()
        if self.syncStatus == .syncing {
            self.syncStatus = .idle
        }
    }

    func performSyncWithRetry(attempt: Int = 1) async {
        guard self.isNetworkAvailable else {
            await self.handleSyncError(
                NSError(
                    domain: "SyncError",
                    code: -1009,
                    userInfo: [
                        NSLocalizedDescriptionKey: "No internet connection. Please check your network and try again."
                    ]
                ),
                shouldRetry: false
            )
            return
        }

        self.syncStatus = .syncing

        do {
            try await self.historicalService.syncToFirebase()
            if !Task.isCancelled {
                await self.handleSyncSuccess()
            }
        } catch {
            if !Task.isCancelled {
                let shouldRetry = attempt < self.SYNC_MAX_RETRY_ATTEMPTS
                await self.handleSyncError(error, shouldRetry: shouldRetry, attempt: attempt)
            }
        }
    }

    func handleSyncSuccess() async {
        self.syncStatus = .success

        #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        try? await Task.sleep(nanoseconds: self.SYNC_SUCCESS_DISPLAY_DURATION)

        if !Task.isCancelled {
            self.syncStatus = .idle
        }
    }

    func handleSyncError(_ error: Error, shouldRetry: Bool, attempt: Int = 1) async {
        if shouldRetry {
            self.syncStatus = .error("Sync failed. Retrying... (Attempt \(attempt)/\(self.SYNC_MAX_RETRY_ATTEMPTS))")
            try? await Task.sleep(nanoseconds: self.SYNC_RETRY_DELAY)
            if !Task.isCancelled {
                await self.performSyncWithRetry(attempt: attempt + 1)
            }
        } else {
            self.syncStatus = .error(error.localizedDescription)

            #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif

            try? await Task.sleep(nanoseconds: self.SYNC_ERROR_DISPLAY_DURATION)

            if !Task.isCancelled {
                self.syncStatus = .idle
            }
        }
    }

    func handleMorningNudgeChange(_ enabled: Bool) {
        if enabled {
            NotificationManager.shared.scheduleMorningNudge()
        } else {
            NotificationManager.shared.cancelMorningNudge()
        }
    }

    // MARK: - Sync Status Helpers

    var syncStatusText: String {
        switch self.syncStatus {
        case .idle: "Sync with Cloud"
        case .syncing: "Syncing..."
        case .success: "Synced!"
        case .error: "Sync Failed"
        }
    }

    var syncAccessibilityLabel: String {
        switch self.syncStatus {
        case .idle: "Sync with Cloud button"
        case .syncing: "Syncing data to cloud"
        case .success: "Sync completed successfully"
        case let .error(message): "Sync failed: \(message)"
        }
    }

    var syncAccessibilityHint: String {
        switch self.syncStatus {
        case .idle: "Double tap to sync your data with cloud storage"
        case .syncing: "Sync in progress, please wait"
        case .success: "Sync completed"
        case .error: "Double tap to retry sync"
        }
    }
}
