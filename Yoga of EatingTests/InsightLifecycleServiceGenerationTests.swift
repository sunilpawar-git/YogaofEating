import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Tests for InsightLifecycleService.generateBriefing — the unified briefing generation path.
/// Verifies server-first, local-fallback behaviour after BriefingService deletion.
@MainActor
final class InsightLifecycleServiceGenerationTests: XCTestCase {
    private var mockHistorical: MockHistoricalDataService!
    private var sut: InsightLifecycleService!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        // nil functions → local-only mode (no Firebase in tests)
        self.sut = InsightLifecycleService(
            historicalService: self.mockHistorical,
            functions: nil
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockHistorical = nil
        super.tearDown()
    }

    // MARK: - generateBriefing exists and returns DailyInsight

    func test_generateBriefing_returnsNil_whenFewerThanTwoSnapshots() async {
        let result = await self.sut.generateBriefing(for: Date(), healthKitSleepData: [:])
        XCTAssertNil(result)
    }

    func test_generateBriefing_returnsInsight_withTwoOrMoreSnapshots() async {
        self.seedSnapshots(count: 3)
        let result = await self.sut.generateBriefing(for: Date(), healthKitSleepData: [:])
        XCTAssertNotNil(result)
    }

    func test_generateBriefing_returnsUnifiedDailyInsight_notLegacyType() async {
        self.seedSnapshots(count: 3)
        let result = await self.sut.generateBriefing(for: Date(), healthKitSleepData: [:])
        // Compile-time: result type is DailyInsight, not LegacyDailyInsight or DailyBriefing
        XCTAssertNotNil(result as DailyInsight?)
    }

    // MARK: - Local fallback content

    func test_generateBriefing_localFallback_headlineIsNonEmpty() async {
        self.seedSnapshots(count: 3)
        let result = await self.sut.generateBriefing(for: Date(), healthKitSleepData: [:])
        XCTAssertFalse(result?.headline.isEmpty ?? true)
    }

    func test_generateBriefing_localFallback_nudgeSuggestionIsNonEmpty() async {
        self.seedSnapshots(count: 3)
        let result = await self.sut.generateBriefing(for: Date(), healthKitSleepData: [:])
        XCTAssertFalse(result?.nudge.suggestion.isEmpty ?? true)
    }

    func test_generateBriefing_localFallback_confidenceIsValid() async {
        self.seedSnapshots(count: 5)
        let result = await self.sut.generateBriefing(for: Date(), healthKitSleepData: [:])
        XCTAssertGreaterThanOrEqual(result?.confidence ?? -1, 0.0)
        XCTAssertLessThanOrEqual(result?.confidence ?? 2, 1.0)
    }

    func test_generateBriefing_highScoringSnapshots_headlineReflectsProgress() async {
        self.seedSnapshots(count: 4, averageScore: 0.85)
        let result = await self.sut.generateBriefing(for: Date(), healthKitSleepData: [:])
        XCTAssertNotNil(result)
        // Should not be the "challenging" headline for high scorers
        XCTAssertNotEqual(result?.headline, Strings.Insight.Headline.challenging)
    }

    // MARK: - Persistence

    func test_generateBriefing_persistsViaUpdateInsight() async {
        self.seedSnapshots(count: 3)
        _ = await self.sut.generateBriefing(for: Date(), healthKitSleepData: [:])
        XCTAssertTrue(self.mockHistorical.updateInsightCalled)
    }

    func test_generateBriefing_persistedInsight_retrievableFromSnapshot() async {
        let today = Calendar.current.startOfDay(for: Date())
        self.seedSnapshots(count: 3)
        _ = await self.sut.generateBriefing(for: today, healthKitSleepData: [:])
        XCTAssertNotNil(self.mockHistorical.getSnapshot(for: today)?.insight)
    }

    // MARK: - No BriefingService dependency

    func test_insightLifecycleService_hasNoBriefingServiceDependency() {
        // Structural: InsightLifecycleService init has no BriefingService parameter
        // This compiles only if BriefingService is not required for construction
        let service = InsightLifecycleService(
            historicalService: self.mockHistorical,
            functions: nil
        )
        XCTAssertNotNil(service)
    }

    // MARK: - Helpers

    private func seedSnapshots(count: Int, averageScore: Double = 0.6) {
        for i in 0..<count {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let meal = MealBuilder().withScore(averageScore).withItems(["Food \(i)"]).build()
            let snap = DailySmileySnapshotBuilder()
                .withDate(date)
                .withMeals([meal])
                .build()
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snap)
        }
    }
}
