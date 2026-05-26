import FirebaseAuth
import Foundation
import SwiftUI

// MARK: - Insights Extension

extension MainViewModel {
    // MARK: - Computed Properties

    /// Returns today's persisted unified insight from the snapshot store.
    var todaysInsight: DailyInsight? {
        self.historicalService.getSnapshot(for: Date())?.insight
    }

    /// Whether an unread insight is available (drives the smiley red dot).
    var hasUnreadInsight: Bool {
        guard let insight = self.currentInsight else { return false }
        return !insight.isViewed
    }

    /// Whether any insight is available (enables smiley long-press).
    var hasInsightAvailable: Bool {
        self.currentInsight != nil
    }

    // MARK: - Insight Actions

    func dismissInsight() {
        if let insight = self.currentInsight {
            let entry = NudgeHistoryEntry(date: Date(), suggestion: insight.nudge.suggestion)
            self.nudgeHistory.append(entry)
            if self.nudgeHistory.count > ValidationLimits.nudgeHistoryMaxEntries {
                self.nudgeHistory = Array(self.nudgeHistory.suffix(ValidationLimits.nudgeHistoryMaxEntries))
            }
            self.saveData()
        }
        self.showInsightSheet = false
        if var insight = self.currentInsight {
            insight.markAsViewed()
            self.currentInsight = insight
        }
    }

    func markNudgeFollowedThrough(id: UUID) {
        guard let index = self.nudgeHistory.firstIndex(where: { $0.id == id }) else { return }
        self.nudgeHistory[index].wasFollowedThrough = true
        self.saveData()
    }

    func showInsightDetails() {
        guard self.currentInsight != nil else { return }
        self.showInsightSheet = true
    }

    func handleSmileyLongPress() {
        let hasFreshInsight = self.currentInsight.map {
            Calendar.current.isDateInToday($0.date)
        } ?? false
        guard self.isViewingToday || hasFreshInsight else { return }
        SensoryService.shared.playNudge(style: .heavy)
        if hasFreshInsight {
            self.showBriefingSheet = true
        } else {
            self.triggerInsightGeneration()
            self.showBreakdownSheet = true
        }
    }

    /// Called by `MainScreenSheets` via `.onChange(of: currentInsight)` on the parent
    /// view — NOT inside the sheet content — so it fires reliably even during dismiss.
    /// Guards ensure it only acts when the breakdown fallback is actually showing.
    func handleInsightGeneratedDuringFallback(_ insight: DailyInsight?) {
        guard self.showBreakdownSheet else { return }
        guard let insight, Calendar.current.isDateInToday(insight.date) else { return }
        self.showBreakdownSheet = false
        self.showBriefingSheet = true
    }

    // MARK: - Briefing Actions

    func markBriefingViewed() {
        guard var insight = self.currentInsight else { return }
        insight.markAsViewed()
        self.currentInsight = insight
        self.historicalService.updateInsight(for: Date(), insight: insight)
    }

    /// Triggers morning briefing generation via `InsightLifecycleService`.
    /// Idempotent by default: skips if a valid insight already exists for today.
    /// Pass `force: true` to bypass both the in-memory and snapshot caches (e.g. pull-to-refresh).
    func triggerInsightGeneration(force: Bool = false) {
        guard self.authService?.currentUser?.uid != nil else { return }
        guard !self.isInsightGenerationInProgress else { return }

        let date = Date()

        if !force {
            if let existing = self.currentInsight,
               Calendar.current.isDate(existing.date, inSameDayAs: date)
            {
                return
            }

            // Restore from persisted snapshot without triggering a Cloud Function call
            if let snapshot = self.historicalService.getSnapshot(for: date),
               let persisted = snapshot.insight,
               Calendar.current.isDate(persisted.date, inSameDayAs: date)
            {
                self.currentInsight = persisted
                return
            }
        }

        self.currentInsight = nil
        self.isInsightGenerationInProgress = true
        self.insightTask = Task {
            defer { self.isInsightGenerationInProgress = false }

            let healthKitSleepData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)
            let userContext = BriefingUserContext.build(
                from: self.healthProfileService.currentProfile,
                authService: self.authService
            )
            guard let insight = await self.insightLifecycleService.generateBriefing(
                for: date,
                userContext: userContext,
                nudgeHistory: self.nudgeHistory,
                healthKitSleepData: healthKitSleepData
            ) else { return }

            guard !Task.isCancelled else { return }
            self.currentInsight = insight

            guard let userId = self.authService?.currentUser?.uid else { return }
            NotificationManager.shared.scheduleBriefingNotification(
                headline: insight.headline,
                userId: userId
            )
        }
    }
}
