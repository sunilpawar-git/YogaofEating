import Foundation
import HealthKit
import OSLog

private let lifecycleLogger = Logger(subsystem: "com.yogaofeating", category: "MainViewModel.Lifecycle")

extension MainViewModel {
    func loadData() {
        if let data = self.persistenceService.load() {
            // Account-switch detection: if the signed-in user differs from the last stored user,
            // discard the stale local data and restore the new user's cloud history.
            let currentUID = self.authService?.currentUser?.uid
            let storedUID = self.userDefaults.string(forKey: StorageKeys.lastSignedInUID)
            if let currentUID, let storedUID, currentUID != storedUID {
                self.historicalService.clearAllData()
                self.saveData()
                // A new user has signed in — clear the previous user's data-deletion flag
                // so their cloud history can be restored without interference.
                self.userDefaults.removeObject(forKey: StorageKeys.hasDeletedAllData)
                self.triggerCloudRestoreIfNeeded()
                return
            }

            self.meals = data.meals
            self.smileyState = data.smileyState
            self.lastResetDate = data.lastResetDate
            self.historicalService.historicalData = data.historicalData
            self.nudgeHistory = data.nudgeHistory

            // Update stored UID so future launches can detect any subsequent account switch.
            if let currentUID {
                self.userDefaults.set(currentUID, forKey: StorageKeys.lastSignedInUID)
            }

            // Still check if we need to reset for a new day since the last save
            self.checkAndResetIfNewDay()

            // If sleep quality is already logged today, fetch Apple sleep data for badge display
            if self.todaysSleepQuality != nil {
                self.fetchAppleSleepDataForBadge()
            }
        } else {
            // No local persistence file — fresh install or Xcode reinstall.
            // Attempt to restore historical data from Firebase so the user's
            // past entries reappear after a device/simulator wipe.
            self.triggerCloudRestoreIfNeeded()
        }

        // Hydrate today's insight from persisted snapshot
        if self.currentInsight == nil,
           let persistedInsight = self.historicalService.getSnapshot(for: Date())?.insight
        {
            self.currentInsight = persistedInsight
        }

        // Pre-generate today's briefing in the background so it's already ready when
        // the user opens it. triggerInsightGeneration is idempotent — it returns early
        // if a fresh snapshot already exists, so no extra Cloud Function calls are made.
        self.triggerInsightGeneration()

        // Refresh today's activity data for a live TDEE in the calorie pill
        self.refreshActivityDataIfNeeded()
    }

    /// Kicks off a background restore from Firebase when no local persistence file exists.
    /// Fire-and-forget: throws `syncAuthRequired` (silently) when not signed in.
    /// Stores the current user's UID after a successful restore so future launches
    /// can detect account switches.
    func triggerCloudRestoreIfNeeded() {
        // Respect an explicit user-initiated data deletion: do not automatically re-download
        // cloud data the user chose to erase on this device.
        guard !self.userDefaults.bool(forKey: StorageKeys.hasDeletedAllData) else {
            lifecycleLogger.info("Cloud restore skipped — user has explicitly deleted all data on this device.")
            return
        }
        Task { [weak self] in
            guard let self else { return }
            try? await self.historicalService.restoreFromFirebase()
            if let uid = self.authService?.currentUser?.uid {
                self.userDefaults.set(uid, forKey: StorageKeys.lastSignedInUID)
            }
        }
    }

    func fetchAppleSleepDataForBadge() {
        self.sleepBadgeTask?.cancel()
        self.sleepBadgeTask = Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    self.appleSleepData = sleepData
                    lifecycleLogger
                        .info(
                            "Loaded Apple sleep data for badge: \(sleepData.formattedDuration, privacy: .private)"
                        )
                }
            } catch {
                // Non-critical: badge simply won't show Apple metrics. Log at .info for debuggability.
                lifecycleLogger.info("Sleep badge fetch unavailable: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    func saveData() {
        self.persistenceService.save(
            meals: self.meals,
            smileyState: self.smileyState,
            lastResetDate: self.lastResetDate,
            historicalData: self.historicalService.historicalData,
            nudgeHistory: self.nudgeHistory
        )
    }

    func cancelInsightTask() {
        self.insightTask?.cancel()
        self.insightTask = nil
    }

    func checkAndResetIfNewDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(self.lastResetDate) {
            self.resetDay()
            self.lastResetDate = Date()
            self.saveData()
        }
    }

    func setupResetMonitoring() {
        self.resetMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                // CancellationError from sleep is intentional (task cancelled on deinit) — no-op
                try? await Task.sleep(nanoseconds: TimingConstants.dayResetPollIntervalNanoseconds)
                self?.checkAndResetIfNewDay()
            }
        }
    }

    /// Refreshes today's activity data from HealthKit if the cooldown window has elapsed.
    /// Call on app startup and on foreground. The cooldown guard prevents redundant
    /// HealthKit queries on rapid foreground/background cycles.
    ///
    /// Auth and data fetch are intentionally separate Tasks:
    /// - Auth uses `HealthKitService.shared` directly (not injectable) and may show a dialog
    /// - Data fetch uses the injected `activityProvider` (mockable in tests), so tests are deterministic
    func refreshActivityDataIfNeeded() {
        // HealthKit auth shows a system sheet that intercepts taps in UI tests — skip entirely.
        guard !CommandLine.arguments.contains("--uitesting") else { return }
        let elapsed = Date().timeIntervalSince(self.lastActivityDataFetchDate ?? .distantPast)
        guard elapsed >= TimingConstants.activityFetchCooldown else { return }
        self.lastActivityDataFetchDate = Date()

        // Request HealthKit permissions (fire-and-forget; may show permission dialog).
        // After successful auth, also load today's data — covers the first-launch case where
        // the data task below fires before the permission dialog is dismissed.
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                await self.loadTodayActivityData()
            } catch {
                lifecycleLogger.info("Activity auth unavailable: \(error.localizedDescription, privacy: .private)")
            }
        }

        // Fetch data via injected provider (mockable; runs independently of auth task).
        // Cancel any prior in-flight fetch before launching a new one.
        self.activityRefreshTask?.cancel()
        self.activityRefreshTask = Task { [weak self] in
            guard let self else { return }
            await self.loadTodayActivityData()
            lifecycleLogger.info("Activity data refreshed")
        }
    }
}
