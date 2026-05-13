import FirebaseAuth
import Foundation
import SwiftUI

// MARK: - Insights Extension

extension MainViewModel {
    // MARK: - Computed Properties

    /// Returns today's generated unified insight from the persisted snapshot.
    var todaysInsight: DailyInsight? {
        self.historicalService.getSnapshot(for: Date())?.insight
    }

    /// Whether the insight card should be shown (unviewed insight exists).
    var showInsightCard: Bool {
        guard let insight = self.todaysInsight else { return false }
        return !insight.isViewed
    }

    /// Whether an unread legacy insight is available (smiley red dot).
    var hasUnreadInsight: Bool {
        guard let insight = self.currentInsight else { return false }
        return !insight.isViewed
    }

    /// Whether any legacy insight is available (enables smiley long-press).
    var hasInsightAvailable: Bool {
        self.currentInsight != nil
    }

    // MARK: - Briefing Computed Properties (Phase 2 bridge — removed in Phase 4)

    var hasBriefingAvailable: Bool {
        self.currentBriefing != nil
    }

    var hasUnreadBriefing: Bool {
        guard let briefing = self.currentBriefing else { return false }
        return !briefing.isViewed
    }

    var briefingCardData: (headline: String, topCorrelation: String?, nudge: String, isViewed: Bool)? {
        guard let briefing = self.currentBriefing else { return nil }
        return (
            headline: briefing.headline,
            topCorrelation: briefing.topCorrelation?.observation,
            nudge: briefing.nudge.suggestion,
            isViewed: briefing.isViewed
        )
    }

    // MARK: - Insight Actions

    func dismissInsight() {
        self.showInsightSheet = false
        if var insight = self.currentInsight {
            insight.markAsViewed()
            self.currentInsight = insight
        }
    }

    func showInsightDetails() {
        guard self.currentInsight != nil else { return }
        self.showInsightSheet = true
    }

    func handleSmileyLongPress() {
        guard self.wellbeingBreakdownContract != nil || self.hasInsightAvailable else { return }
        SensoryService.shared.playNudge(style: .heavy)
        if self.wellbeingBreakdownContract != nil {
            self.showBreakdownSheet = true
        } else {
            self.showInsightSheet = true
        }
    }

    // MARK: - Briefing Actions (Phase 2 bridge — removed in Phase 4)

    func markBriefingViewed() {
        guard var briefing = self.currentBriefing else { return }
        briefing.markAsViewed()
        self.currentBriefing = briefing
        // Convert to unified insight and persist via the SSOT storage path
        self.historicalService.updateInsight(for: Date(), insight: DailyInsight(briefing: briefing))
    }

    func triggerBriefingGeneration() {
        guard !self.isBriefingGenerationInProgress else { return }

        let date = Date()

        if let existing = self.currentBriefing,
           Calendar.current.isDate(existing.date, inSameDayAs: date)
        {
            return
        }

        // Restore from persisted unified insight (Phase 2: no more snapshot.briefing)
        if let snapshot = self.historicalService.getSnapshot(for: date),
           let persistedInsight = snapshot.insight,
           Calendar.current.isDate(persistedInsight.date, inSameDayAs: date)
        {
            self.currentBriefing = DailyBriefing(insight: persistedInsight)
            return
        }

        self.isBriefingGenerationInProgress = true
        self.briefingTask = Task {
            defer { self.isBriefingGenerationInProgress = false }

            let healthKitSleepData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)
            if let briefing = await self.insightService.generateBriefing(
                for: date,
                healthKitSleepData: healthKitSleepData
            ) {
                guard !Task.isCancelled else { return }
                self.currentBriefing = briefing
                // Store via unified SSOT path (Phase 2 bridge converts DailyBriefing → DailyInsight)
                self.historicalService.updateInsight(for: date, insight: DailyInsight(briefing: briefing))

                guard let userId = Auth.auth().currentUser?.uid else { return }
                NotificationManager.shared.scheduleBriefingNotification(
                    headline: briefing.headline,
                    userId: userId
                )
            }
        }
    }
}
