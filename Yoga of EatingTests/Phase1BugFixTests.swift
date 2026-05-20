#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 1 (audit) bug-fix regression guards.
    /// Each test was written RED against the buggy production code.
    @MainActor
    final class Phase1BugFixTests: XCTestCase {
        private let engine = DailySynthesisEngine()
        private var sut: InsightLifecycleService!
        private var mock: MockHistoricalDataService!

        override func setUp() {
            super.setUp()
            self.mock = MockHistoricalDataService()
            self.sut = InsightLifecycleService(historicalService: self.mock, functions: nil)
        }

        override func tearDown() {
            self.sut = nil
            self.mock = nil
            super.tearDown()
        }

        // MARK: - B1: buildLocalInsight must use synthesis.overall (data-aware), not synthesis.dimensions.overall

        // When only meals are known (physicalLoad = 0.85, all others = 0.5 stubs):
        //   synthesis.dimensions.overall  ≈ (0.85 + 0.5 + 0.5 + 0.5) / 4 = 0.5875  → headlineSteady
        //   synthesis.overall (data-aware) = 0.85                                    → headlineStrong
        // The data-aware value is correct; the unweighted one drags the headline down.
        func test_buildLocalInsight_usesDataAwareOverall_forHeadline() {
            let synthesis = DailySynthesis(
                dimensions: WellbeingDimensions(
                    physicalLoad: 0.85,
                    emotionalTone: 0.5,
                    cognitiveClarity: 0.5,
                    behavioralMomentum: 0.5
                ),
                dataCompleteness: [.physicalLoad],
                textSignals: [.neutral],
                smileySuggestion: SmileyState(scale: 0.9, mood: .serene),
                dominantDimension: .physicalLoad,
                causalNarrative: "Test"
            )
            let snapshots = (0..<5).map { i in
                DailySmileySnapshotBuilder()
                    .daysAgo(i)
                    .withMeals([MealBuilder().withScore(0.85).analyzed().build()])
                    .build()
            }

            let insight = self.sut.buildLocalInsight(date: Date(), synthesis: synthesis, recentSnapshots: snapshots)

            XCTAssertEqual(
                insight.headline,
                Strings.EnrichedInsight.headlineStrong,
                "buildLocalInsight must use synthesis.overall (0.85 > 0.65 threshold), not synthesis.dimensions.overall (~0.59)"
            )
        }

        // MARK: - B2: computeConfidence must use dataCompleteness, not !=(0.5) equality

        // A physicalLoad score of exactly 0.5 can be real data (a borderline meal day).
        // The old `!= 0.5` guard silently drops the confidence bonus for that case.
        func test_computeConfidence_earnsBonusForKnownDimension_whenScoreIsExactlyHalf() {
            let synthesis = DailySynthesis(
                dimensions: WellbeingDimensions(
                    physicalLoad: 0.5,
                    emotionalTone: 0.5,
                    cognitiveClarity: 0.5,
                    behavioralMomentum: 0.5
                ),
                dataCompleteness: [.physicalLoad, .cognitiveClarity],
                textSignals: [.clear, .grateful],
                smileySuggestion: SmileyState.neutral,
                dominantDimension: .physicalLoad,
                causalNarrative: "Test"
            )
            let snapshots = (0..<5).map { i in DailySmileySnapshotBuilder().daysAgo(i).build() }

            let confidence = self.sut.computeConfidence(synthesis: synthesis, snapshots: snapshots)

            // dataCompleteness-aware: 0.4 + 0.2 (5 snaps) + 0.2 (non-neutral signals) + 0.1 (physical) + 0.1 (cognitive) = 1.0
            // != 0.5 guard:           0.4 + 0.2 + 0.2 + 0 + 0 = 0.8  ← missing bonuses
            XCTAssertGreaterThan(
                confidence, 0.9,
                "computeConfidence must use dataCompleteness.contains(), not dimension != 0.5"
            )
        }

        // MARK: - B3: no-data synthesis must not produce "0 meals at X%" narrative

        // When the engine runs with no input (no meals, sleep, feeling, or todos),
        // the dominantDimension fallback is .physicalLoad with mealCount=0.
        // The physical format string then produces "0 meals at 50%..." which is misleading.
        func test_synthesis_noData_causalNarrativeDoesNotReferenceZeroMeals() {
            let synthesis = SynthesisInputBuilder().synthesize(with: self.engine)

            XCTAssertFalse(
                synthesis.causalNarrative.contains("0 meals"),
                "No-data narrative must not say '0 meals'. Got: \(synthesis.causalNarrative)"
            )
        }

        func test_synthesis_noData_causalNarrativeIsNotEmpty() {
            let synthesis = SynthesisInputBuilder().synthesize(with: self.engine)
            XCTAssertFalse(synthesis.causalNarrative.isEmpty)
        }
    }

#endif
