#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 2 TDD: Correlation card observations must reference actual data values, not boilerplate.
    /// All tests start RED — they pass once Phase 2 implementation is complete.
    final class BriefingCardDataInjectionTests: XCTestCase {
        private let analyzer = PatternAnalysisEngine()

        // MARK: - Intention Followthrough

        // Red: current observation is boilerplate — no completion rate.
        func test_intentionFollowthrough_observation_containsCompletionRate() {
            let done = MindCheckEntryBuilder().withCategory(.todo).accomplished().build()
            let notDone = MindCheckEntryBuilder().withCategory(.todo).build()
            // 1 of 4 done = 25%
            let snapshots = SnapshotWeekBuilder()
                .withDefaultScore(0.4)
                .withTodosPerDay([done, notDone, notDone, notDone])
                .build()
            let cards = self.analyzer.analyzeIntentionFollowthrough(from: snapshots)
            guard let card = cards.first else {
                XCTFail("Expected an intention-followthrough card")
                return
            }
            XCTAssert(
                card.observation.contains("25%") || card.observation.contains("1 of 4"),
                "Observation must reference completion rate. Got: \(card.observation)"
            )
        }

        // Red: current observation is boilerplate — no day count.
        func test_intentionFollowthrough_observation_containsDayCount() {
            let notDone = MindCheckEntryBuilder().withCategory(.todo).build()
            let snapshots = SnapshotWeekBuilder()
                .withDefaultScore(0.4)
                .withTodosPerDay([notDone, notDone])
                .build()
            let cards = self.analyzer.analyzeIntentionFollowthrough(from: snapshots)
            guard let card = cards.first else { return }
            XCTAssert(
                card.observation.contains("7") || card.observation.contains("days"),
                "Observation must reference affected day count. Got: \(card.observation)"
            )
        }

        // MARK: - Sleep Recovery Carryover

        // Red: current observation uses the word "Two" — no numeric digit.
        // After Phase 2, observation must contain a numeric count of consecutive nights.
        func test_sleepRecoveryCarryover_observation_containsNumericNightCount() {
            let snapshots = SnapshotWeekBuilder()
                .withDayCount(3)
                .withDefaultScore(0.5)
                .withSleepQuality(.poor)
                .build()
            let cards = self.analyzer.analyzeSleepRecoveryCarryover(from: snapshots)
            guard let card = cards.first else {
                XCTFail("Expected a sleep-recovery card")
                return
            }
            // "Two consecutive..." has no digit → fails Red; "2 nights..." passes Green
            XCTAssert(
                card.observation.contains(where: \.isNumber),
                "Observation must contain a numeric digit for the night count. Got: \(card.observation)"
            )
        }

        // MARK: - Carry-Over Load (regression — already uses interpolation)

        func test_carryOverLoad_observation_containsLowDayCount() {
            let snapshots = SnapshotWeekBuilder()
                .withDayCount(5)
                .withDefaultScore(0.2)
                .build()
            let cards = self.analyzer.analyzeCarryOverLoad(from: snapshots)
            guard let card = cards.first else {
                XCTFail("Expected a carry-over-load card")
                return
            }
            XCTAssert(
                card.observation.contains("5"),
                "Observation must reference the number of low-wellbeing days. Got: \(card.observation)"
            )
        }
    }

#endif
