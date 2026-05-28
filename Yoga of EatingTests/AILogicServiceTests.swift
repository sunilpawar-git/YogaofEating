#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    // Tests for AILogicService — the Firebase-backed AI scoring service.
    //
    // Tests here cover:
    //   - Stub calculateHealthScore / calculateNextState (synchronous local fallbacks)
    //   - analyzeMealQuality fallback when Firebase Functions is nil (no Firebase in test env)
    //   - getDetailedInsight fallback when Firebase Functions is nil
    //
    // Tests that require live Firebase (analyzeMealQuality with real network) belong in
    // a separate Firebase Emulator target and are not included here.

    @MainActor
    final class AILogicServiceTests: XCTestCase {
        // MARK: - Properties

        var sut: AILogicService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            // Pass functions: nil — simulates "no Firebase" environment (unit test context)
            self.sut = AILogicService(functions: nil)
        }

        override func tearDown() {
            self.sut = nil
            super.tearDown()
        }

        // MARK: - calculateHealthScore (stub)

        func test_calculateHealthScore_string_returnsHalf() {
            // AILogicService.calculateHealthScore is a stub that returns 0.5; the real
            // score comes asynchronously from Firebase. Local scoring via MealLogicService
            // is used for real-time typing feedback only.
            XCTAssertEqual(self.sut.calculateHealthScore(for: "apple salad"), 0.5)
        }

        func test_calculateHealthScore_array_returnsHalf() {
            XCTAssertEqual(self.sut.calculateHealthScore(for: ["apple", "salad"]), 0.5)
        }

        func test_calculateHealthScore_emptyArray_returnsHalf() {
            XCTAssertEqual(self.sut.calculateHealthScore(for: []), 0.5)
        }

        func test_calculateHealthScore_emptyString_returnsHalf() {
            XCTAssertEqual(self.sut.calculateHealthScore(for: ""), 0.5)
        }

        // MARK: - calculateNextState (mirrors MealLogicService logic)

        func test_calculateNextState_healthyScore_shrinksSmiley() {
            let initial = SmileyState(scale: 1.5, mood: .neutral)
            let next = self.sut.calculateNextState(from: initial, healthScore: 0.8)
            XCTAssertLessThan(next.scale, initial.scale, "Healthy score should shrink the smiley")
            XCTAssertEqual(next.mood, .serene)
        }

        func test_calculateNextState_unhealthyScore_growsSmiley() {
            let initial = SmileyState(scale: 1.0, mood: .neutral)
            let next = self.sut.calculateNextState(from: initial, healthScore: 0.2)
            XCTAssertGreaterThan(next.scale, initial.scale, "Unhealthy score should grow the smiley")
            XCTAssertEqual(next.mood, .overwhelmed)
        }

        func test_calculateNextState_neutralScore_keepsNeutralMood() {
            let initial = SmileyState(scale: 1.0, mood: .neutral)
            let next = self.sut.calculateNextState(from: initial, healthScore: 0.5)
            XCTAssertEqual(next.mood, .neutral)
        }

        func test_calculateNextState_clampsScaleAtMax() {
            let initial = SmileyState(scale: 2.4, mood: .overwhelmed)
            let next = self.sut.calculateNextState(from: initial, healthScore: 0.1)
            XCTAssertLessThanOrEqual(next.scale, 2.5, "Scale must not exceed 2.5")
        }

        func test_calculateNextState_clampsScaleAtMin() {
            let initial = SmileyState(scale: 0.6, mood: .serene)
            let next = self.sut.calculateNextState(from: initial, healthScore: 0.9)
            XCTAssertGreaterThanOrEqual(next.scale, 0.5, "Scale must not go below 0.5")
        }

        // MARK: - analyzeMealQuality: nil functions fallback

        func test_analyzeMealQuality_returnsFallback_whenFunctionsNil() async throws {
            // When Firebase Functions is unavailable, the service must return safe defaults
            // rather than throwing — callers should still get a valid (neutral) result.
            let result = try await self.sut.analyzeMealQuality(description: "apple salad")
            XCTAssertEqual(result.score, 0.5, "Fallback score should be 0.5")
            XCTAssertEqual(result.mood, .neutral, "Fallback mood should be neutral")
            XCTAssertEqual(result.sound, "tink", "Fallback sound should be tink")
            XCTAssertNil(result.insight, "Fallback insight should be nil")
        }

        func test_analyzeMealQuality_doesNotThrow_whenFunctionsNil() async {
            // Regression: An early draft threw when functions was nil.
            // Callers depend on non-throwing fallback.
            do {
                _ = try await self.sut.analyzeMealQuality(description: "test food")
            } catch {
                XCTFail("analyzeMealQuality should not throw when functions is nil, got: \(error)")
            }
        }

        // MARK: - getDetailedInsight: nil functions fallback

        func test_getDetailedInsight_returnsFallback_whenFunctionsNil() async throws {
            let meal = Meal(mealType: .lunch, items: ["Salad", "Water"], healthScore: 0.7)
            let insight = try await self.sut.getDetailedInsight(for: meal)
            XCTAssertFalse(insight.summary.isEmpty, "Fallback summary should not be empty")
            XCTAssertEqual(insight.category, "moderate", "Fallback category should be moderate")
        }

        func test_getDetailedInsight_doesNotThrow_whenFunctionsNil() async {
            let meal = Meal(mealType: .dinner, items: ["Pasta"], healthScore: 0.5)
            do {
                _ = try await self.sut.getDetailedInsight(for: meal)
            } catch {
                XCTFail("getDetailedInsight should not throw when functions is nil, got: \(error)")
            }
        }

        // MARK: - SmileyMood initializer from raw string

        func test_smileyMood_init_parsesSerene() {
            XCTAssertEqual(SmileyMood(rawValue: "serene"), .serene)
        }

        func test_smileyMood_init_parsesNeutral() {
            XCTAssertEqual(SmileyMood(rawValue: "neutral"), .neutral)
        }

        func test_smileyMood_init_parsesOverwhelmed() {
            XCTAssertEqual(SmileyMood(rawValue: "overwhelmed"), .overwhelmed)
        }

        func test_smileyMood_init_isCaseInsensitive() {
            XCTAssertEqual(SmileyMood(rawValue: "SERENE"), .serene)
            XCTAssertEqual(SmileyMood(rawValue: "Neutral"), .neutral)
        }

        func test_smileyMood_init_returnsNil_forUnknownValue() {
            XCTAssertNil(SmileyMood(rawValue: "happy"))
            XCTAssertNil(SmileyMood(rawValue: ""))
        }

        // MARK: - AIAnalysisProvider conformance

        func test_aiLogicService_conformsToAIAnalysisProvider() {
            // Cast through AnyObject to avoid the "always succeeds" warning while still
            // asserting the conformance at runtime — catches accidental extension deletions.
            let asAny: AnyObject = self.sut
            XCTAssertTrue(asAny is any AIAnalysisProvider)
        }

        func test_aiLogicService_conformsToMealInsightProvider() {
            let asAny: AnyObject = self.sut
            XCTAssertTrue(asAny is any MealInsightProvider)
        }

        // MARK: - parseAnalysisResponse: macro parsing & calorie derivation

        func test_parseAnalysisResponse_derivesCaloriesFromMacros() {
            let data: [String: Any] = ["healthScore": 0.8, "protein": 42, "carbs": 130, "fat": 28]
            let result = AILogicService.parseAnalysisResponse(data)
            // 42*4 + 130*4 + 28*9 = 168 + 520 + 252 = 940
            XCTAssertEqual(result.estimatedCalories, 940)
        }

        func test_parseAnalysisResponse_fallsBackToDirectCaloriesWhenMacrosAbsent() {
            let data: [String: Any] = ["healthScore": 0.7, "estimatedCalories": 600]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.estimatedCalories, 600)
        }

        func test_parseAnalysis_bothPresent_directHigher_usesDirectCalories() {
            // Phase 4 safeguard: when direct estimate exceeds macro-derived, take the max.
            // Prevents silent underreporting when Gemini underestimates individual macros.
            // Old behaviour (macros always win): returned 165. New behaviour: 999.
            let data: [String: Any] = [
                "healthScore": 0.7,
                "protein": 10,
                "carbs": 20,
                "fat": 5,
                "estimatedCalories": 999
            ]
            let result = AILogicService.parseAnalysisResponse(data)
            // 10*4 + 20*4 + 5*9 = 40 + 80 + 45 = 165; max(165, 999) = 999
            XCTAssertEqual(result.estimatedCalories, 999)
        }

        func test_parseAnalysis_bothPresent_macrosHigher_usesMacroCalories() {
            // When macros derive a higher figure than the direct estimate, macros win (max).
            let data: [String: Any] = [
                "healthScore": 0.8,
                "protein": 42,
                "carbs": 130,
                "fat": 28,
                "estimatedCalories": 500
            ]
            let result = AILogicService.parseAnalysisResponse(data)
            // 42*4 + 130*4 + 28*9 = 168 + 520 + 252 = 940; max(940, 500) = 940
            XCTAssertEqual(result.estimatedCalories, 940)
        }

        func test_parseAnalysis_macrosPresent_noDirectCalories_usesMacroCalories() {
            // When no direct estimate is available, macro-derived calories are used.
            let data: [String: Any] = ["healthScore": 0.7, "protein": 20, "carbs": 80, "fat": 20]
            let result = AILogicService.parseAnalysisResponse(data)
            // 20*4 + 80*4 + 20*9 = 80 + 320 + 180 = 580
            XCTAssertEqual(result.estimatedCalories, 580)
        }

        func test_parseAnalysis_noMacros_directPresent_usesDirectCalories() {
            // When macros are absent, the direct calorie estimate is used as-is.
            let data: [String: Any] = ["healthScore": 0.6, "estimatedCalories": 750]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.estimatedCalories, 750)
        }

        func test_parseAnalysisResponse_clampsProteinAboveMaximum() {
            let data: [String: Any] = ["healthScore": 0.5, "protein": 9999, "carbs": 10, "fat": 5]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.protein, ValidationLimits.maxProteinPerMeal)
        }

        func test_parseAnalysisResponse_clampsCarbohydratesAboveMaximum() {
            let data: [String: Any] = ["healthScore": 0.5, "protein": 10, "carbs": 9999, "fat": 5]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.carbs, ValidationLimits.maxCarbsPerMeal)
        }

        func test_parseAnalysisResponse_clampsFatAboveMaximum() {
            let data: [String: Any] = ["healthScore": 0.5, "protein": 10, "carbs": 50, "fat": 9999]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.fat, ValidationLimits.maxFatPerMeal)
        }

        func test_parseAnalysisResponse_macrosNilWhenAbsent() {
            let data: [String: Any] = ["healthScore": 0.6]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertNil(result.protein)
            XCTAssertNil(result.carbs)
            XCTAssertNil(result.fat)
        }

        func test_parseAnalysisResponse_preservesZeroMacros() {
            // Black coffee: all zeros are valid macro values (not absent)
            let data: [String: Any] = ["healthScore": 0.9, "protein": 0, "carbs": 0, "fat": 0]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.protein, 0)
            XCTAssertEqual(result.carbs, 0)
            XCTAssertEqual(result.fat, 0)
        }

        func test_parseAnalysisResponse_partialMacroTriple_fallsBackToDirectCalories() {
            // Firebase returns only 2 of 3 macros (incomplete triple) — must use direct estimatedCalories
            let data: [String: Any] = ["healthScore": 0.7, "protein": 30, "carbs": 50, "estimatedCalories": 400]
            let result = AILogicService.parseAnalysisResponse(data)
            XCTAssertEqual(result.estimatedCalories, 400, "Incomplete macro triple must not derive calories")
            XCTAssertNil(result.fat, "Missing fat must remain nil")
            XCTAssertEqual(result.protein, 30, "Present macros must still be stored")
        }
    }
#endif
