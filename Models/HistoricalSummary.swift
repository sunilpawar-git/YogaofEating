import Foundation

/// Aggregate statistics for a time period (30 or 90 days).
struct PeriodStats: Codable {
    let averageFoodScore: Double
    let daysLogged: Int
}

/// Aggregate wellbeing patterns across 30 and 90 days.
/// Contains only statistical aggregates — no raw meal descriptions.
struct HistoricalSummary: Codable {
    let thirtyDayStats: PeriodStats
    let ninetyDayStats: PeriodStats?
    let currentStreak: Int
    let bestDimension: WellbeingDimension?
    let worstDimension: WellbeingDimension?

    static let empty = HistoricalSummary(
        thirtyDayStats: PeriodStats(averageFoodScore: 0.0, daysLogged: 0),
        ninetyDayStats: nil,
        currentStreak: 0,
        bestDimension: nil,
        worstDimension: nil
    )
}
