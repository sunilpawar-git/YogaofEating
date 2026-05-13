#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class InsightLifecycleIntegrationTests: XCTestCase {
        private var mockHistorical: MockHistoricalDataService!
        private var sut: MainViewModel!

        override func setUp() {
            super.setUp()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = MainViewModel(
                historicalService: self.mockHistorical,
                skipDataLoading: true
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - EnrichedDailyInsight Codable backward compatibility

        func test_enrichedInsight_isNil_byDefault_onLegacySnapshot() throws {
            let snap = DailySmileySnapshotBuilder().build()
            let data = try JSONEncoder().encode(snap)
            let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: data)
            XCTAssertNil(decoded.enrichedInsight)
        }

        func test_enrichedInsight_codableRoundTrip() throws {
            let enriched = DailyInsight(
                date: Date(),
                headline: "Great day ahead",
                dimensions: .neutral,
                dominantInsight: "Your food is driving today.",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "Keep going", reasoning: "Positive trend"),
                weeklyTrend: nil,
                causalExplanation: "Physical load is the dominant factor.",
                textSignals: [.grateful, .clear],
                confidence: 0.82
            )
            let snap = DailySmileySnapshotBuilder()
                .withEnrichedInsight(enriched)
                .build()

            let data = try JSONEncoder().encode(snap)
            let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: data)

            let decodedInsight = try XCTUnwrap(decoded.enrichedInsight)
            XCTAssertEqual(decodedInsight.headline, "Great day ahead")
            XCTAssertEqual(decodedInsight.textSignals, [.grateful, .clear])
            XCTAssertEqual(decodedInsight.confidence, 0.82, accuracy: 0.001)
        }

        func test_legacyJSONWithoutEnrichedInsight_decodesSuccessfully() throws {
            let json = """
            {
                "id": "12345678-1234-1234-1234-123456789012",
                "date": 0,
                "smileyState": {"scale": 1.0, "mood": "neutral"},
                "meals": [],
                "mealCount": 0,
                "averageHealthScore": 0.5
            }
            """.data(using: .utf8)!

            let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: json)
            XCTAssertNil(decoded.enrichedInsight)
        }

        // MARK: - Legacy fields coexist with enriched insight

        func test_snapshot_canHoldBothLegacyAndEnrichedInsight() throws {
            let legacyInsight = LegacyDailyInsightBuilder().build()
            let enriched = DailyInsight(
                date: Date(),
                headline: "Enriched headline",
                dimensions: .neutral,
                dominantInsight: "Physical.",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "Test", reasoning: "Test"),
                weeklyTrend: nil,
                causalExplanation: "Test explanation",
                textSignals: [.neutral],
                confidence: 0.7
            )

            let snap = DailySmileySnapshotBuilder()
                .withInsight(legacyInsight)
                .withEnrichedInsight(enriched)
                .build()

            XCTAssertNotNil(snap.insight)
            XCTAssertNotNil(snap.enrichedInsight)
            XCTAssertEqual(snap.insight?.insightText, legacyInsight.insightText)
            XCTAssertEqual(snap.enrichedInsight?.headline, "Enriched headline")
        }

        // MARK: - Historical service update

        func test_updateEnrichedInsight_storesInSnapshot() {
            let today = Date()
            let enriched = DailyInsight(
                date: today,
                headline: "Test headline",
                dimensions: .neutral,
                dominantInsight: "Test.",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "Go", reasoning: "Because"),
                weeklyTrend: nil,
                causalExplanation: "Explanation",
                textSignals: [.clear],
                confidence: 0.75
            )

            self.mockHistorical.updateEnrichedInsight(for: today, insight: enriched)

            let snap = self.mockHistorical.historicalData.snapshot(for: today)
            XCTAssertNotNil(snap?.enrichedInsight)
            XCTAssertEqual(snap?.enrichedInsight?.headline, "Test headline")
        }

        func test_updateEnrichedInsight_preservesExistingFields() {
            let today = Date()
            let legacyInsight = LegacyDailyInsightBuilder().build()
            self.mockHistorical.updateInsight(for: today, insight: legacyInsight)

            let enriched = DailyInsight(
                date: today,
                headline: "Enriched",
                dimensions: .neutral,
                dominantInsight: "Physical.",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "Go", reasoning: "Because"),
                weeklyTrend: nil,
                causalExplanation: "Explanation",
                textSignals: [.neutral],
                confidence: 0.7
            )
            self.mockHistorical.updateEnrichedInsight(for: today, insight: enriched)

            let snap = self.mockHistorical.historicalData.snapshot(for: today)
            XCTAssertNotNil(snap?.insight, "Legacy insight should be preserved")
            XCTAssertNotNil(snap?.enrichedInsight, "Enriched insight should be set")
        }
    }

#endif
