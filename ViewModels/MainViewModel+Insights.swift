import FirebaseAuth
import Foundation
import SwiftUI

// MARK: - Insights Extension

extension MainViewModel {
    // MARK: - Computed Properties

    /// Returns today's generated insight if available.
    var todaysInsight: DailyInsight? {
        // For now, insights are not persisted - will be added in future
        // This will be populated when insight generation is triggered
        nil
    }

    /// Returns true if the insight card should be shown.
    /// Shows when: there's an unviewed insight for today.
    var showInsightCard: Bool {
        guard let insight = self.todaysInsight else { return false }
        return !insight.isViewed
    }

    /// Whether an unread insight is available (for smiley red dot indicator)
    var hasUnreadInsight: Bool {
        guard let insight = self.currentInsight else { return false }
        return !insight.isViewed
    }

    /// Whether any insight is available (for enabling long-press on smiley)
    var hasInsightAvailable: Bool {
        self.currentInsight != nil
    }

    // MARK: - Briefing Computed Properties

    /// Whether the current briefing has been viewed
    var hasBriefingAvailable: Bool {
        self.currentBriefing != nil
    }

    /// Whether there's an unread briefing
    var hasUnreadBriefing: Bool {
        guard let briefing = self.currentBriefing else { return false }
        return !briefing.isViewed
    }

    /// Data contract for MorningBriefingCard — minimal exposure per tab guidelines.
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

    /// Dismisses the current insight card.
    func dismissInsight() {
        self.showInsightSheet = false
        if var insight = self.currentInsight {
            insight.markAsViewed()
            self.currentInsight = insight
        }
    }

    /// Opens the insight bottom sheet
    func showInsightDetails() {
        guard self.currentInsight != nil else { return }
        self.showInsightSheet = true
    }

    /// Handles long-press on smiley to show insight.
    /// Only shows insight sheet if an insight is available.
    func handleSmileyLongPress() {
        guard self.hasInsightAvailable else { return }
        SensoryService.shared.playNudge(style: .heavy)
        self.showInsightSheet = true
    }

    // MARK: - Briefing Actions

    /// Marks the current briefing as viewed and persists the change.
    func markBriefingViewed() {
        guard var briefing = self.currentBriefing else { return }
        briefing.markAsViewed()
        self.currentBriefing = briefing
        self.historicalService.updateBriefing(for: Date(), briefing: briefing)
    }

    /// Triggers briefing generation for today.
    /// Called after sleep quality is saved (the morning data trigger).
    func triggerBriefingGeneration() {
        let date = Date()

        if let existing = self.currentBriefing,
           Calendar.current.isDate(existing.date, inSameDayAs: date)
        {
            return
        }

        // Also check persisted snapshot to avoid duplicate Cloud Function calls after relaunch
        if let snapshot = self.historicalService.getSnapshot(for: date),
           let persisted = snapshot.briefing
        {
            self.currentBriefing = persisted
            return
        }

        Task {
            let healthKitSleepData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)
            if let briefing = await self.insightService.generateBriefing(
                for: date,
                healthKitSleepData: healthKitSleepData
            ) {
                self.currentBriefing = briefing
                self.historicalService.updateBriefing(for: date, briefing: briefing)

                let userId = Auth.auth().currentUser?.uid ?? "unknown"
                NotificationManager.shared.scheduleBriefingNotification(
                    headline: briefing.headline,
                    userId: userId
                )
            }
        }
    }
}
