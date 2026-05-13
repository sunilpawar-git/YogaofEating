#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class InsightLifecycleTests: XCTestCase {
        private var mockHistorical: MockHistoricalDataService!
        private var sut: InsightLifecycleService!

        override func setUp() {
            super.setUp()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = InsightLifecycleService(historicalService: self.mockHistorical)
        }

        override func tearDown() {
            self.sut = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Helpers

        private func goodSynthesis() -> DailySynthesis {
            DailySynthesis(
                dimensions: WellbeingDimensions(
                    physicalLoad: 0.8, emotionalTone: 0.7,
                    cognitiveClarity: 0.75, behavioralMomentum: 0.65
                ),
                textSignals: [.clear, .grateful],
                smileySuggestion: SmileyState(scale: 0.85, mood: .serene),
                dominantDimension: .physicalLoad,
                causalNarrative: "Your food choices are driving today's state."
            )
        }

        private func recentSnapshots(count: Int = 5) -> [DailySmileySnapshot] {
            (0..<count).map { i in
                DailySmileySnapshotBuilder()
                    .daysAgo(i + 1)
                    .withMeals([MealBuilder().withScore(0.7).analyzed().build()])
                    .build()
            }
        }

        // MARK: - Basic generation

        func test_generateEnrichedInsight_returnsNonNil_withValidInput() async {
            let result = await sut.generateEnrichedInsight(
                for: Date(),
                synthesis: self.goodSynthesis(),
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )
            XCTAssertNotNil(result)
        }

        func test_generateEnrichedInsight_returnsNil_withInsufficientSnapshots() async {
            let result = await sut.generateEnrichedInsight(
                for: Date(),
                synthesis: self.goodSynthesis(),
                recentSnapshots: [self.recentSnapshots(count: 1).first!],
                healthKitSleepData: [:]
            )
            XCTAssertNil(result, "Should require at least 2 recent snapshots")
        }

        func test_generateEnrichedInsight_dimensionsMatchSynthesis() async {
            let synthesis = self.goodSynthesis()
            let result = await sut.generateEnrichedInsight(
                for: Date(),
                synthesis: synthesis,
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )
            XCTAssertEqual(result?.dimensions, synthesis.dimensions)
        }

        func test_generateEnrichedInsight_textSignalsFromSynthesis() async {
            let synthesis = self.goodSynthesis()
            let result = await sut.generateEnrichedInsight(
                for: Date(),
                synthesis: synthesis,
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )
            XCTAssertEqual(result?.textSignals, synthesis.textSignals)
        }

        func test_generateEnrichedInsight_causalExplanationIsNonEmpty() async {
            let result = await sut.generateEnrichedInsight(
                for: Date(),
                synthesis: self.goodSynthesis(),
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )
            XCTAssertFalse(result?.causalExplanation.isEmpty ?? true)
        }

        func test_generateEnrichedInsight_headlineIsNonEmpty() async {
            let result = await sut.generateEnrichedInsight(
                for: Date(),
                synthesis: self.goodSynthesis(),
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )
            XCTAssertFalse(result?.headline.isEmpty ?? true)
        }

        func test_generateEnrichedInsight_confidenceInValidRange() async {
            let result = await sut.generateEnrichedInsight(
                for: Date(),
                synthesis: self.goodSynthesis(),
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )
            if let conf = result?.confidence {
                XCTAssertGreaterThanOrEqual(conf, 0.0)
                XCTAssertLessThanOrEqual(conf, 1.0)
            }
        }

        // MARK: - Persistence

        func test_generateEnrichedInsight_callsUpdateEnrichedInsightOnHistoricalService() async {
            _ = await self.sut.generateEnrichedInsight(
                for: Date(),
                synthesis: self.goodSynthesis(),
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )
            XCTAssertTrue(self.mockHistorical.updateEnrichedInsightCalled)
        }

        func test_generateEnrichedInsight_persistsToSnapshotViaHistoricalService() async {
            let today = Date()
            _ = await self.sut.generateEnrichedInsight(
                for: today,
                synthesis: self.goodSynthesis(),
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )
            let snap = self.mockHistorical.historicalData.snapshot(for: today)
            XCTAssertNotNil(snap?.enrichedInsight)
        }

        // MARK: - Legacy fields unaffected

        func test_enrichedInsight_doesNotAffectLegacyInsightField() async {
            let today = Date()
            let legacyInsight = LegacyDailyInsightBuilder().build()
            self.mockHistorical.updateInsight(for: today, insight: legacyInsight)

            _ = await self.sut.generateEnrichedInsight(
                for: today,
                synthesis: self.goodSynthesis(),
                recentSnapshots: self.recentSnapshots(),
                healthKitSleepData: [:]
            )

            let snap = self.mockHistorical.historicalData.snapshot(for: today)
            XCTAssertNotNil(snap?.insight, "Legacy insight should still be readable")
            XCTAssertNotNil(snap?.enrichedInsight, "Enriched insight should now be set too")
        }

        // MARK: - Correlation cards

        func test_generateEnrichedInsight_hasCorrelationCards() async {
            let result = await sut.generateEnrichedInsight(
                for: Date(),
                synthesis: self.goodSynthesis(),
                recentSnapshots: self.recentSnapshots(count: 7),
                healthKitSleepData: [:]
            )
            XCTAssertNotNil(result?.correlationCards)
        }

        // MARK: - Protocol conformance

        func test_serviceConformsToInsightLifecycling() {
            let _: any InsightLifecycling = InsightLifecycleService(historicalService: self.mockHistorical)
        }
    }

#endif
