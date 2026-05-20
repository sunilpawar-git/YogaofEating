#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 1 (direction) + Phase 3 (data injection for physical) tests for CausalNarrativeResolver.
    final class CausalNarrativeResolverTests: XCTestCase {
        private let engine = DailySynthesisEngine()

        // MARK: - Physical Load (direction + data — Phase 1 & 3)

        func test_causalNarrative_highPhysical_usesHighVariant() {
            let synthesis = SynthesisInputBuilder().withMeals(2, avgScore: 0.9).synthesize(with: self.engine)
            let expected = String(format: Strings.Synthesis.CausalNarrative.physical_high_fmt, 2, 90)
            XCTAssertEqual(synthesis.causalNarrative, expected)
        }

        func test_causalNarrative_lowPhysical_usesLowVariant() {
            let synthesis = SynthesisInputBuilder().withMeals(2, avgScore: 0.1).synthesize(with: self.engine)
            let expected = String(format: Strings.Synthesis.CausalNarrative.physical_low_fmt, 2, 10)
            XCTAssertEqual(synthesis.causalNarrative, expected)
        }

        func test_causalNarrative_neutralPhysical_usesNeutralVariant() {
            let synthesis = SynthesisInputBuilder().withMeals(1, avgScore: 0.5).synthesize(with: self.engine)
            let expected = String(format: Strings.Synthesis.CausalNarrative.physical_neutral_fmt, 1, 50)
            XCTAssertEqual(synthesis.causalNarrative, expected)
        }

        // MARK: - Behavioral Momentum

        func test_causalNarrative_highBehavioralMomentum_usesHighVariant() {
            let todos = [
                MindCheckEntryBuilder().withCategory(.todo).accomplished().build(),
                MindCheckEntryBuilder().withCategory(.todo).accomplished().build()
            ]
            let synthesis = SynthesisInputBuilder().withTodos(todos).synthesize(with: self.engine)
            XCTAssertEqual(synthesis.causalNarrative, Strings.Synthesis.CausalNarrative.behavioral_high)
        }

        func test_causalNarrative_lowBehavioralMomentum_usesLowVariant() {
            let todos = [
                MindCheckEntryBuilder().withCategory(.todo).build(),
                MindCheckEntryBuilder().withCategory(.todo).build()
            ]
            let synthesis = SynthesisInputBuilder().withTodos(todos).synthesize(with: self.engine)
            XCTAssertEqual(synthesis.causalNarrative, Strings.Synthesis.CausalNarrative.behavioral_low)
        }

        // MARK: - Emotional Tone

        func test_causalNarrative_highEmotionalTone_usesHighVariant() {
            let synthesis = SynthesisInputBuilder().withFeeling(.great).synthesize(with: self.engine)
            XCTAssertEqual(synthesis.causalNarrative, Strings.Synthesis.CausalNarrative.emotional_high)
        }

        func test_causalNarrative_lowEmotionalTone_usesLowVariant() {
            let synthesis = SynthesisInputBuilder().withFeeling(.heavy).synthesize(with: self.engine)
            XCTAssertEqual(synthesis.causalNarrative, Strings.Synthesis.CausalNarrative.emotional_low)
        }

        // MARK: - Cognitive Clarity

        func test_causalNarrative_highCognitiveClarity_usesHighVariant() {
            let synthesis = SynthesisInputBuilder().withSleepQuality(.great).synthesize(with: self.engine)
            XCTAssertEqual(synthesis.causalNarrative, Strings.Synthesis.CausalNarrative.cognitive_high)
        }

        func test_causalNarrative_lowCognitiveClarity_usesLowVariant() {
            let synthesis = SynthesisInputBuilder().withSleepQuality(.poor).synthesize(with: self.engine)
            XCTAssertEqual(synthesis.causalNarrative, Strings.Synthesis.CausalNarrative.cognitive_low)
        }
    }

#endif
