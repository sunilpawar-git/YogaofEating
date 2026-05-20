#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 5 TDD: Dimensions with missing data return nil, not 0.5.
    /// DailySynthesis tracks which dimensions have real data.
    final class DataCompletenessTests: XCTestCase {
        private let engine = DailySynthesisEngine()

        // MARK: - DailySynthesis has dataCompleteness

        // Red: DailySynthesis currently has no dataCompleteness field
        func test_dailySynthesis_hasDataCompletenessField() {
            let synthesis = SynthesisInputBuilder().withMeals(1, avgScore: 0.7).synthesize(with: self.engine)
            // dataCompleteness should be a Set<WellbeingDimension>
            XCTAssertNotNil(synthesis.dataCompleteness)
        }

        // Red: physical is known when meals are present
        func test_dataCompleteness_includesPhysical_whenMealsPresent() {
            let synthesis = SynthesisInputBuilder().withMeals(2, avgScore: 0.8).synthesize(with: self.engine)
            XCTAssert(synthesis.dataCompleteness.contains(.physicalLoad))
        }

        // Red: physical is absent when no meals
        func test_dataCompleteness_excludesPhysical_whenNoMeals() {
            let synthesis = SynthesisInputBuilder().synthesize(with: self.engine)
            XCTAssertFalse(synthesis.dataCompleteness.contains(.physicalLoad))
        }

        // Red: cognitive is known when sleep data present
        func test_dataCompleteness_includesCognitive_whenSleepPresent() {
            let synthesis = SynthesisInputBuilder().withSleepQuality(.great).synthesize(with: self.engine)
            XCTAssert(synthesis.dataCompleteness.contains(.cognitiveClarity))
        }

        // Red: cognitive is absent when no sleep data
        func test_dataCompleteness_excludesCognitive_whenNoSleep() {
            let synthesis = SynthesisInputBuilder().withMeals(1, avgScore: 0.7).synthesize(with: self.engine)
            XCTAssertFalse(synthesis.dataCompleteness.contains(.cognitiveClarity))
        }

        // Red: behavioral is known when todos present
        func test_dataCompleteness_includesBehavioral_whenTodosPresent() {
            let todo = MindCheckEntryBuilder().withCategory(.todo).accomplished().build()
            let synthesis = SynthesisInputBuilder().withTodos([todo]).synthesize(with: self.engine)
            XCTAssert(synthesis.dataCompleteness.contains(.behavioralMomentum))
        }

        // Red: behavioral is absent when no todos
        func test_dataCompleteness_excludesBehavioral_whenNoTodos() {
            let synthesis = SynthesisInputBuilder().withMeals(1, avgScore: 0.7).synthesize(with: self.engine)
            XCTAssertFalse(synthesis.dataCompleteness.contains(.behavioralMomentum))
        }

        // Red: emotional is known when feeling present
        func test_dataCompleteness_includesEmotional_whenFeelingPresent() {
            let synthesis = SynthesisInputBuilder().withFeeling(.great).synthesize(with: self.engine)
            XCTAssert(synthesis.dataCompleteness.contains(.emotionalTone))
        }

        // MARK: - Overall score excludes unknown dimensions

        // Red: DailySynthesis.overall should exclude 0.5 stubs for unknown dimensions
        func test_overall_excludesUnknownDimensions() {
            // Only meals → physical = 0.9; others are unknown
            // synthesis.overall should equal 0.9 (not (0.9+0.5+0.5+0.5)/4 = 0.6)
            let synthesis = SynthesisInputBuilder().withMeals(1, avgScore: 0.9).synthesize(with: self.engine)
            XCTAssertEqual(synthesis.overall, 0.9, accuracy: 0.01)
        }
    }

#endif
