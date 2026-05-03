import Foundation

/// Pure, stateless logic for timeline animation decisions.
/// Isolated from SwiftUI so it is fully unit-testable without a UI host.
enum TimelineAnimationState {
    /// Returns true when the smiley should display a breathing pulse animation.
    /// Pulse is shown only for today's view when no meals have been logged yet —
    /// a gentle ambient invitation to start the day's journal.
    static func shouldPulse(mealCount: Int, isToday: Bool) -> Bool {
        isToday && mealCount == 0
    }

    /// Returns true when the empty-state greeting should be shown instead of
    /// the daily quote. The quote is reserved for after the first meal is logged.
    static func shouldShowEmptyStateGreeting(mealCount: Int, isToday: Bool) -> Bool {
        isToday && mealCount == 0
    }

    /// Returns true when the daily quote should be visible.
    /// Quote appears only after at least one meal is logged — it serves as a
    /// contextual reward rather than a disconnected static element.
    static func shouldShowQuote(mealCount: Int, isToday: Bool) -> Bool {
        if isToday {
            return mealCount > 0
        }
        return true
    }
}
