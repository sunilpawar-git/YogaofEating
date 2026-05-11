#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class PatternAnalysisEnrichmentTests: XCTestCase {
        private let engine = PatternAnalysisEngine()
        private let calendar = Calendar.current

        // MARK: - Helpers

        private func snapshot(
            daysAgo: Int,
            sleepQuality: SleepQuality? = nil,
            todos: [MindCheckEntry] = [],
            textSignals: [TextSignal]? = nil,
            wellbeingDimensions: WellbeingDimensions? = nil,
            avgScore: Double = 0.5,
            mealCount: Int = 1
        ) -> DailySmileySnapshot {
            let date = self.calendar.date(byAdding: .day, value: -daysAgo, to: self.calendar.startOfDay(for: Date()))!
            var highlight = HighlightData(todos: todos)
            highlight.sleepQuality = sleepQuality
            var reflect = ReflectData()
            reflect.textSignals = textSignals
            return DailySmileySnapshotBuilder()
                .withDate(date)
                .withMeals(
                    mealCount > 0
                        ? (1...mealCount).map { _ in MealBuilder().withScore(avgScore).build() }
                        : []
                )
                .withHighlightData(highlight)
                .withReflectData(reflect)
                .withWellbeingDimensions(wellbeingDimensions ?? WellbeingDimensions(
                    physicalLoad: avgScore,
                    emotionalTone: 0.5,
                    cognitiveClarity: 0.5,
                    behavioralMomentum: 0.5
                ))
                .withTextSignals(textSignals ?? [.neutral])
                .build()
        }

        // MARK: - 1. Sleep Recovery Carryover

        func test_sleepRecoveryCarryover_fires_whenTwoConsecutivePoorSleepNights() {
            let snaps = [
                snapshot(daysAgo: 1, sleepQuality: .poor),
                snapshot(daysAgo: 2, sleepQuality: .poor),
                snapshot(daysAgo: 3, sleepQuality: .great)
            ]
            let cards = self.engine.analyzeSleepRecoveryCarryover(from: snaps)
            XCTAssertFalse(cards.isEmpty, "Should detect two consecutive poor-sleep nights")
            XCTAssertEqual(cards.first?.category, .sleepRecoveryCarryover)
        }

        func test_sleepRecoveryCarryover_doesNotFire_whenOnlyOnePoorNight() {
            let snaps = [
                snapshot(daysAgo: 1, sleepQuality: .poor),
                snapshot(daysAgo: 2, sleepQuality: .great)
            ]
            let cards = self.engine.analyzeSleepRecoveryCarryover(from: snaps)
            XCTAssertTrue(cards.isEmpty)
        }

        func test_sleepRecoveryCarryover_doesNotFire_whenNoSleepData() {
            let snaps = [
                snapshot(daysAgo: 1),
                snapshot(daysAgo: 2)
            ]
            let cards = self.engine.analyzeSleepRecoveryCarryover(from: snaps)
            XCTAssertTrue(cards.isEmpty)
        }

        func test_sleepRecoveryCarryover_confidence_isValidRange() {
            let snaps = [
                snapshot(daysAgo: 1, sleepQuality: .terrible),
                snapshot(daysAgo: 2, sleepQuality: .terrible)
            ]
            let cards = self.engine.analyzeSleepRecoveryCarryover(from: snaps)
            if let card = cards.first {
                XCTAssertGreaterThanOrEqual(card.confidence, 0.0)
                XCTAssertLessThanOrEqual(card.confidence, 1.0)
            }
        }

        // MARK: - 2. Intention-Followthrough Gap

        func test_intentionFollowthrough_fires_whenCompletionRateLow() {
            let todos = (1...4).map { i in
                MindCheckEntryBuilder()
                    .withCategory(.todo)
                    .withText("Task \(i)")
                    .build()
            }
            let snaps = [snapshot(daysAgo: 1, todos: todos)]
            let cards = self.engine.analyzeIntentionFollowthrough(from: snaps)
            XCTAssertFalse(cards.isEmpty, "Should detect low followthrough with 0% completion")
            XCTAssertEqual(cards.first?.category, .intentionFollowthrough)
        }

        func test_intentionFollowthrough_doesNotFire_whenCompletionRateHigh() {
            let todos = (1...3).map { i in
                MindCheckEntryBuilder()
                    .withCategory(.todo)
                    .withText("Task \(i)")
                    .accomplished()
                    .build()
            }
            let snaps = [snapshot(daysAgo: 1, todos: todos)]
            let cards = self.engine.analyzeIntentionFollowthrough(from: snaps)
            XCTAssertTrue(cards.isEmpty, "Should not fire when todos are accomplished")
        }

        func test_intentionFollowthrough_doesNotFire_withFewerThanMinTodos() {
            let todos = [MindCheckEntryBuilder().withCategory(.todo).build()]
            let snaps = [snapshot(daysAgo: 1, todos: todos)]
            let cards = self.engine.analyzeIntentionFollowthrough(from: snaps)
            XCTAssertTrue(cards.isEmpty, "Should not fire with only 1 todo")
        }

        func test_intentionFollowthrough_confidence_isValidRange() {
            let todos = (1...5).map { i in MindCheckEntryBuilder().withCategory(.todo).withText("T\(i)").build() }
            let snaps = (1...3).map { self.snapshot(daysAgo: $0, todos: todos) }
            let cards = self.engine.analyzeIntentionFollowthrough(from: snaps)
            for card in cards {
                XCTAssertGreaterThanOrEqual(card.confidence, 0.0)
                XCTAssertLessThanOrEqual(card.confidence, 1.0)
            }
        }

        // MARK: - 3. Journal Tone → Next-Day Wellbeing Prediction

        func test_journalTonePrediction_fires_whenOverwhelmedPrecedesLowWellbeing() {
            let lowDimensions = WellbeingDimensions(
                physicalLoad: 0.4, emotionalTone: 0.3, cognitiveClarity: 0.35, behavioralMomentum: 0.4
            )
            let snaps = [
                snapshot(daysAgo: 0, wellbeingDimensions: lowDimensions), // today: low wellbeing
                snapshot(daysAgo: 1, textSignals: [.overwhelmed]) // yesterday: overwhelmed
            ]
            let cards = self.engine.analyzeJournalTonePrediction(from: snaps)
            XCTAssertFalse(cards.isEmpty, "Should detect overwhelmed evening preceding low wellbeing")
            XCTAssertEqual(cards.first?.category, .journalTonePrediction)
        }

        func test_journalTonePrediction_doesNotFire_whenToneIsPositive() {
            let snaps = [
                snapshot(daysAgo: 0),
                snapshot(daysAgo: 1, textSignals: [.grateful])
            ]
            let cards = self.engine.analyzeJournalTonePrediction(from: snaps)
            XCTAssertTrue(cards.isEmpty, "Should not fire for positive journal tone")
        }

        func test_journalTonePrediction_doesNotFire_withInsufficientData() {
            let snaps = [snapshot(daysAgo: 1, textSignals: [.overwhelmed])]
            let cards = self.engine.analyzeJournalTonePrediction(from: snaps)
            XCTAssertTrue(cards.isEmpty, "Need at least 2 days for lag detection")
        }

        // MARK: - 4. Subjective vs Objective Sleep Mismatch

        func test_sleepMismatch_fires_whenGreatSleepRatingButLowClarityDimension() {
            let lowClarityDimensions = WellbeingDimensions(
                physicalLoad: 0.7, emotionalTone: 0.6, cognitiveClarity: 0.3, behavioralMomentum: 0.6
            )
            let snaps = (1...3).map { daysAgo in
                self.snapshot(daysAgo: daysAgo, sleepQuality: .great, wellbeingDimensions: lowClarityDimensions)
            }
            let cards = self.engine.analyzeSleepMismatch(from: snaps)
            XCTAssertFalse(cards.isEmpty, "Should detect great rating but low cognitive clarity")
            XCTAssertEqual(cards.first?.category, .sleepMismatch)
        }

        func test_sleepMismatch_doesNotFire_whenSleepRatingMatchesCognition() {
            let goodDimensions = WellbeingDimensions(
                physicalLoad: 0.7, emotionalTone: 0.6, cognitiveClarity: 0.8, behavioralMomentum: 0.6
            )
            let snaps = [snapshot(daysAgo: 1, sleepQuality: .great, wellbeingDimensions: goodDimensions)]
            let cards = self.engine.analyzeSleepMismatch(from: snaps)
            XCTAssertTrue(cards.isEmpty)
        }

        func test_sleepMismatch_doesNotFire_whenNoSleepRatingPresent() {
            let lowDimensions = WellbeingDimensions(
                physicalLoad: 0.5, emotionalTone: 0.5, cognitiveClarity: 0.2, behavioralMomentum: 0.5
            )
            let snaps = [snapshot(daysAgo: 1, sleepQuality: nil, wellbeingDimensions: lowDimensions)]
            let cards = self.engine.analyzeSleepMismatch(from: snaps)
            XCTAssertTrue(cards.isEmpty)
        }

        // MARK: - 5. Carry-Over Load

        func test_carryOverLoad_fires_whenThreePlusLowWellbeingDays() {
            let lowDimensions = WellbeingDimensions(
                physicalLoad: 0.3, emotionalTone: 0.3, cognitiveClarity: 0.3, behavioralMomentum: 0.3
            )
            let snaps = (1...5).map { self.snapshot(daysAgo: $0, wellbeingDimensions: lowDimensions) }
            let cards = self.engine.analyzeCarryOverLoad(from: snaps)
            XCTAssertFalse(cards.isEmpty, "Should detect 5 consecutive low-wellbeing days")
            XCTAssertEqual(cards.first?.category, .carryOverLoad)
        }

        func test_carryOverLoad_doesNotFire_withFewerThanThreeLowDays() {
            let lowDimensions = WellbeingDimensions(
                physicalLoad: 0.3, emotionalTone: 0.3, cognitiveClarity: 0.3, behavioralMomentum: 0.3
            )
            let snaps = [
                snapshot(daysAgo: 1, wellbeingDimensions: lowDimensions),
                snapshot(daysAgo: 2, wellbeingDimensions: lowDimensions),
                snapshot(daysAgo: 3) // this one has normal wellbeing
            ]
            let cards = self.engine.analyzeCarryOverLoad(from: snaps)
            XCTAssertTrue(cards.isEmpty)
        }

        func test_carryOverLoad_fallsBackToAvgScore_whenNoDimensionsPresent() {
            let snaps = (1...4).map { self.snapshot(daysAgo: $0, avgScore: 0.3, mealCount: 2) }
                .map { snap in
                    // Create snapshot without wellbeingDimensions
                    DailySmileySnapshot(
                        id: snap.id, date: snap.date, smileyState: snap.smileyState,
                        meals: snap.meals, mealCount: snap.mealCount,
                        averageHealthScore: snap.averageHealthScore,
                        wellbeingDimensions: nil
                    )
                }
            let cards = self.engine.analyzeCarryOverLoad(from: snaps)
            XCTAssertFalse(cards.isEmpty, "Should use avgScore as fallback when dimensions not set")
        }

        func test_carryOverLoad_confidence_isValidRange() {
            let lowDimensions = WellbeingDimensions(
                physicalLoad: 0.2, emotionalTone: 0.2, cognitiveClarity: 0.2, behavioralMomentum: 0.2
            )
            let snaps = (1...5).map { self.snapshot(daysAgo: $0, wellbeingDimensions: lowDimensions) }
            let cards = self.engine.analyzeCarryOverLoad(from: snaps)
            for card in cards {
                XCTAssertGreaterThanOrEqual(card.confidence, 0.0)
                XCTAssertLessThanOrEqual(card.confidence, 1.0)
            }
        }

        // MARK: - GenerateCorrelationCards includes new correlations

        func test_generateCorrelationCards_includesNewCorrelations() {
            let lowDimensions = WellbeingDimensions(
                physicalLoad: 0.3, emotionalTone: 0.3, cognitiveClarity: 0.3, behavioralMomentum: 0.3
            )
            let snaps = (1...5).map { self.snapshot(daysAgo: $0, wellbeingDimensions: lowDimensions) }
            let cards = self.engine.generateCorrelationCards(from: snaps)
            // At least carryOverLoad should appear
            XCTAssertTrue(
                cards.contains(where: { $0.category == .carryOverLoad }),
                "generateCorrelationCards should include carryOverLoad"
            )
        }
    }

#endif
