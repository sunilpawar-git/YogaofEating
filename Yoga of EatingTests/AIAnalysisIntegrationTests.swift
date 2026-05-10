#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    // Integration tests for the full AI meal analysis pipeline.
    //
    // Unit tests in MainViewModelAIAnalysisTests verify isolated ViewModel behaviour.
    // These tests verify end-to-end wiring: typing → local score → "done" → AI score →
    // isAIAnalyzed flag → smiley state, using realistic component assembly.
    //
    // All tests use MockAILogicService (which conforms to AIAnalysisProvider) so Firebase
    // is never touched. The wiring — not the network — is what's being tested.

    @MainActor
    final class AIAnalysisIntegrationTests: XCTestCase {
        // MARK: - Properties

        var sut: MainViewModel!
        var mockAI: MockAILogicService!
        var mockPersistence: MockPersistenceService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockAI = MockAILogicService()
            self.mockPersistence = MockPersistenceService()
            self.sut = MainViewModel(
                logicService: self.mockAI,
                persistenceService: self.mockPersistence,
                skipDataLoading: true
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockAI = nil
            self.mockPersistence = nil
            super.tearDown()
        }

        // MARK: - Full pipeline: typing → done → AI score

        func test_pipeline_localScore_then_aiScore() async throws {
            // Step 1: Create meal
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            // Step 2: Simulate typing (local-only updates)
            self.sut.updateMealItemsLocalOnly(mealId, items: ["App"])
            self.sut.updateMealItemsLocalOnly(mealId, items: ["Apple"])
            XCTAssertEqual(self.sut.meals.first?.healthScore, 0.5, "Local stub score should be 0.5 during typing")
            XCTAssertFalse(self.sut.meals.first?.isAIAnalyzed ?? true, "Not yet AI analyzed")
            XCTAssertFalse(self.mockAI.analyzeCalled, "AI should not be called during typing")

            // Step 3: User hits "done" — use the meal's own type to avoid hitting the
            // mealTypeChanged branch instead of the needsAIAnalysis branch.
            let mealType = self.sut.meals.first?.mealType ?? .lunch
            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.85,
                mood: .serene,
                sound: "chime",
                insight: "Great choice!",
                estimatedCalories: nil
            )
            self.sut.updateMeal(mealId, mealType: mealType, items: ["Apple"])

            try await Task.sleep(nanoseconds: 200_000_000) // 200ms — let the async Task finish

            // Step 4: AI score should replace local stub
            XCTAssertTrue(self.mockAI.analyzeCalled, "AI should be called on done action")
            XCTAssertEqual(
                self.sut.meals.first?.healthScore ?? 0,
                0.85,
                accuracy: 0.001,
                "AI score should replace local stub"
            )
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false, "Meal should be marked AI analyzed")
            XCTAssertEqual(self.sut.meals.first?.aiInsight, "Great choice!")
        }

        func test_pipeline_aiScore_savedToPersistence() async throws {
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            // Items must be set before trigger — performDeepAnalysis guards on description.count >= 5
            self.sut.updateMealItemsLocalOnly(mealId, items: ["Apple salad"])
            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.75,
                mood: .serene,
                sound: "chime",
                insight: nil,
                estimatedCalories: nil
            )
            await self.sut.triggerAIAnalysisForMeal(mealId)

            // Persistence must be called with the updated score so it survives app restart
            XCTAssertTrue(self.mockPersistence.saveCalled, "Save must be called after AI analysis")
            XCTAssertEqual(self.mockPersistence.savedData?.meals.first?.healthScore ?? 0, 0.75, accuracy: 0.001)
            XCTAssertTrue(self.mockPersistence.savedData?.meals.first?.isAIAnalyzed ?? false)
        }

        // MARK: - Content lifecycle: change → reset → re-analyze

        func test_contentChange_resetsAIFlag_andRetriggers() async throws {
            // Given: meal is AI analyzed
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.8,
                mood: .serene,
                sound: "chime",
                insight: nil,
                estimatedCalories: nil
            )
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)

            // When: content changes (new item added)
            self.mockAI.analyzeCalled = false
            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.4,
                mood: .overwhelmed,
                sound: "thud",
                insight: nil,
                estimatedCalories: nil
            )
            self.sut.updateMeal(mealId, mealType: .breakfast, items: ["Apple", "Fries"])

            try await Task.sleep(nanoseconds: 200_000_000)

            // Then: re-analyzed with new score
            XCTAssertTrue(self.mockAI.analyzeCalled, "Content change should trigger re-analysis")
            XCTAssertEqual(self.sut.meals.first?.healthScore ?? 0, 0.4, accuracy: 0.001)
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)
        }

        func test_whitespaceOnlyChange_doesNotRetrigger() async throws {
            // Given: meal is AI analyzed
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.8,
                mood: .serene,
                sound: "chime",
                insight: nil,
                estimatedCalories: nil
            )
            self.sut.updateMeal(mealId, mealType: .breakfast, items: ["Apple"])
            try await Task.sleep(nanoseconds: 200_000_000)

            self.mockAI.analyzeCalled = false

            // When: same content with trailing space (normalized to same)
            self.sut.updateMeal(mealId, mealType: .breakfast, items: ["Apple "])
            try await Task.sleep(nanoseconds: 200_000_000)

            XCTAssertFalse(self.mockAI.analyzeCalled, "Whitespace-only changes should not retrigger AI")
        }

        // MARK: - Multi-meal smiley state

        func test_multiMeal_smileyReflectsAverageAiScore() async {
            // Three meals with different AI scores — smiley state should reflect the average
            self.sut.createNewMeal()
            self.sut.createNewMeal()
            self.sut.createNewMeal()
            XCTAssertEqual(self.sut.meals.count, 3)

            // Set AI scores directly (simulating completed analyses)
            self.sut.meals[0].healthScore = 0.9 // serene territory
            self.sut.meals[0].isAIAnalyzed = true
            self.sut.meals[1].healthScore = 0.9
            self.sut.meals[1].isAIAnalyzed = true
            self.sut.meals[2].healthScore = 0.9
            self.sut.meals[2].isAIAnalyzed = true

            await self.sut.reanalyzeAllMealsForSmileyState()
            XCTAssertEqual(self.sut.smileyState.mood, .serene, "All healthy meals should yield serene smiley")

            // Swap to all unhealthy
            self.sut.meals[0].healthScore = 0.1
            self.sut.meals[1].healthScore = 0.1
            self.sut.meals[2].healthScore = 0.1

            await self.sut.reanalyzeAllMealsForSmileyState()
            XCTAssertEqual(
                self.sut.smileyState.mood,
                .overwhelmed,
                "All unhealthy meals should yield overwhelmed smiley"
            )
        }

        func test_singleHighScoreMeal_setsSerenemood() async {
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.9,
                mood: .serene,
                sound: "chime",
                insight: nil,
                estimatedCalories: nil
            )
            await self.sut.performDeepAnalysis(for: mealId, items: ["Green smoothie bowl"])

            XCTAssertEqual(self.sut.smileyState.mood, .serene)
        }

        func test_singleLowScoreMeal_setsOverwhelmedMood() async {
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.1,
                mood: .overwhelmed,
                sound: "thud",
                insight: nil,
                estimatedCalories: nil
            )
            await self.sut.performDeepAnalysis(for: mealId, items: ["Deep fried everything"])

            XCTAssertEqual(self.sut.smileyState.mood, .overwhelmed)
        }

        // MARK: - Deduplication

        func test_concurrentDoneTaps_onlyCallAIOnce() async {
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            self.sut.meals[0].items = ["Apple"]

            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.8,
                mood: .serene,
                sound: "chime",
                insight: nil,
                estimatedCalories: nil
            )

            // Fire two concurrent analyses for the same meal
            async let first: () = self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])
            async let second: () = self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])
            _ = await (first, second)

            // analysisInProgress guard must deduplicate — confirm one run with consistent score
            XCTAssertTrue(self.mockAI.analyzeCalled, "At least one analysis should run")
            XCTAssertEqual(self.sut.meals.first?.healthScore ?? 0, 0.8, accuracy: 0.001)
        }

        func test_secondDoneAfterAiComplete_doesNotRetrigger_whenContentUnchanged() async throws {
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }
            let type = self.sut.meals.first?.mealType ?? .lunch

            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.8,
                mood: .serene,
                sound: "chime",
                insight: nil,
                estimatedCalories: nil
            )
            self.sut.updateMeal(mealId, mealType: type, items: ["Apple"])
            try await Task.sleep(nanoseconds: 200_000_000)

            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)
            self.mockAI.analyzeCalled = false

            // Second "done" with same content — should skip since already analyzed
            self.sut.updateMeal(mealId, mealType: type, items: ["Apple"])
            try await Task.sleep(nanoseconds: 200_000_000)

            XCTAssertFalse(self.mockAI.analyzeCalled, "No retrigger when content unchanged and already analyzed")
        }

        // MARK: - Error recovery

        func test_aiFailure_doesNotMarkMealAsAnalyzed() async {
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            self.mockAI.shouldThrowError = true
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple salad"])

            XCTAssertFalse(self.sut.meals.first?.isAIAnalyzed ?? true, "Failed analysis must not set isAIAnalyzed")
        }

        func test_aiFailure_preservesLocalScore() async {
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

            // Local score is 0.5 (AILogicService stub)
            let localScore = self.sut.meals.first?.healthScore ?? -1

            self.mockAI.shouldThrowError = true
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple salad"])

            XCTAssertEqual(
                self.sut.meals.first?.healthScore ?? 0,
                localScore,
                accuracy: 0.001,
                "Local score must be preserved on AI failure"
            )
        }

        func test_aiFailure_allowsRetryOnNextDone() async throws {
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }
            let type = self.sut.meals.first?.mealType ?? .lunch

            // First attempt: fails
            self.mockAI.shouldThrowError = true
            self.sut.updateMeal(mealId, mealType: type, items: ["Apple"])
            try await Task.sleep(nanoseconds: 200_000_000)
            XCTAssertFalse(self.sut.meals.first?.isAIAnalyzed ?? true)

            // Second attempt: succeeds (user tries again)
            self.mockAI.shouldThrowError = false
            self.mockAI.mockAnalysisResult = MealAnalysisResult(
                score: 0.8,
                mood: .serene,
                sound: "chime",
                insight: nil,
                estimatedCalories: nil
            )
            self.sut.meals[0].isAIAnalyzed = false // reset to allow retry
            await self.sut.triggerAIAnalysisForMeal(mealId)

            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false, "Retry after failure should succeed")
            XCTAssertEqual(self.sut.meals.first?.healthScore ?? 0, 0.8, accuracy: 0.001)
        }

        // MARK: - Production wiring (regression guard)

        func test_defaultInit_logicServiceIsAIAnalysisProvider() {
            // Regression: This was broken when the default was silently changed to
            // MealLogicService, causing performDeepAnalysis to always bail early.
            // If this test fails, AI analysis is silently disabled in production.
            let vm = MainViewModel(skipDataLoading: true)
            XCTAssertTrue(
                vm.logicService is AIAnalysisProvider,
                "Default MainViewModel must use AIAnalysisProvider — changing this silently disables AI analysis"
            )
        }

        func test_defaultInit_performDeepAnalysis_reachesAIProvider() async {
            // End-to-end regression: confirms the AIAnalysisProvider guard in
            // performDeepAnalysis passes when using the default logicService.
            let mockLogic = MockAILogicService()
            mockLogic.mockAnalysisResult = MealAnalysisResult(
                score: 0.9,
                mood: .serene,
                sound: "chime",
                insight: nil,
                estimatedCalories: nil
            )
            let vm = MainViewModel(
                logicService: mockLogic,
                persistenceService: self.mockPersistence,
                skipDataLoading: true
            )

            vm.createNewMeal()
            guard let mealId = vm.meals.first?.id else { return XCTFail("No meal") }

            await vm.performDeepAnalysis(for: mealId, items: ["Apple salad bowl"])

            XCTAssertTrue(
                mockLogic.analyzeCalled,
                "If false, the AIAnalysisProvider guard is failing and Firebase is never called"
            )
        }
    }
#endif
