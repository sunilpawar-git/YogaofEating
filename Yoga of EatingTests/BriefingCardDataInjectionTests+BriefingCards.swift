#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Phase 6 (audit) — data-injection tests for the 6 analyzers in PatternAnalysisEngine+BriefingCards.swift
    /// and PatternAnalysisEngine+SynthesisCorrelations.swift that previously had hardcoded observations.
    /// Each test verifies the observation string comes from Strings.swift (SSOT).
    final class BriefingCardDataInjectionTests_BriefingCards: XCTestCase {
        private let analyzer = PatternAnalysisEngine()

        // MARK: - PatternAnalysisEngine+BriefingCards

        func test_foodDebt_observation_matchesStringsSSoT() {
            // Build two consecutive bad-score days so foodDebt fires
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let snaps: [DailySmileySnapshot] = [0, 1, 2].compactMap { daysAgo in
                guard let d = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
                return DailySmileySnapshotBuilder()
                    .withDate(d)
                    .withMeals([MealBuilder().withScore(0.2).analyzed().build()])
                    .build()
            }
            let cards = self.analyzer.analyzeFoodDebt(from: snaps)
            guard let card = cards.first else {
                XCTFail("Expected a foodDebt card")
                return
            }
            XCTAssertEqual(card.observation, Strings.Insight.Cards.foodDebt)
        }

        func test_foodToMood_observation_matchesStringsSSoT() {
            let snaps = SnapshotWeekBuilder()
                .withDayCount(5)
                .withDefaultScore(0.85)
                .withFeeling(.great)
                .build()
            let cards = self.analyzer.analyzeFoodToFeeling(from: snaps)
            guard let card = cards.first else { return }
            XCTAssertEqual(card.observation, Strings.Insight.Cards.foodToMood)
        }

        func test_timingPattern_observation_matchesStringsSSoT() {
            // 5 days each with 2 meals close in time — triggers timing consistency
            let snaps: [DailySmileySnapshot] = (0..<5).map { i in
                let base = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                let m1 = MealBuilder().withScore(0.7).withTimestamp(base.addingTimeInterval(8 * 3600)).analyzed()
                    .build()
                let m2 = MealBuilder().withScore(0.7).withTimestamp(base.addingTimeInterval(12 * 3600)).analyzed()
                    .build()
                return DailySmileySnapshotBuilder()
                    .daysAgo(i)
                    .withMeals([m1, m2])
                    .withReflectData(ReflectData(feeling: .great))
                    .build()
            }
            let cards = self.analyzer.analyzeTimingConsistency(from: snaps)
            guard let card = cards.first else { return }
            XCTAssertEqual(card.observation, Strings.Insight.Cards.timingPattern)
        }

        func test_todoProductivity_observation_matchesStringsSSoT() {
            let done = MindCheckEntryBuilder().withCategory(.todo).accomplished().build()
            let snaps: [DailySmileySnapshot] = (0..<5).map { i in
                DailySmileySnapshotBuilder()
                    .daysAgo(i)
                    .withMeals([MealBuilder().withScore(0.8).analyzed().build()])
                    .withMorningMindCheck([done, done])
                    .build()
            }
            let cards = self.analyzer.analyzeTodoProductivity(from: snaps)
            guard let card = cards.first else { return }
            XCTAssertEqual(card.observation, Strings.Insight.Cards.todoProductivity)
        }

        // MARK: - PatternAnalysisEngine+SynthesisCorrelations

        func test_journalTonePrediction_observation_matchesStringsSSoT() {
            let calendar = Calendar.current
            let snaps: [DailySmileySnapshot] = (0..<5).compactMap { i in
                guard let d = calendar.date(byAdding: .day, value: -i, to: Date()) else { return nil }
                var reflect = ReflectData()
                reflect.textSignals = [.overwhelmed]
                return DailySmileySnapshotBuilder()
                    .withDate(d)
                    .withReflectData(reflect)
                    .build()
            }
            let cards = self.analyzer.analyzeJournalTonePrediction(from: snaps)
            guard let card = cards.first else { return }
            XCTAssertEqual(card.observation, Strings.Insight.Cards.journalTonePrediction)
        }

        func test_sleepMismatch_observation_matchesStringsSSoT() {
            let snaps = SnapshotWeekBuilder()
                .withDayCount(4)
                .withDefaultScore(0.5)
                .withSleepQuality(.great)
                .build()
            let cards = self.analyzer.analyzeSleepMismatch(from: snaps)
            guard let card = cards.first else { return }
            XCTAssertEqual(card.observation, Strings.Insight.Cards.sleepMismatch)
        }
    }

#endif
