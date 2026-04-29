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
            // Compile-time guarantee, but also asserted at runtime to surface if protocol
            // conformance is accidentally removed via an extension deletion.
            XCTAssertTrue(self.sut is AIAnalysisProvider)
        }

        func test_aiLogicService_conformsToMealInsightProvider() {
            XCTAssertTrue(self.sut is MealInsightProvider)
        }
    }
#endif
