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
                _ = try await self.healthKitProvider.requestAuthorization()

                let weightUnit: HKUnit = self.unitSystem == 0 ? .gramUnit(with: .kilo) : .pound()
                let heightUnit: HKUnit = self.unitSystem == 0 ? .meterUnit(with: .centi) : .inch()

                if let hkWeight = try await self.healthKitProvider.fetchLatestWeight(unit: weightUnit) {
                    self.weight = String(format: "%.1f", hkWeight)
                }

                if let hkHeight = try await self.healthKitProvider.fetchLatestHeight(unit: heightUnit) {
                    self.height = String(format: "%.1f", hkHeight)
                }

                if let hkAge = try self.healthKitProvider.fetchAge() {
                    self.age = String(hkAge)
                }

                if let hkGender = try self.healthKitProvider.fetchGender() {
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

    /// Performs a single cloud sync attempt. Retries are handled at the
    /// `HistoricalSyncService.withRetry` layer — no outer loop needed here.
    func performSyncWithRetry() async {
        guard self.isNetworkAvailable else {
            await self.handleSyncError(AppError.syncUploadFailed(
                underlying: NSError(
                    domain: "NetworkError",
                    code: -1009,
                    userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
                )
            ))
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
                await self.handleSyncError(error)
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

    func handleSyncError(_ error: Error) async {
        // Use the typed AppError description when available; fall back to a generic message to
        // avoid exposing Firebase/NSError internals to the user. Detailed error is logged by the service.
        let userMessage = (error as? AppError)?.errorDescription
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

    // MARK: - Sync Status Display Helpers

    var syncStatusText: String {
        switch self.syncStatus {
        case .idle: Strings.Settings.syncButtonIdle
        case .syncing: Strings.Settings.syncButtonSyncing
        case .success: Strings.Settings.syncButtonSuccess
        case .error: Strings.Settings.syncButtonError
        }
    }

    var syncAccessibilityLabel: String {
        switch self.syncStatus {
        case .idle: Strings.Settings.syncAccessibilityLabelIdle
        case .syncing: Strings.Settings.syncAccessibilityLabelSyncing
        case .success: Strings.Settings.syncAccessibilityLabelSuccess
        case let .error(message): Strings.Settings.syncAccessibilityLabelErrorPrefix + message
        }
    }

    var syncAccessibilityHint: String {
        switch self.syncStatus {
        case .idle: Strings.Settings.syncAccessibilityHintIdle
        case .syncing: Strings.Settings.syncAccessibilityHintSyncing
        case .success: Strings.Settings.syncAccessibilityHintSuccess
        case .error: Strings.Settings.syncAccessibilityHintError
        }
    }
}
