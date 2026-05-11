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

    // MARK: - Color Band Thresholds (used in Theme.swift for ScoreBadge colors)

    /// Upper color band: scores above this display as "great" green.
    static let colorBandHigh: Double = 0.75

    /// Mid color band: scores above this display as "okay" yellow-green.
    static let colorBandMid: Double = 0.55

    // MARK: - Trend Analysis

    /// Minimum score delta between the first and second half of a lookback window
    /// required to classify a trend as improving or declining (vs. steady).
    static let trendSignificanceDelta: Double = 0.1

    // MARK: - Input Validation (co-located with scoring domain to avoid a separate ValidationConstants file)

    /// Minimum character count in a meal description before AI analysis is triggered.
    /// Prevents excessive API calls while the user is still typing short content.
    static let minimumMealDescriptionLength: Int = 5
}

// MARK: - SynthesisThresholds

enum SynthesisThresholds {
    /// Minimum shift in any dimension that warrants a full insight re-generation.
    static let dimensionShiftThreshold: Double = 0.08

    /// Synthesis overall score above this → .serene smiley.
    static let overallHealthy: Double = 0.65

    /// Synthesis overall score in this range → .neutral smiley.
    static let overallNeutral: Double = 0.45

    /// Synthesis overall score below this → .overwhelmed smiley.
    /// Values between overallNeutral and this → .thoughtful (Phase 3).
    static let overallThoughtful: Double = 0.35
}
