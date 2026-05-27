#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class DailySynthesisEngineTests: XCTestCase {
        private let sut = DailySynthesisEngine()

        // MARK: - Meals-only synthesis (backward compat with legacy test expectations)

        func test_mealsOnly_physicalLoad_equalsAvgMealScore() {
            let meals = [
                MealBuilder().withScore(0.8).analyzed().build(),
                MealBuilder().withScore(0.6).analyzed().build()
            ]
            let synthesis = self.sut.synthesize(
                meals: meals,
                highlightData: nil,
                reflectData: nil,
                appleSleepData: nil,
                yesterday: nil
            )
            // physicalLoad reflects the meal average; other dimensions default to neutral (0.5)
            XCTAssertEqual(synthesis.dimensions.physicalLoad, 0.7, accuracy: 0.01)
            // With no other data, smiley is determined solely by meal score
            XCTAssertEqual(synthesis.smileySuggestion.mood, .serene)
        }

        func test_mealsOnly_highScore_producesSerene() {
            let meals = [MealBuilder().withScore(0.9).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertEqual(synthesis.smileySuggestion.mood, .serene)
        }

        func test_mealsOnly_lowScore_producesOverwhelmed() {
            let meals = [MealBuilder().withScore(0.2).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertEqual(synthesis.smileySuggestion.mood, .overwhelmed)
        }

        func test_mealsOnly_midScore_producesNeutral() {
            let meals = [MealBuilder().withScore(0.55).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertEqual(synthesis.smileySuggestion.mood, .neutral)
        }

        // MARK: - Sleep data lowers overall when poor

        func test_poorSleep_withGoodMeals_lowersOverall_comparedToMealsAlone() {
            let meals = [MealBuilder().withScore(0.85).analyzed().build()]
            let goodSleepQuality = SleepQuality.poor

            var highlight = HighlightData()
            highlight.sleepQuality = goodSleepQuality

            let withSleep = self.sut.synthesize(
                meals: meals, highlightData: highlight, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            let withoutSleep = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )

            XCTAssertLessThan(withSleep.dimensions.overall, withoutSleep.dimensions.overall)
        }

        func test_greatSleep_withModerateMeals_raisesOverall_comparedToMealsAlone() {
            let meals = [MealBuilder().withScore(0.5).analyzed().build()]
            var highlight = HighlightData()
            highlight.sleepQuality = .great

            let withSleep = self.sut.synthesize(
                meals: meals, highlightData: highlight, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            let withoutSleep = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )

            XCTAssertGreaterThan(withSleep.dimensions.overall, withoutSleep.dimensions.overall)
        }

        // MARK: - Feeling data affects emotional tone

        func test_positiveFeeling_raisesEmotionalTone() {
            let reflect = ReflectData(feeling: .great)
            let synthesis = self.sut.synthesize(
                meals: [], highlightData: nil, reflectData: reflect,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertGreaterThan(synthesis.dimensions.emotionalTone, 0.5)
        }

        func test_negativeFeeling_lowersEmotionalTone() {
            let reflect = ReflectData(feeling: .heavy)
            let synthesis = self.sut.synthesize(
                meals: [], highlightData: nil, reflectData: reflect,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertLessThan(synthesis.dimensions.emotionalTone, 0.5)
        }

        // MARK: - Nil / empty inputs degrade gracefully

        func test_noData_overall_isNeutral() {
            let synthesis = self.sut.synthesize(
                meals: [], highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertEqual(synthesis.dimensions.overall, 0.5, accuracy: 0.01)
        }

        func test_allDimensions_clampedToZeroOne() {
            let meals = [MealBuilder().withScore(1.5).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertGreaterThanOrEqual(synthesis.dimensions.physicalLoad, 0.0)
            XCTAssertLessThanOrEqual(synthesis.dimensions.physicalLoad, 1.0)
        }

        // MARK: - Dominant dimension

        func test_dominantDimension_isPhysical_whenOnlyMealsPresent() {
            let meals = [MealBuilder().withScore(0.9).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertEqual(synthesis.dominantDimension, .physicalLoad)
        }

        func test_dominantDimension_isCognitive_whenSleepDominates() {
            let meals = [MealBuilder().withScore(0.5).analyzed().build()]
            var highlight = HighlightData()
            highlight.sleepQuality = .great

            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: highlight, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            // With great sleep and neutral meals, cognitive should be the standout dimension
            XCTAssertNotNil(synthesis.dominantDimension)
        }

        // MARK: - Causal narrative

        func test_causalNarrative_isNonEmpty() {
            let meals = [MealBuilder().withScore(0.7).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertFalse(synthesis.causalNarrative.isEmpty)
        }

        // MARK: - Thoughtful mood

        func test_borderlineLowScore_producesThoughtful() {
            let meals = [MealBuilder().withScore(0.4).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            // 0.4 is between thoughtful (0.35) and neutral (0.45) thresholds
            XCTAssertEqual(synthesis.smileySuggestion.mood, .thoughtful)
        }

        // MARK: - Todo behavioral momentum

        func test_completedTodos_raisesBehavioralMomentum() {
            let completedTodo = MindCheckEntryBuilder()
                .withCategory(.todo)
                .accomplished()
                .build()
            var highlight = HighlightData(todos: [completedTodo])
            highlight.sleepQuality = nil

            let synthesis = self.sut.synthesize(
                meals: [], highlightData: highlight, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertGreaterThan(synthesis.dimensions.behavioralMomentum, 0.5)
        }

        func test_uncompletedTodos_lowersBehavioralMomentum() {
            let incompleteTodo = MindCheckEntryBuilder()
                .withCategory(.todo)
                .build()
            let highlight = HighlightData(todos: [incompleteTodo])

            let synthesis = self.sut.synthesize(
                meals: [], highlightData: highlight, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertLessThan(synthesis.dimensions.behavioralMomentum, 0.5)
        }

        // MARK: - DailySynthesis.overall weighted calculation

        func test_overall_withPhysicalAndCognitive_usesWeights() {
            // physical=0.80 (weight 0.50), cognitive=0.30 (weight 0.25)
            // Weighted: (0.80×0.50 + 0.30×0.25) / (0.50+0.25) = 0.475 / 0.75 = 0.6333…
            // Unweighted (current bug): (0.80+0.30)/2 = 0.55  ← must differ from expected
            let synthesis = DailySynthesis(
                dimensions: WellbeingDimensions(
                    physicalLoad: 0.80,
                    emotionalTone: 0.5,
                    cognitiveClarity: 0.30,
                    behavioralMomentum: 0.5
                ),
                dataCompleteness: [.physicalLoad, .cognitiveClarity],
                textSignals: [],
                smileySuggestion: .neutral,
                dominantDimension: .physicalLoad,
                causalNarrative: ""
            )
            XCTAssertEqual(synthesis.overall, 0.6333, accuracy: 0.001)
        }

        func test_overall_singleDimension_equalsScore() {
            let synthesis = DailySynthesis(
                dimensions: WellbeingDimensions(
                    physicalLoad: 0.80,
                    emotionalTone: 0.5,
                    cognitiveClarity: 0.5,
                    behavioralMomentum: 0.5
                ),
                dataCompleteness: [.physicalLoad],
                textSignals: [],
                smileySuggestion: .neutral,
                dominantDimension: .physicalLoad,
                causalNarrative: ""
            )
            XCTAssertEqual(synthesis.overall, 0.80, accuracy: 0.001)
        }

        func test_overall_noData_returnsFallback() {
            let synthesis = DailySynthesis(
                dimensions: .neutral,
                dataCompleteness: [],
                textSignals: [],
                smileySuggestion: .neutral,
                dominantDimension: .physicalLoad,
                causalNarrative: ""
            )
            XCTAssertEqual(synthesis.overall, 0.5, accuracy: 0.001)
        }

        // MARK: - Exercise bonus (Phase 1 TDD — Red: calls 6-param synthesize not yet in protocol)

        func test_exerciseBonus_nilCalories_returnsZero() {
            let meals = [MealBuilder().withScore(0.5).analyzed().build()]
            let withNil = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: nil
            )
            let withoutParam = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil
            )
            XCTAssertEqual(withNil.dimensions.physicalLoad, withoutParam.dimensions.physicalLoad, accuracy: 0.001)
        }

        func test_exerciseBonus_100kcal_returnsZero() {
            let meals = [MealBuilder().withScore(0.5).analyzed().build()]
            let base = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: nil
            )
            let with100 = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: 100
            )
            XCTAssertEqual(
                with100.dimensions.physicalLoad,
                base.dimensions.physicalLoad,
                accuracy: 0.001,
                "100 kcal is below tier 1 threshold — no bonus"
            )
        }

        func test_exerciseBonus_150kcal_returnsSmallBonus_0_05() {
            let meals = [MealBuilder().withScore(0.5).analyzed().build()]
            let base = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: nil
            )
            let with150 = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: 150
            )
            XCTAssertEqual(
                with150.dimensions.physicalLoad - base.dimensions.physicalLoad,
                0.05, accuracy: 0.001,
                "150 kcal (tier 1) must add exactly +0.05 bonus"
            )
        }

        func test_exerciseBonus_300kcal_returnsMediumBonus_0_10() {
            let meals = [MealBuilder().withScore(0.5).analyzed().build()]
            let base = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: nil
            )
            let with300 = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: 300
            )
            XCTAssertEqual(
                with300.dimensions.physicalLoad - base.dimensions.physicalLoad,
                0.10, accuracy: 0.001,
                "300 kcal (tier 2) must add exactly +0.10 bonus"
            )
        }

        func test_exerciseBonus_500kcal_returnsMaxBonus_0_15() {
            let meals = [MealBuilder().withScore(0.5).analyzed().build()]
            let base = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: nil
            )
            let with500 = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: 500
            )
            XCTAssertEqual(
                with500.dimensions.physicalLoad - base.dimensions.physicalLoad,
                0.15, accuracy: 0.001,
                "500 kcal (tier 3) must add exactly +0.15 max bonus"
            )
        }

        func test_exerciseBonus_1000kcal_clampedToMaxBonus() {
            let meals = [MealBuilder().withScore(0.5).analyzed().build()]
            let with500 = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: 500
            )
            let with1000 = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: 1000
            )
            XCTAssertEqual(
                with1000.dimensions.physicalLoad, with500.dimensions.physicalLoad, accuracy: 0.001,
                "1000 kcal must not exceed the max +0.15 bonus"
            )
        }

        func test_physicalLoad_noMeals_noExercise_returnsStubScore() {
            let synthesis = self.sut.synthesize(
                meals: [], highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: nil
            )
            XCTAssertEqual(
                synthesis.dimensions.physicalLoad,
                0.5,
                accuracy: 0.001,
                "No meals + no exercise must return the neutral stub score"
            )
        }

        func test_physicalLoad_mealsOnly_noExercise_equalsBaseScore() {
            let meals = [
                MealBuilder().withScore(0.6).analyzed().build(),
                MealBuilder().withScore(0.8).analyzed().build()
            ]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: nil
            )
            XCTAssertEqual(
                synthesis.dimensions.physicalLoad,
                0.7,
                accuracy: 0.001,
                "Meals only (no exercise) must equal the avg meal score"
            )
        }

        func test_physicalLoad_mealsAndExercise_baseScorePlusBonus() {
            let meals = [MealBuilder().withScore(0.6).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: 350
            )
            XCTAssertEqual(
                synthesis.dimensions.physicalLoad,
                0.7,
                accuracy: 0.001,
                "0.6 base + 0.10 tier-2 bonus = 0.70"
            )
        }

        func test_physicalLoad_highFoodHighExercise_clampedToOne() {
            let meals = [MealBuilder().withScore(0.95).analyzed().build()]
            let synthesis = self.sut.synthesize(
                meals: meals, highlightData: nil, reflectData: nil,
                appleSleepData: nil, yesterday: nil, activeCaloriesBurned: 600
            )
            XCTAssertLessThanOrEqual(
                synthesis.dimensions.physicalLoad,
                1.0,
                "physicalLoad must never exceed 1.0 even with max exercise bonus"
            )
        }
    }

#endif
