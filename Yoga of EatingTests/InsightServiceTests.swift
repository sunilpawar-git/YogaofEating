import XCTest
@testable import Yoga_of_Eating

/// Phase 3C — split tests.
///
/// Verifies that:
/// 1. `BriefingService` can generate a briefing independently of `InsightGenerationService`.
/// 2. `PatternAnalysisEngine` produces the same output as the pre-split `PatternAnalyzer`.
@MainActor
final class InsightServiceTests: XCTestCase {
    // MARK: - BriefingService isolation

    func test_briefingService_generatesLocalBriefing_independently() async {
        let mockHistorical = MockHistoricalDataService()
        let briefingService = BriefingService(historicalService: mockHistorical)

        // Provide at least 2 snapshots (minimum required by generateBriefing)
        let snapshots = [
            Self.makeSnapshot(daysAgo: 1, score: 0.7),
            Self.makeSnapshot(daysAgo: 2, score: 0.6)
        ]
        for snap in snapshots {
            mockHistorical.historicalData.addOrUpdate(snapshot: snap)
        }

        let briefing = await briefingService.generateBriefing(for: Date(), healthKitSleepData: [:])

        XCTAssertNotNil(briefing, "BriefingService must generate a local briefing when Firebase is unavailable")
    }

    func test_briefingService_returnsNil_whenInsufficientData() async {
        let mockHistorical = MockHistoricalDataService()
        let briefingService = BriefingService(historicalService: mockHistorical)
        // No snapshots added — below the 2-snapshot minimum

        let briefing = await briefingService.generateBriefing(for: Date(), healthKitSleepData: [:])

        XCTAssertNil(briefing, "BriefingService must return nil when fewer than 2 snapshots are available")
    }

    // MARK: - PatternAnalysisEngine parity

    func test_patternAnalysisEngine_producesSameOutputAsPatternAnalyzer() {
        let snapshots = Self.makeSnapshotsForPatternAnalysis()

        let analyzer = PatternAnalyzer()
        let engine = PatternAnalysisEngine()

        let analyzerOutput = analyzer.generateCorrelationCards(from: snapshots)
        let engineOutput = engine.generateCorrelationCards(from: snapshots)

        XCTAssertEqual(
            analyzerOutput.count,
            engineOutput.count,
            "PatternAnalysisEngine must produce the same number of correlation cards as the original PatternAnalyzer"
        )

        let analyzerCategories = analyzerOutput.map(\.category).sorted { $0.rawValue < $1.rawValue }
        let engineCategories = engineOutput.map(\.category).sorted { $0.rawValue < $1.rawValue }
        XCTAssertEqual(
            analyzerCategories,
            engineCategories,
            "PatternAnalysisEngine must produce identical card categories as the original PatternAnalyzer"
        )
    }

    func test_patternAnalysisEngine_matchesPatternAnalyzerPatterns() {
        let snapshots = Self.makeSnapshotsForPatternAnalysis()

        let analyzer = PatternAnalyzer()
        let engine = PatternAnalysisEngine()

        let analyzerPatterns = analyzer.analyzePatterns(from: snapshots)
        let enginePatterns = engine.analyzePatterns(from: snapshots)

        XCTAssertEqual(
            analyzerPatterns.count,
            enginePatterns.count,
            "PatternAnalysisEngine.analyzePatterns must match the original PatternAnalyzer output count"
        )

        let analyzerTypes = analyzerPatterns.map(\.patternType).sorted { $0.rawValue < $1.rawValue }
        let engineTypes = enginePatterns.map(\.patternType).sorted { $0.rawValue < $1.rawValue }
        XCTAssertEqual(
            analyzerTypes,
            engineTypes,
            "PatternAnalysisEngine.analyzePatterns must produce identical pattern types as the original PatternAnalyzer"
        )
    }

    // MARK: - Helpers

    private static func makeSnapshot(daysAgo: Int, score: Double) -> DailySmileySnapshot {
        let meal = MealBuilder().withItems(["salad"]).withScore(score).analyzed().build()
        return DailySmileySnapshotBuilder()
            .daysAgo(daysAgo)
            .withMeals([meal])
            .build()
    }

    private static func makeSnapshotsForPatternAnalysis() -> [DailySmileySnapshot] {
        (1...5).map { daysAgo in Self.makeSnapshot(daysAgo: daysAgo, score: 0.6) }
    }
}
