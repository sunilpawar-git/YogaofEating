import Foundation

/// Represents a weekly aggregation of daily insights.
/// Compounds daily patterns into a weekly summary with wins and improvement areas.
struct WeeklyInsight: Codable, Identifiable, Equatable {
    /// Unique identifier
    let id: UUID

    /// Start date of the week
    let weekStartDate: Date

    /// End date of the week
    let weekEndDate: Date

    /// Summary text for the week
    let summaryText: String

    /// Top patterns detected across the week
    let topPatterns: [InsightPattern]

    /// Individual daily insights that make up this weekly summary
    let dailyInsights: [DailyInsight]

    /// Areas where the user could improve
    let improvementAreas: [String]

    /// Wins/achievements for the week
    let wins: [String]

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weekEndDate: Date,
        summaryText: String,
        topPatterns: [InsightPattern] = [],
        dailyInsights: [DailyInsight] = [],
        improvementAreas: [String] = [],
        wins: [String] = []
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.summaryText = summaryText
        self.topPatterns = topPatterns
        self.dailyInsights = dailyInsights
        self.improvementAreas = improvementAreas
        self.wins = wins
    }

    // MARK: - Computed Properties

    /// Formatted date range string like "6 Jan - 12 Jan"
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: self.weekStartDate)) - \(formatter.string(from: self.weekEndDate))"
    }

    /// Number of days with insights
    var daysWithInsights: Int {
        self.dailyInsights.count
    }

    /// Average confidence across all daily insights
    var averageConfidence: Double {
        guard !self.dailyInsights.isEmpty else { return 0 }
        return self.dailyInsights.map(\.confidence).reduce(0, +) / Double(self.dailyInsights.count)
    }

    /// Most common insight type this week
    var dominantInsightType: InsightType? {
        let typeCounts = Dictionary(grouping: self.dailyInsights, by: \.insightType)
            .mapValues(\.count)
        return typeCounts.max(by: { $0.value < $1.value })?.key
    }

    /// Whether this was a good week (more wins than improvement areas)
    var isPositiveWeek: Bool {
        self.wins.count >= self.improvementAreas.count
    }
}
