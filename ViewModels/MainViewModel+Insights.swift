import Foundation
import SwiftUI

// MARK: - Insights Extension

extension MainViewModel {
    // MARK: - Computed Properties

    /// Whether an unviewed insight exists (drives both inline card and smiley red dot)
    var showInsightCard: Bool {
        guard let insight = self.currentInsight else { return false }
        return !insight.isViewed
    }

    var hasUnreadInsight: Bool { self.showInsightCard }

    /// Whether any insight is available (for enabling long-press on smiley)
    var hasInsightAvailable: Bool {
        self.currentInsight != nil
    }

    // MARK: - Insight Actions

    /// Dismisses the current insight card and persists the viewed state.
    func dismissInsight() {
        self.showInsightSheet = false
        guard var insight = self.currentInsight else { return }
        insight.markAsViewed()
        self.currentInsight = insight
        self.historicalService.updateDailyInsight(for: insight.date, insight: insight)
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

    /// Generates or refreshes the weekly summary insight when enough data exists.
    func refreshWeeklyInsight() {
        Task {
            let insight = await self.insightService.generateWeeklyInsight()
            await MainActor.run {
                self.currentWeeklyInsight = insight
            }
        }
    }
}
