#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 4 (audit) architecture-hardening tests.
    final class Phase4ArchitectureTests: XCTestCase {
        private let engine = DailySynthesisEngine()

        // MARK: - T3: hasFeelingData must not fire for an empty textSignals array

        // Red: reflectData?.textSignals != nil passes when textSignals == [],
        // incorrectly marking emotional as "known" with a 0.5 stub score.
        func test_dataCompleteness_excludesEmotional_whenTextSignalsIsEmpty() {
            var reflect = ReflectData()
            reflect.textSignals = [] // non-nil but empty — no real emotional data
            let synthesis = SynthesisInputBuilder()
                .withReflectData(reflect)
                .synthesize(with: self.engine)

            XCTAssertFalse(
                synthesis.dataCompleteness.contains(.emotionalTone),
                "Empty textSignals array must not mark emotional as complete"
            )
        }

        // Companion: non-empty non-neutral signals should still mark emotional as known
        func test_dataCompleteness_includesEmotional_whenTextSignalsIsNonEmpty() {
            var reflect = ReflectData()
            reflect.textSignals = [.stressed]
            let synthesis = SynthesisInputBuilder()
                .withReflectData(reflect)
                .synthesize(with: self.engine)

            XCTAssert(
                synthesis.dataCompleteness.contains(.emotionalTone),
                "Non-empty non-neutral signals must mark emotional as known"
            )
        }

        // MARK: - T2: DailySynthesis.== must survive new fields (synthesized via Equatable)

        func test_dailySynthesis_equality_holdsForIdenticalValues() {
            let a = SynthesisInputBuilder().withMeals(2, avgScore: 0.7).synthesize(with: self.engine)
            let b = SynthesisInputBuilder().withMeals(2, avgScore: 0.7).synthesize(with: self.engine)
            XCTAssertEqual(a, b)
        }

        func test_dailySynthesis_inequality_whenDimensionsDiffer() {
            let a = SynthesisInputBuilder().withMeals(2, avgScore: 0.8).synthesize(with: self.engine)
            let b = SynthesisInputBuilder().withMeals(2, avgScore: 0.2).synthesize(with: self.engine)
            XCTAssertNotEqual(a, b)
        }
    }

#endif
