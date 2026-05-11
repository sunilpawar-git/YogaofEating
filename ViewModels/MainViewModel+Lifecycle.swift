import Foundation
import HealthKit
import OSLog

private let lifecycleLogger = Logger(subsystem: "com.yogaofeating", category: "MainViewModel.Lifecycle")

extension MainViewModel {
    func loadData() {
        if let data = self.persistenceService.load() {
            self.meals = data.meals
            self.smileyState = data.smileyState
            self.lastResetDate = data.lastResetDate
            self.historicalService.historicalData = data.historicalData

            // Still check if we need to reset for a new day since the last save
            self.checkAndResetIfNewDay()

            // If sleep quality is already logged today, fetch Apple sleep data for badge display
            if self.todaysSleepQuality != nil {
                self.fetchAppleSleepDataForBadge()
            }
        }

        // Hydrate today's briefing from persisted snapshot (independent of persistence load)
        if self.currentBriefing == nil,
           let todayBriefing = self.historicalService.getSnapshot(for: Date())?.briefing
        {
            self.currentBriefing = todayBriefing
        }
    }

    func fetchAppleSleepDataForBadge() {
        self.sleepBadgeTask = Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    self.appleSleepData = sleepData
                    lifecycleLogger
                        .info(
                            "Loaded Apple sleep data for badge: \(sleepData.formattedDuration, privacy: .public)"
                        )
                }
            } catch {
                // Non-critical: badge simply won't show Apple metrics. Log at .info for debuggability.
                lifecycleLogger.info("Sleep badge fetch unavailable: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func saveData() {
        self.persistenceService.save(
            meals: self.meals,
            smileyState: self.smileyState,
            lastResetDate: self.lastResetDate,
            historicalData: self.historicalService.historicalData
        )
    }

    func cancelBriefingTask() {
        self.briefingTask?.cancel()
        self.briefingTask = nil
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
    /// Implemented in Phase 3. Stub intentionally empty during Phase 2 (TDD Red).
    func refreshActivityDataIfNeeded() {
        // stub — Phase 3
    }
}
