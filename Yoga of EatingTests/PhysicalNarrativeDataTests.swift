#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 3 TDD: Physical causal narrative must reference meal count and average score.
    /// All tests start RED — they pass once Phase 3 implementation is complete.
    final class PhysicalNarrativeDataTests: XCTestCase {
        private let engine = DailySynthesisEngine()

        func test_physicalNarrative_referencesMealCount() {
            let synthesis = SynthesisInputBuilder().withMeals(3, avgScore: 0.7).synthesize(with: self.engine)
            XCTAssert(
                synthesis.causalNarrative.contains("3"),
                "Physical narrative must reference meal count. Got: \(synthesis.causalNarrative)"
            )
        }

        func test_physicalNarrative_referencesAverageScore() {
            // avgScore 0.65 → should appear as "65%" or "65" in the narrative
            let synthesis = SynthesisInputBuilder().withMeals(2, avgScore: 0.65).synthesize(with: self.engine)
            XCTAssert(
                synthesis.causalNarrative.contains("65"),
                "Physical narrative must reference average score. Got: \(synthesis.causalNarrative)"
            )
        }

        // Regression: privacy — meal item names must not appear in the narrative
        func test_physicalNarrative_doesNotContainRawMealItemText() {
            let synthesis = SynthesisInputBuilder()
                .withMeals([MealBuilder().withItems(["grilled salmon", "salad"]).withScore(0.8).analyzed().build()])
                .synthesize(with: self.engine)
            XCTAssertFalse(
                synthesis.causalNarrative.contains("grilled salmon"),
                "Narrative must not leak raw meal item text"
            )
            XCTAssertFalse(
                synthesis.causalNarrative.contains("salad"),
                "Narrative must not leak raw meal item text"
            )
        }
    }

#endif
