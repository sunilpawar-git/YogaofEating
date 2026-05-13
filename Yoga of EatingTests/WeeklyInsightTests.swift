import XCTest
@testable import Yoga_of_Eating

/// Tests for Weekly Insight aggregation.
/// Phase 7: Compound daily insights into weekly summaries.
final class WeeklyInsightTests: XCTestCase {
    // MARK: - Model Tests

    func test_weeklyInsight_initialization() {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!

        // When
        let weekly = WeeklyInsight(
            weekStartDate: weekStart,
            weekEndDate: today,
            summaryText: "Great week overall!",
            topPatterns: [],
            dailyInsights: [],
            improvementAreas: ["Sleep timing"],
            wins: ["Consistent exercise"]
        )

        // Then
        XCTAssertEqual(weekly.summaryText, "Great week overall!")
        XCTAssertEqual(weekly.improvementAreas.count, 1)
        XCTAssertEqual(weekly.wins.count, 1)
    }

    func test_weeklyInsight_aggregatesMultipleDailyInsights() {
        // Given
        let dailyInsights = [
            LegacyDailyInsight(
                date: Date(),
                insightText: "Day 1 insight",
                insightType: .foodSleep,
                confidence: 0.8
            ),
            LegacyDailyInsight(
                date: Date().addingTimeInterval(-86400),
                insightText: "Day 2 insight",
                insightType: .mindsetFeeling,
                confidence: 0.7
            ),
            LegacyDailyInsight(
                date: Date().addingTimeInterval(-86400 * 2),
                insightText: "Day 3 insight",
                insightType: .pattern,
                confidence: 0.9
            )
        ]

        // When
        let weekly = WeeklyInsight(
            weekStartDate: Date().addingTimeInterval(-86400 * 6),
            weekEndDate: Date(),
            summaryText: "Summary",
            topPatterns: [],
            dailyInsights: dailyInsights,
            improvementAreas: [],
            wins: []
        )

        // Then
        XCTAssertEqual(weekly.dailyInsights.count, 3)
    }

    func test_weeklyInsight_identifiesTopPatterns() {
        // Given
        let patterns = [
            InsightPattern(
                type: .foodSleep,
                description: "Late dinners affect sleep",
                confidence: 0.9,
                references: []
            ),
            InsightPattern(
                type: .mindsetFeeling,
                description: "Gratitude improves mood",
                confidence: 0.7,
                references: []
            )
        ]

        // When
        let weekly = WeeklyInsight(
            weekStartDate: Date().addingTimeInterval(-86400 * 6),
            weekEndDate: Date(),
            summaryText: "Summary",
            topPatterns: patterns,
            dailyInsights: [],
            improvementAreas: [],
            wins: []
        )

        // Then
        XCTAssertEqual(weekly.topPatterns.count, 2)
        XCTAssertEqual(weekly.topPatterns.first?.confidence, 0.9)
    }

    func test_weeklyInsight_generatesWeeklySummary() {
        // Given
        let calendar = Calendar.current
        let today = Date()

        let dailyInsights = (0..<5).map { daysAgo in
            LegacyDailyInsight(
                date: calendar.date(byAdding: .day, value: -daysAgo, to: today)!,
                insightText: "Insight for day \(daysAgo)",
                insightType: daysAgo % 2 == 0 ? .foodSleep : .mindsetFeeling,
                confidence: 0.7 + Double(daysAgo) * 0.02
            )
        }

        // When
        let weekly = WeeklyInsight(
            weekStartDate: calendar.date(byAdding: .day, value: -6, to: today)!,
            weekEndDate: today,
            summaryText: "This week you focused on food and sleep patterns.",
            topPatterns: [],
            dailyInsights: dailyInsights,
            improvementAreas: ["Evening meal timing"],
            wins: ["5 days of logging", "Improved sleep quality"]
        )

        // Then
        XCTAssertFalse(weekly.summaryText.isEmpty)
        XCTAssertEqual(weekly.wins.count, 2)
    }

    // MARK: - Codable Tests

    func test_weeklyInsight_encodesAndDecodes() throws {
        // Given
        let weekly = WeeklyInsight(
            weekStartDate: Date(),
            weekEndDate: Date(),
            summaryText: "Test summary",
            topPatterns: [],
            dailyInsights: [],
            improvementAreas: ["Area 1"],
            wins: ["Win 1"]
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(weekly)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeeklyInsight.self, from: data)

        // Then
        XCTAssertEqual(decoded.summaryText, weekly.summaryText)
        XCTAssertEqual(decoded.improvementAreas, weekly.improvementAreas)
        XCTAssertEqual(decoded.wins, weekly.wins)
    }

    // MARK: - Service Tests

    @MainActor
    func test_weeklyInsight_model_encodesAndDecodes() throws {
        // WeeklyInsight model is deleted in Phase 5. Test that the model type is still Codable.
        let weekly = WeeklyInsight(weekStartDate: Date(), weekEndDate: Date(), summaryText: "Good week")
        let data = try JSONEncoder().encode(weekly)
        let decoded = try JSONDecoder().decode(WeeklyInsight.self, from: data)
        XCTAssertEqual(decoded.summaryText, "Good week")
    }

    // MARK: - Strings Tests

    func test_weekly_strings_exist() {
        XCTAssertFalse(Strings.Insight.weeklyTitle.isEmpty)
    }
}
