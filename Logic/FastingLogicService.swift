import Foundation

/// Service to calculate fasting periods between meals.
enum FastingLogicService {
    /// Minimum connector spacing in points
    static let minimumSpacing: CGFloat = 30.0

    /// Scale factor: points per 10 minutes of fasting
    static let spacingScaleFactor: CGFloat = 0.5

    /// Minimum fasting hours to show badge
    static let minimumBadgeHours: Double = 1.0

    /// Calculates fasting periods between consecutive meals.
    /// Meals are sorted by timestamp before calculation.
    /// - Parameter meals: Array of meals to analyze
    /// - Returns: Array of fasting periods between consecutive meals
    static func calculateFastingPeriods(from meals: [Meal]) -> [FastingPeriod] {
        // Need at least 2 meals to have a fasting period
        guard meals.count >= 2 else { return [] }

        // Sort meals by timestamp
        let sortedMeals = meals.sorted { $0.timestamp < $1.timestamp }

        var periods: [FastingPeriod] = []

        for index in 0..<(sortedMeals.count - 1) {
            let currentMeal = sortedMeals[index]
            let nextMeal = sortedMeals[index + 1]

            // Skip pairs where timestamps are identical or inverted (duplicate/bad data)
            guard nextMeal.timestamp > currentMeal.timestamp else { continue }

            let period = FastingPeriod(
                startMealId: currentMeal.id,
                endMealId: nextMeal.id,
                startTime: currentMeal.timestamp,
                endTime: nextMeal.timestamp
            )

            periods.append(period)
        }

        return periods
    }

    /// Calculates the visual spacing for a fasting period.
    /// Longer fasting durations result in proportionally longer connectors.
    /// - Parameter period: The fasting period to calculate spacing for
    /// - Returns: Spacing in points
    static func calculateSpacing(for period: FastingPeriod) -> CGFloat {
        let durationInMinutes = period.duration / 60.0
        let scaledSpacing = CGFloat(durationInMinutes / 10.0) * Self.spacingScaleFactor

        return max(Self.minimumSpacing, scaledSpacing + Self.minimumSpacing)
    }

    /// Determines if a badge should be shown for this fasting period.
    /// - Parameter period: The fasting period to check
    /// - Returns: True if badge should be displayed
    static func shouldShowBadge(for period: FastingPeriod) -> Bool {
        period.durationInHours >= self.minimumBadgeHours
    }
}
