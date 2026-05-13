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

    /// Whether the insight card should be shown (unviewed insight available).
    var showInsightCard: Bool {
        guard let insight = self.todaysInsight else { return false }
        return !insight.isViewed
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

    /// Briefing card data contract — minimal fields for `MorningBriefingCard`.
    var briefingCardData: (headline: String, topCorrelation: String?, nudge: String, isViewed: Bool)? {
        guard let insight = self.currentInsight else { return nil }
        return (
            headline: insight.headline,
            topCorrelation: insight.topCorrelation?.observation,
            nudge: insight.nudge.suggestion,
            isViewed: insight.isViewed
        )
    }

    var hasBriefingAvailable: Bool { self.currentInsight != nil }
    var hasUnreadBriefing: Bool { self.hasUnreadInsight }

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

    // MARK: - Briefing Actions

    func markBriefingViewed() {
        guard var insight = self.currentInsight else { return }
        insight.markAsViewed()
        self.currentInsight = insight
        self.historicalService.updateInsight(for: Date(), insight: insight)
    }

    /// Triggers morning briefing generation via `InsightLifecycleService`.
    /// Idempotent: skips if an insight already exists for today.
    func triggerInsightGeneration() {
        guard !self.isInsightGenerationInProgress else { return }

        let date = Date()

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

        self.isInsightGenerationInProgress = true
        self.insightTask = Task {
            defer { self.isInsightGenerationInProgress = false }

            let healthKitSleepData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)
            guard let insight = await self.insightLifecycleService.generateBriefing(
                for: date,
                healthKitSleepData: healthKitSleepData
            ) else { return }

            guard !Task.isCancelled else { return }
            self.currentInsight = insight

            guard let userId = Auth.auth().currentUser?.uid else { return }
            NotificationManager.shared.scheduleBriefingNotification(
                headline: insight.headline,
                userId: userId
            )
        }
    }
}
