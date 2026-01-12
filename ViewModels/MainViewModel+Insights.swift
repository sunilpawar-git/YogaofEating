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

    /// Whether the peekaboo star should show an unread indicator
    var hasUnreadInsight: Bool {
        guard let insight = self.currentInsight else { return false }
        return !insight.isViewed
    }

    /// Whether the peekaboo star should be visible
    var shouldShowPeekabooStar: Bool {
        self.currentInsight != nil
    }

    // MARK: - Insight Actions

    /// Dismisses the current insight card.
    func dismissInsight() {
        // Mark insight as viewed
        self.showInsightSheet = false
        if self.currentInsight != nil {
            self.currentInsight?.markAsViewed()
        }
    }

    /// Opens the insight bottom sheet
    func showInsightDetails() {
        guard self.currentInsight != nil else { return }
        self.showInsightSheet = true
    }
}
