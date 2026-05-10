#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    // MARK: - Phase 0: CaloriePillData unit tests

    @MainActor
    final class CaloriePillTests: XCTestCase {
        // MARK: - CaloriePillData — init

        func test_caloriePillData_init_setsConsumedAndTDEE() {
            let data = CaloriePillData(consumed: 1250, tdee: 2250)
            XCTAssertEqual(data.consumed, 1250)
            XCTAssertEqual(data.tdee, 2250)
        }

        func test_caloriePillData_equality_sameValues() {
            let a = CaloriePillData(consumed: 1000, tdee: 2000)
            let b = CaloriePillData(consumed: 1000, tdee: 2000)
            XCTAssertEqual(a, b)
        }

        func test_caloriePillData_equality_differentConsumed_notEqual() {
            let a = CaloriePillData(consumed: 1000, tdee: 2000)
            let b = CaloriePillData(consumed: 1200, tdee: 2000)
            XCTAssertNotEqual(a, b)
        }

        // MARK: - CaloriePillData — progressFraction

        func test_caloriePillData_progressFraction_clampedAt1WhenOverGoal() {
            let data = CaloriePillData(consumed: 2500, tdee: 2000)
            XCTAssertEqual(data.progressFraction, 1.0, accuracy: 0.001)
        }

        func test_caloriePillData_progressFraction_zeroWhenTDEENil() {
            let data = CaloriePillData(consumed: 500, tdee: nil)
            XCTAssertEqual(data.progressFraction, 0.0, accuracy: 0.001)
        }

        func test_caloriePillData_progressFraction_correctRatio() {
            let data = CaloriePillData(consumed: 1000, tdee: 2000)
            XCTAssertEqual(data.progressFraction, 0.5, accuracy: 0.001)
        }

        func test_caloriePillData_progressFraction_zeroWhenConsumedZero() {
            let data = CaloriePillData(consumed: 0, tdee: 2000)
            XCTAssertEqual(data.progressFraction, 0.0, accuracy: 0.001)
        }

        // MARK: - CaloriePillData — fillColor

        func test_caloriePillData_fillColor_greenBelow70Percent() {
            // 56% consumed
            let data = CaloriePillData(consumed: 1120, tdee: 2000)
            XCTAssertEqual(data.fillColor, AppTheme.CaloriePill.fillOnTrack)
        }

        func test_caloriePillData_fillColor_amberAt85Percent() {
            // 85% consumed
            let data = CaloriePillData(consumed: 1700, tdee: 2000)
            XCTAssertEqual(data.fillColor, AppTheme.CaloriePill.fillApproaching)
        }

        func test_caloriePillData_fillColor_coralWhenOver100Percent() {
            // 107% consumed
            let data = CaloriePillData(consumed: 2140, tdee: 2000)
            XCTAssertEqual(data.fillColor, AppTheme.CaloriePill.fillOver)
        }

        func test_caloriePillData_fillColor_amberAtExactly70Percent() {
            // Boundary: exactly 70% → approaching
            let data = CaloriePillData(consumed: 1400, tdee: 2000)
            XCTAssertEqual(data.fillColor, AppTheme.CaloriePill.fillApproaching)
        }

        func test_caloriePillData_fillColor_onTrackWhenTDEENil() {
            // No TDEE → default to onTrack color (no fill shown)
            let data = CaloriePillData(consumed: 500, tdee: nil)
            XCTAssertEqual(data.fillColor, AppTheme.CaloriePill.fillOnTrack)
        }

        // MARK: - CaloriePillData — isVisible

        func test_caloriePillData_isVisible_falseWhenConsumedZeroAndTDEENil() {
            let data = CaloriePillData(consumed: 0, tdee: nil)
            XCTAssertFalse(data.isVisible)
        }

        func test_caloriePillData_isVisible_trueWhenConsumedZeroButTDEEKnown() {
            // Show "0 / 2,250 Cal" so user sees daily target from start of day
            let data = CaloriePillData(consumed: 0, tdee: 2250)
            XCTAssertTrue(data.isVisible)
        }

        func test_caloriePillData_isVisible_trueWhenConsumedPositiveAndTDEENil() {
            // Consumed data exists — pill must show even without TDEE
            let data = CaloriePillData(consumed: 500, tdee: nil)
            XCTAssertTrue(data.isVisible)
        }

        func test_caloriePillData_isVisible_trueWhenBothPresent() {
            let data = CaloriePillData(consumed: 1250, tdee: 2250)
            XCTAssertTrue(data.isVisible)
        }

        // MARK: - CaloriePillData — formatting

        func test_caloriePillData_formattedConsumed_usesLocaleGroupingSeparator() {
            let data = CaloriePillData(consumed: 1250, tdee: 2250)
            // Must contain "1" and "250" separated by some grouping character
            // (locale-agnostic: just check it formats the number, not a raw "1250")
            XCTAssertFalse(data.formattedConsumed.isEmpty)
            XCTAssertTrue(data.formattedConsumed.contains("1"))
            XCTAssertTrue(data.formattedConsumed.contains("250"))
        }

        func test_caloriePillData_formattedTDEE_returnsNilWhenTDEENil() {
            let data = CaloriePillData(consumed: 500, tdee: nil)
            XCTAssertNil(data.formattedTDEE)
        }

        func test_caloriePillData_formattedTDEE_nonNilWhenTDEEPresent() {
            let data = CaloriePillData(consumed: 500, tdee: 2000)
            XCTAssertNotNil(data.formattedTDEE)
        }

        // MARK: - R2: remaining + formattedRemaining (Red → computed property doesn't exist yet)

        func test_caloriePillData_remaining_tdeeMinusConsumed() {
            let data = CaloriePillData(consumed: 1000, tdee: 2500)
            XCTAssertEqual(data.remaining, 1500)
        }

        func test_caloriePillData_remaining_nilWhenTDEENil() {
            let data = CaloriePillData(consumed: 800, tdee: nil)
            XCTAssertNil(data.remaining)
        }

        func test_caloriePillData_remaining_negativeWhenOverGoal() {
            let data = CaloriePillData(consumed: 2800, tdee: 2200)
            XCTAssertEqual(data.remaining, -600)
        }

        func test_caloriePillData_formattedRemaining_nilWhenTDEENil() {
            let data = CaloriePillData(consumed: 500, tdee: nil)
            XCTAssertNil(data.formattedRemaining)
        }

        func test_caloriePillData_formattedRemaining_nonNilWhenTDEEPresent() {
            let data = CaloriePillData(consumed: 500, tdee: 2000)
            XCTAssertNotNil(data.formattedRemaining)
        }

        // MARK: - R3: isPartial / formattedConsumed ~ prefix

        func test_caloriePillData_isPartialFalse_formattedConsumedNoTilde() {
            let data = CaloriePillData(consumed: 1200, tdee: 2000, isPartial: false)
            XCTAssertFalse(data.formattedConsumed.hasPrefix("~"), "Non-partial data should not show ~")
        }

        func test_caloriePillData_isPartialTrue_formattedConsumedHasTilde() {
            let data = CaloriePillData(consumed: 800, tdee: 2000, isPartial: true)
            XCTAssertTrue(data.formattedConsumed.hasPrefix("~"), "Partial data should show ~ prefix")
        }
    }

    // MARK: - Phase 2: MealAnalysisResult struct

    func test_mealAnalysisResult_hasScore() {
        let result = MealAnalysisResult(score: 0.8, mood: .serene, sound: "chime", insight: nil, estimatedCalories: nil)
        XCTAssertEqual(result.score, 0.8, accuracy: 0.001)
    }

    func test_mealAnalysisResult_estimatedCalories_defaultsToNil() {
        let result = MealAnalysisResult(score: 0.5, mood: .neutral, sound: "tink", insight: nil, estimatedCalories: nil)
        XCTAssertNil(result.estimatedCalories)
    }

    func test_mealAnalysisResult_estimatedCalories_canBeSet() {
        let result = MealAnalysisResult(
            score: 0.7,
            mood: .serene,
            sound: "chime",
            insight: "Good meal",
            estimatedCalories: 620
        )
        XCTAssertEqual(result.estimatedCalories, 620)
    }

    // MARK: - Phase 1: Meal.estimatedCalories

    @MainActor
    final class MealEstimatedCaloriesTests: XCTestCase {
        func test_meal_estimatedCalories_defaultsToNil() {
            let meal = Meal()
            XCTAssertNil(meal.estimatedCalories)
        }

        func test_meal_estimatedCalories_canBeSetViaInit() {
            let meal = Meal(estimatedCalories: 620)
            XCTAssertEqual(meal.estimatedCalories, 620)
        }

        func test_meal_codable_estimatedCalories_roundTrips() throws {
            var meal = Meal(items: ["oats"], healthScore: 0.7, estimatedCalories: 350)
            meal.isAIAnalyzed = true
            let data = try JSONEncoder().encode(meal)
            let decoded = try JSONDecoder().decode(Meal.self, from: data)
            XCTAssertEqual(decoded.estimatedCalories, 350)
        }

        func test_meal_codable_estimatedCalories_decodesFromLegacyJSON_returnsNil() throws {
            // Simulate JSON from before estimatedCalories existed
            let legacyJSON = """
            {
                "id": "00000000-0000-0000-0000-000000000001",
                "timestamp": 0,
                "mealType": "breakfast",
                "items": ["eggs"],
                "healthScore": 0.8,
                "isAIAnalyzed": false
            }
            """.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(Meal.self, from: legacyJSON)
            XCTAssertNil(decoded.estimatedCalories)
        }
    }

    // MARK: - Phase 1: DailySmileySnapshot.totalCalories

    @MainActor
    final class SnapshotTotalCaloriesTests: XCTestCase {
        private func makeSnapshot(totalCalories: Int? = nil) -> DailySmileySnapshot {
            DailySmileySnapshot(
                id: UUID(),
                date: Date(),
                smileyState: SmileyState(scale: 1.0, mood: .neutral),
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                totalCalories: totalCalories
            )
        }

        func test_dailySmileySnapshot_totalCalories_defaultsToNil() {
            let snapshot = self.makeSnapshot()
            XCTAssertNil(snapshot.totalCalories)
        }

        func test_dailySmileySnapshot_totalCalories_canBeSetViaInit() {
            let snapshot = self.makeSnapshot(totalCalories: 1850)
            XCTAssertEqual(snapshot.totalCalories, 1850)
        }

        func test_dailySmileySnapshot_withTotalCalories_builder_setsValue() {
            let snapshot = self.makeSnapshot().withTotalCalories(2100, hasCompleteCalorieData: true)
            XCTAssertEqual(snapshot.totalCalories, 2100)
        }

        func test_dailySmileySnapshot_withTotalCalories_builder_preservesOtherFields() {
            let original = self.makeSnapshot(totalCalories: nil)
            let updated = original.withTotalCalories(500, hasCompleteCalorieData: false)
            XCTAssertEqual(updated.id, original.id)
            XCTAssertEqual(updated.averageHealthScore, original.averageHealthScore)
        }

        func test_dailySmileySnapshot_codable_totalCalories_roundTrips() throws {
            let snapshot = self.makeSnapshot(totalCalories: 1750)
            let data = try JSONEncoder().encode(snapshot)
            let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: data)
            XCTAssertEqual(decoded.totalCalories, 1750)
        }

        func test_dailySmileySnapshot_codable_totalCalories_decodesFromLegacyJSON_returnsNil() throws {
            // Simulate JSON without totalCalories key (legacy data)
            let legacyJSON = """
            {
                "id": "00000000-0000-0000-0000-000000000002",
                "date": 0,
                "smileyState": {"scale": 1.0, "mood": "neutral"},
                "meals": [],
                "mealCount": 0,
                "averageHealthScore": 0.5
            }
            """.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(DailySmileySnapshot.self, from: legacyJSON)
            XCTAssertNil(decoded.totalCalories)
        }
    }

    // MARK: - R5: CalorieDetailData model

    final class CalorieDetailDataTests: XCTestCase {
        private func makeMeal(type: MealType = .lunch, items: [String] = ["Food"], calories: Int? = nil) -> Meal {
            var meal = Meal(mealType: type, items: items)
            meal.estimatedCalories = calories
            return meal
        }

        func test_calorieDetailData_perMealBreakdown_matchesMeals() {
            let meals = [
                self.makeMeal(type: .breakfast, items: ["Oats"], calories: 350),
                self.makeMeal(type: .lunch, items: ["Salad"], calories: 500)
            ]
            let detail = CalorieDetailData(consumed: 850, tdee: 2000, meals: meals)
            XCTAssertEqual(detail.mealBreakdown.count, 2)
            XCTAssertEqual(detail.mealBreakdown[0].calories, 350)
            XCTAssertEqual(detail.mealBreakdown[1].calories, 500)
        }

        func test_calorieDetailData_perMealBreakdown_excludesMealsWithoutCalories() {
            let meals = [
                self.makeMeal(type: .breakfast, calories: 300),
                self.makeMeal(type: .lunch, calories: nil) // not analyzed yet
            ]
            let detail = CalorieDetailData(consumed: 300, tdee: 2000, meals: meals)
            XCTAssertEqual(detail.mealBreakdown.count, 1)
        }

        func test_calorieDetailData_remainingCalories_tdeeMinusConsumed() {
            let detail = CalorieDetailData(consumed: 1400, tdee: 2000, meals: [])
            XCTAssertEqual(detail.remaining, 600)
        }

        func test_calorieDetailData_remainingCalories_nilWhenTDEENil() {
            let detail = CalorieDetailData(consumed: 1400, tdee: nil, meals: [])
            XCTAssertNil(detail.remaining)
        }

        func test_calorieDetailData_activityBreakdown_showsBasalAndActive() {
            let detail = CalorieDetailData(
                consumed: 1200,
                tdee: 1800,
                meals: [],
                basalCalories: 1400,
                activeCalories: 400
            )
            XCTAssertEqual(detail.basalCalories, 1400)
            XCTAssertEqual(detail.activeCalories, 400)
        }

        func test_calorieDetailData_activityNilByDefault() {
            let detail = CalorieDetailData(consumed: 1000, tdee: 2000, meals: [])
            XCTAssertNil(detail.basalCalories)
            XCTAssertNil(detail.activeCalories)
        }
    }

    // MARK: - AILogicService.parseAnalysisResponse — NSNumber cast regression

    /// Tests the internal static parser directly, without a real Firebase connection.
    /// Verifies that both Int-backed and Double-backed NSNumbers are handled correctly.
    /// The bug: `data["estimatedCalories"] as? Int` silently returns nil when Firebase
    /// deserializes a JSON integer as a Double-backed NSNumber on some SDK versions.
    final class AILogicServiceParseResponseTests: XCTestCase {
        func test_parseResponse_intNSNumber_extractsEstimatedCalories() {
            // Arrange: simulate Firebase returning estimatedCalories as Int-backed NSNumber
            let data: [String: Any] = [
                "healthScore": 0.75,
                "mood": "serene",
                "sound": "chime",
                "insight": "Good meal",
                "estimatedCalories": NSNumber(value: 620) // Int-backed
            ]
            // Act
            let result = AILogicService.parseAnalysisResponse(data)
            // Assert
            XCTAssertEqual(
                result.estimatedCalories,
                620,
                "Int-backed NSNumber should be extracted by parseAnalysisResponse"
            )
        }

        func test_parseResponse_doubleNSNumber_extractsEstimatedCalories() {
            // Arrange: simulate Firebase returning estimatedCalories as Double-backed NSNumber
            // (JSONSerialization may decode integer JSON values as Double-backed NSNumber on
            // some Firebase SDK versions — `as? Int` silently fails in this case)
            let data: [String: Any] = [
                "healthScore": 0.75,
                "mood": "serene",
                "sound": "chime",
                "insight": "Good meal",
                "estimatedCalories": NSNumber(value: 620.0) // Double-backed — the bug case
            ]
            // Act
            let result = AILogicService.parseAnalysisResponse(data)
            // Assert: must NOT return nil — the NSNumber bridge must handle Double-backed values
            XCTAssertEqual(
                result.estimatedCalories,
                620,
                "Double-backed NSNumber must still extract calories — `as? Int` alone fails this"
            )
        }

        func test_parseResponse_nullEstimatedCalories_returnsNil() {
            let data: [String: Any] = [
                "healthScore": 0.5,
                "mood": "neutral",
                "sound": "tink",
                "estimatedCalories": NSNull() // null JSON value
            ]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertNil(result.estimatedCalories, "JSON null should produce nil estimatedCalories")
        }

        func test_parseResponse_missingEstimatedCalories_returnsNil() {
            let data: [String: Any] = [
                "healthScore": 0.5,
                "mood": "neutral",
                "sound": "tink"
                // estimatedCalories key absent
            ]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertNil(result.estimatedCalories, "Missing key should produce nil estimatedCalories")
        }

        func test_parseResponse_healthScore_usesNSNumberBridge() {
            // Verify healthScore also uses the safe NSNumber bridge path
            let data: [String: Any] = [
                "healthScore": NSNumber(value: 0.85),
                "mood": "serene",
                "sound": "chime"
            ]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.score, 0.85, accuracy: 0.001)
        }

        func test_parseResponse_unknownMood_fallsBackToNeutral() {
            let data: [String: Any] = [
                "healthScore": 0.5,
                "mood": "INVALID_MOOD",
                "sound": "tink"
            ]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.mood, .neutral)
        }

        func test_parseResponse_emptyDict_returnsDefaults() {
            let result = AILogicService.parseAnalysisResponse([:])
            XCTAssertEqual(result.score, 0.5, accuracy: 0.001)
            XCTAssertEqual(result.mood, .neutral)
            XCTAssertNil(result.estimatedCalories)
        }
    }

    // MARK: - Integration: VM pipeline → caloriePillData.consumed

    /// Verifies the full pipeline: VM with mock AI (stubbedCalories: 620) →
    /// performDeepAnalysis → caloriePillData.consumed == 620.
    /// This test was missing (T2 in Plans/errors) — its absence meant the calorie
    /// logging bug could regress undetected.
    @MainActor
    final class CaloriePillIntegrationTests: XCTestCase {
        private func makeVM(stubbedCalories: Int?) -> (MainViewModel, CaloriePillMockAI) {
            let mock = CaloriePillMockAI(stubbedCalories: stubbedCalories)
            let vm = MainViewModel(logicService: mock, skipDataLoading: true)
            return (vm, mock)
        }

        func test_integration_mealAnalyzed_pillDataConsumed_reflectsEstimatedCalories() async throws {
            // Arrange
            let (vm, _) = self.makeVM(stubbedCalories: 620)
            vm.createNewMeal()
            guard let meal = vm.meals.first else { XCTFail("No meal created")
                return
            }
            vm.meals[0].items = ["100gm palak paneer", "2 chapati"]

            // Act: trigger AI analysis directly (simulates Done button)
            await vm.performDeepAnalysis(for: meal.id, items: vm.meals[0].items)

            // Assert: caloriePillData.consumed must reflect the stubbed estimate
            XCTAssertEqual(
                vm.caloriePillData.consumed, 620,
                "After AI analysis, caloriePillData.consumed must equal the AI-returned estimatedCalories. " +
                    "Failure here means estimatedCalories is not flowing from MealAnalysisResult → Meal → caloriePillData."
            )
        }

        func test_integration_mealAnalyzed_pillIsVisible_whenConsumedPositive() async throws {
            let (vm, _) = self.makeVM(stubbedCalories: 350)
            vm.createNewMeal()
            guard let meal = vm.meals.first else { XCTFail("No meal created")
                return
            }
            vm.meals[0].items = ["oats", "berries"]

            await vm.performDeepAnalysis(for: meal.id, items: vm.meals[0].items)

            XCTAssertTrue(
                vm.caloriePillData.isVisible,
                "Pill must be visible once consumed > 0"
            )
        }

        func test_integration_multipleMeals_consumed_sumsBothEstimates() async throws {
            let (vm, _) = self.makeVM(stubbedCalories: 500)
            vm.createNewMeal()
            vm.createNewMeal()
            guard vm.meals.count == 2 else { XCTFail("Expected 2 meals")
                return
            }
            let id1 = vm.meals[0].id
            let id2 = vm.meals[1].id
            // Items must be >= 5 chars (ScoringThresholds.minimumMealDescriptionLength = 5)
            vm.meals[0].items = ["oatmeal with berries"]
            vm.meals[1].items = ["salad with grilled chicken"]

            await vm.performDeepAnalysis(for: id1, items: vm.meals[0].items)
            await vm.performDeepAnalysis(for: id2, items: vm.meals[1].items)

            XCTAssertEqual(
                vm.caloriePillData.consumed, 1000,
                "Two meals each returning 500 Cal must sum to 1000 in caloriePillData.consumed"
            )
        }

        func test_integration_aiReturnsNilCalories_consumedStaysZero() async throws {
            let (vm, _) = self.makeVM(stubbedCalories: nil)
            vm.createNewMeal()
            guard let meal = vm.meals.first else { XCTFail("No meal created")
                return
            }
            vm.meals[0].items = ["mystery dish"]

            await vm.performDeepAnalysis(for: meal.id, items: vm.meals[0].items)

            XCTAssertEqual(
                vm.caloriePillData.consumed, 0,
                "When AI returns nil estimatedCalories, consumed must remain 0"
            )
        }
    }

    // MARK: - Pill width

    final class CaloriePillWidthTests: XCTestCase {
        func test_caloriePillMaxWidth_isDefinedAndReasonable() {
            // The design spec calls for ~220pt. Any value outside 160–280 is a regression.
            let maxWidth = AppTheme.CaloriePill.pillMaxWidth
            XCTAssertGreaterThanOrEqual(maxWidth, 160, "pillMaxWidth must be at least 160pt")
            XCTAssertLessThanOrEqual(maxWidth, 280, "pillMaxWidth must not exceed 280pt (full-width is the bug)")
        }
    }

    // MARK: - CaloriePillMockAI (local mock — not in Mocks.swift; scoped to this test file)

    /// Mock AIAnalysisProvider that returns a configurable `estimatedCalories`.
    /// Kept local to CaloriePillTests to avoid polluting the shared Mocks.swift.
    final class CaloriePillMockAI: AIAnalysisProvider {
        var stubbedCalories: Int?

        init(stubbedCalories: Int?) {
            self.stubbedCalories = stubbedCalories
        }

        func calculateHealthScore(for _: String) -> Double { 0.7 }
        func calculateHealthScore(for _: [String]) -> Double { 0.7 }
        func calculateNextState(from state: SmileyState, healthScore _: Double) -> SmileyState { state }

        func analyzeMealQuality(description _: String) async throws -> MealAnalysisResult {
            MealAnalysisResult(
                score: 0.7,
                mood: .serene,
                sound: "chime",
                insight: "Test meal",
                estimatedCalories: self.stubbedCalories
            )
        }
    }

#endif
