import Foundation

/// Single source of truth for all scoring thresholds used across the app.
/// All business logic that branches on health scores must reference these constants.
/// Never duplicate these values in service files, view models, or views.
enum ScoringThresholds {
    /// Scores above this are considered "healthy" — triggers .serene smiley, shrinks scale.
    static let healthy: Double = 0.65

    /// Scores below this are considered "unhealthy" — triggers .overwhelmed smiley, grows scale.
    static let unhealthy: Double = 0.35

    /// Two consecutive days with averageHealthScore below this trigger the food-debt
    /// smiley starting state and a CorrelationCard in the morning briefing.
    /// Basis: Esposito et al. (2002) — inflammatory markers after 2 poor-eating days.
    static let foodDebtBadDay: Double = 0.45

    /// "Great week" threshold — weekly summary phrases above this score.
    static let high: Double = 0.7

    /// Neutral/default fallback score when no data is available.
    static let neutral: Double = 0.5

    /// Minimum consecutive days with score >= high to earn a "healthy eating streak" win.
    static let minimumConsistentDays: Int = 5
}
