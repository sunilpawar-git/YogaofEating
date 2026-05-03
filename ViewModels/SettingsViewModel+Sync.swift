import Foundation
import HealthKit
import OSLog
#if canImport(UIKit)
    import UIKit
#endif

private let syncLogger = Logger(subsystem: "com.yogaofeating", category: "Settings")

/// HealthKit sync, auth actions, and cloud sync for `SettingsViewModel`.
/// Extracted to keep `SettingsViewModel.swift` under the 250-line limit.
extension SettingsViewModel {
    // MARK: - HealthKit Sync

    func syncWithHealthKit() {
        // Untracked fire-and-forget: triggered by toggle, single run, no cancellation needed.
        Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()

                let weightUnit: HKUnit = self.unitSystem == 0 ? .gramUnit(with: .kilo) : .pound()
                let heightUnit: HKUnit = self.unitSystem == 0 ? .meterUnit(with: .centi) : .inch()

                if let hkWeight = try await HealthKitService.shared.fetchLatestWeight(unit: weightUnit) {
                    self.weight = String(format: "%.1f", hkWeight)
                }

                if let hkHeight = try await HealthKitService.shared.fetchLatestHeight(unit: heightUnit) {
                    self.height = String(format: "%.1f", hkHeight)
                }

                if let hkAge = try HealthKitService.shared.fetchAge() {
                    self.age = String(hkAge)
                }

                if let hkGender = try HealthKitService.shared.fetchGender() {
                    self.applyHealthKitGender(hkGender)
                }

                syncLogger.info("HealthKit sync successful")
            } catch {
                syncLogger.error("HealthKit sync failed: \(error.localizedDescription, privacy: .public)")
                self.isHealthSyncEnabled = false
            }
        }
    }

    /// Applies a HealthKit gender rawValue to the `gender` property.
    ///
    /// HKBiologicalSex rawValues: notSet=0, female=1, male=2, other=3.
    /// Values outside 0–3 have no matching Picker `.tag()` and emit a
    /// "variant selector cell index number could not be found" warning on every
    /// render. Clamping prevents that spam if HealthKit ever returns a future
    /// enum case.
    func applyHealthKitGender(_ rawValue: Int) {
        self.gender = min(max(rawValue, 0), 3)
    }

    // MARK: - Auth

    /// The currently authenticated user, or nil if signed out.
    /// Views must read this property instead of accessing `authService.currentUser` directly (MVVM).
    var currentUser: (any AuthUser)? {
        self.authService.currentUser
    }

    /// Signs in with Google via the injected auth service.
    /// On failure, sets `authError` with a generic user-facing message.
    /// On success, clears any prior `authError`.
    /// Views must call this method rather than accessing `authService` directly (MVVM).
    func signInWithGoogle() async {
        do {
            try await self.authService.signInWithGoogle()
            self.authError = nil
            syncLogger.info("Google sign-in succeeded")
        } catch {
            syncLogger.error("Google sign-in failed: \(error.localizedDescription, privacy: .public)")
            self.authError = AppError.authProviderFailed(underlying: error).errorDescription
        }
    }

    /// Signs out the current user via the injected auth service.
    /// Views must call this method rather than accessing `authService.signOut()` directly (MVVM).
    func signOut() {
        self.authService.signOut()
        syncLogger.info("User signed out")
    }

    // MARK: - Cloud Sync

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
            await self.handleSyncError(AppError.syncUploadFailed(
                underlying: NSError(
                    domain: "NetworkError",
                    code: -1009,
                    userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
                )
            ), shouldRetry: false)
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
                let shouldRetry = attempt < self.syncMaxRetryAttempts
                await self.handleSyncError(error, shouldRetry: shouldRetry, attempt: attempt)
            }
        }
    }

    func handleSyncSuccess() async {
        self.syncStatus = .success

        #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        // CancellationError from sleep is intentional (sync task cancelled) — status cleared by guard below
        try? await Task.sleep(nanoseconds: self.syncSuccessDisplayDuration)

        if !Task.isCancelled {
            self.syncStatus = .idle
        }
    }

    func handleSyncError(_ error: Error, shouldRetry: Bool, attempt: Int = 1) async {
        if shouldRetry {
            self.syncStatus = .error("Sync failed. Retrying... (Attempt \(attempt)/\(self.syncMaxRetryAttempts))")
            // CancellationError from sleep is intentional (retry cancelled on sync task cancel) — no-op
            try? await Task.sleep(nanoseconds: self.syncRetryDelay)
            if !Task.isCancelled {
                await self.performSyncWithRetry(attempt: attempt + 1)
            }
        } else {
            // Use AppError description if available; fall back to a generic message to avoid
            // exposing Firebase/NSError internals to the user. Detailed error logged above.
            let userMessage = AppError.syncUploadFailed(underlying: error).errorDescription
                ?? Strings.Settings.syncFailedGeneric
            self.syncStatus = .error(userMessage)

            #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif

            // CancellationError from sleep is intentional (sync task cancelled) — status cleared by guard below
            try? await Task.sleep(nanoseconds: self.syncErrorDisplayDuration)

            if !Task.isCancelled {
                self.syncStatus = .idle
            }
        }
    }

    // MARK: - Sync Status Display Helpers

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
