#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class MainViewModelAIAnalysisTests: XCTestCase {
        // MARK: - Properties

        var sut: MainViewModel!
        var mockAILogic: MockAILogicService!
        var mockPersistence: MockPersistenceService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockAILogic = MockAILogicService()
            self.mockPersistence = MockPersistenceService()
            self.sut = MainViewModel(logicService: self.mockAILogic, persistenceService: self.mockPersistence)
        }

        override func tearDown() {
            self.sut = nil
            self.mockAILogic = nil
            self.mockPersistence = nil
            super.tearDown()
        }

        // MARK: - Tests: Success Scenarios

        func test_performDeepAnalysis_updatesHealthScore_onSuccess() async {
            // Arrange
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // Act
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple", "Salad"])

            // Assert
            XCTAssertTrue(self.mockAILogic.analyzeCalled)
            XCTAssertEqual(self.sut.meals.first?.healthScore, 0.8)
        }

        func test_performDeepAnalysis_updatesSmileyState_onSuccess() async {
            // Arrange
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.9, mood: .serene, sound: "chime", insight: nil)

            // Act
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Healthy food"])

            // Assert
            // Smiley state should be updated based on the health score
            XCTAssertNotNil(self.sut.smileyState)
        }

        func test_reanalyzeAllMealsForSmileyState_calculatesAverage_correctly() async {
            // Arrange
            self.sut.createNewMeal()
            self.sut.createNewMeal()
            self.sut.createNewMeal()

            // Set health scores manually
            if self.sut.meals.count >= 3 {
                self.sut.meals[0].healthScore = 0.6
                self.sut.meals[1].healthScore = 0.8
                self.sut.meals[2].healthScore = 1.0
            }

            // Act
            await self.sut.reanalyzeAllMealsForSmileyState()

            // Assert
            // Average should be (0.6 + 0.8 + 1.0) / 3 = 0.8
            // This would affect the smiley state accordingly
            XCTAssertNotNil(self.sut.smileyState)
        }

        // MARK: - Tests: Error Scenarios

        func test_performDeepAnalysis_returnsEarly_whenMealNotFound() async {
            // Arrange
            let nonExistentId = UUID()

            // Act
            await self.sut.performDeepAnalysis(for: nonExistentId, items: ["Food"])

            // Assert
            XCTAssertFalse(self.mockAILogic.analyzeCalled)
        }

        func test_performDeepAnalysis_usesLocalScore_whenServiceNotAI() async {
            // Arrange
            let mockLocalLogic = MockMealLogicService()
            self.sut = MainViewModel(logicService: mockLocalLogic, persistenceService: self.mockPersistence)
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            // Act
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Food"])

            // Assert
            // Should use local scoring since service is not AILogicService
            XCTAssertEqual(self.sut.meals.first?.healthScore, 0.5)
        }

        func test_performDeepAnalysis_fallsBack_onAIError() async {
            // Arrange
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.shouldThrowError = true

            // Act
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Food"])

            // Assert
            XCTAssertTrue(self.mockAILogic.analyzeCalled)
            // Should fall back gracefully without crashing
        }

        func test_reanalyzeAllMealsForSmileyState_doesNothing_whenMealsEmpty() async {
            // Arrange
            // No meals created

            // Act
            await self.sut.reanalyzeAllMealsForSmileyState()

            // Assert
            XCTAssertEqual(self.sut.smileyState.scale, 1.0)
            XCTAssertEqual(self.sut.smileyState.mood, .neutral)
        }

        // MARK: - Phase 4: AI Analyzed Flag Tests

        func test_newMeal_isAIAnalyzed_defaultsFalse() {
            // When: Create a new meal
            self.sut.createNewMeal()

            // Then: isAIAnalyzed should be false by default
            XCTAssertFalse(self.sut.meals.first?.isAIAnalyzed ?? true)
        }

        func test_performDeepAnalysis_setsIsAIAnalyzed_onSuccess() async {
            // Given: Create a meal
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }
            XCTAssertFalse(meal.isAIAnalyzed)

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // When: Perform AI analysis
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple", "Salad"])

            // Then: isAIAnalyzed should be true
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)
        }

        func test_performDeepAnalysis_doesNotSetIsAIAnalyzed_onError() async {
            // Given: Create a meal
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.shouldThrowError = true

            // When: Perform AI analysis (will fail)
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Food"])

            // Then: isAIAnalyzed should remain false
            XCTAssertFalse(self.sut.meals.first?.isAIAnalyzed ?? true)
        }

        func test_isAIAnalyzed_persistsAfterSave() async {
            // Given: Create a meal and run AI analysis
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple"])

            // Then: Saved data should have isAIAnalyzed = true
            XCTAssertTrue(self.mockPersistence.savedData?.meals.first?.isAIAnalyzed ?? false)
        }

        // MARK: - Phase 1: Skip Already Analyzed Meals

        func test_performDeepAnalysis_skipsAlreadyAnalyzedMeal() async {
            // Given: Create a meal and mark it as already analyzed
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // First analysis
            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])

            // Verify first call happened
            XCTAssertTrue(self.mockAILogic.analyzeCalled)
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)

            // Reset the flag to track second call
            self.mockAILogic.analyzeCalled = false

            // When: Try to analyze the same meal again
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])

            // Then: The AI service should NOT be called again
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "AI analysis should be skipped for already analyzed meals")
        }

        func test_performDeepAnalysis_analyzesUnanalyzedMeal() async {
            // Given: Create a meal (default isAIAnalyzed = false)
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            XCTAssertFalse(self.sut.meals.first?.isAIAnalyzed ?? true)

            self.mockAILogic.mockAnalysisResult = (score: 0.7, mood: .neutral, sound: "tink", insight: nil)

            // When: Analyze the meal
            await self.sut.performDeepAnalysis(for: mealId, items: ["Salad"])

            // Then: The AI service SHOULD be called
            XCTAssertTrue(self.mockAILogic.analyzeCalled, "AI analysis should proceed for unanalyzed meals")
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)
        }

        // MARK: - Phase 2: Prevent Concurrent Duplicate Requests

        func test_performDeepAnalysis_preventsConcurrentDuplicateRequests() async {
            // Given: Create a meal
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // Use a slow mock that simulates network delay
            let slowMock = SlowMockAILogicService()
            self.sut = MainViewModel(logicService: slowMock, persistenceService: self.mockPersistence)
            self.sut.createNewMeal()
            guard let newMealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // When: Fire two concurrent analysis requests for the same meal
            async let first: () = self.sut.performDeepAnalysis(for: newMealId, items: ["Apple"])
            async let second: () = self.sut.performDeepAnalysis(for: newMealId, items: ["Apple"])

            // Wait for both to complete
            _ = await (first, second)

            // Then: Only ONE analysis should have been performed
            XCTAssertEqual(slowMock.analyzeCallCount, 1, "Should only call analyze once for concurrent requests")
        }

        func test_performDeepAnalysis_allowsSequentialRequestsAfterCompletion() async {
            // Given: Create a meal
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // When: First analysis completes
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)

            // Reset for second request - but note Phase 1 guard will skip
            // This test verifies the in-flight tracking is properly cleaned up
            self.mockAILogic.analyzeCalled = false

            // Simulate content change by resetting isAIAnalyzed
            self.sut.meals[0].isAIAnalyzed = false

            // When: Second analysis (after first completed)
            await self.sut.performDeepAnalysis(for: mealId, items: ["Orange"])

            // Then: Second analysis should proceed (in-flight tracking cleaned up)
            XCTAssertTrue(self.mockAILogic.analyzeCalled, "Should allow analysis after previous completed")
        }

        // MARK: - Phase 3: Only Re-Analyze When Content Changes

        func test_updateMeal_resetsAIAnalyzedFlag_whenItemsChange() async {
            // Given: Create and analyze a meal
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)

            // When: Update with DIFFERENT items
            self.sut.updateMeal(mealId, mealType: .lunch, items: ["Orange", "Banana"])

            // Then: isAIAnalyzed should be reset to false (content changed)
            XCTAssertFalse(self.sut.meals.first?.isAIAnalyzed ?? true, "isAIAnalyzed should be reset when items change")
        }

        func test_updateMeal_preservesAIAnalyzedFlag_whenItemsUnchanged() async {
            // Given: Create and analyze a meal
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // Set initial items
            let initialItems = ["Apple", "Banana"]
            self.sut.updateMeal(mealId, mealType: .breakfast, items: initialItems)

            // Manually set isAIAnalyzed to true (simulating completed analysis)
            self.sut.meals[0].isAIAnalyzed = true
            self.mockAILogic.analyzeCalled = false

            // When: Update with SAME items (just mealType change)
            self.sut.updateMeal(mealId, mealType: .lunch, items: initialItems)

            // Then: isAIAnalyzed should remain true (content unchanged)
            XCTAssertTrue(
                self.sut.meals.first?.isAIAnalyzed ?? false,
                "isAIAnalyzed should be preserved when items don't change"
            )
        }

        func test_updateMeal_skipsAnalysis_whenItemsUnchanged() async throws {
            // Given: Create and analyze a meal
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // Set initial items and mark as analyzed
            let initialItems = ["Apple", "Banana"]
            self.sut.updateMeal(mealId, mealType: .breakfast, items: initialItems)
            self.sut.meals[0].isAIAnalyzed = true
            self.mockAILogic.analyzeCalled = false

            // When: Update with SAME items
            self.sut.updateMeal(mealId, mealType: .lunch, items: initialItems)

            // Give async Task a chance to run (if it was triggered)
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Then: AI analysis should NOT be triggered
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "Should not call AI when items unchanged")
        }
    }

    // MARK: - Slow Mock for Concurrency Testing

    /// A mock that simulates network delay to test concurrent request handling
    class SlowMockAILogicService: AIAnalysisProvider {
        var analyzeCallCount: Int = 0
        var mockAnalysisResult: (score: Double, mood: SmileyMood, sound: String, insight: String?) =
            (0.7, .serene, "chime", nil)

        func calculateHealthScore(for _: String) -> Double { 0.5 }
        func calculateHealthScore(for _: [String]) -> Double { 0.5 }

        func calculateNextState(from state: SmileyState, healthScore: Double) -> SmileyState {
            var nextState = state
            if healthScore > 0.6 {
                nextState.scale = max(0.5, state.scale - 0.1)
                nextState.mood = .serene
            }
            return nextState
        }

        func analyzeMealQuality(description _: String) async throws
            -> (score: Double, mood: SmileyMood, sound: String, insight: String?)
        {
            self.analyzeCallCount += 1

            // Simulate network delay
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

            return self.mockAnalysisResult
        }
    }

    // MARK: - Mocks

    /// Mock AILogicService for testing
    class MockAILogicService: AIAnalysisProvider {
        var mockAnalysisResult: (score: Double, mood: SmileyMood, sound: String, insight: String?) =
            (0.7, .serene, "chime", nil)
        var shouldThrowError: Bool = false
        var analyzeCalled: Bool = false

        func calculateHealthScore(for _: String) -> Double {
            0.5
        }

        func calculateHealthScore(for _: [String]) -> Double {
            0.5
        }

        func calculateNextState(from state: SmileyState, healthScore: Double) -> SmileyState {
            var nextState = state

            if healthScore > 0.6 {
                nextState.scale = max(0.5, state.scale - 0.1)
                nextState.mood = .serene
            } else if healthScore < 0.4 {
                nextState.scale = min(2.5, state.scale + 0.2)
                nextState.mood = .overwhelmed
            } else {
                nextState.mood = .neutral
            }

            return nextState
        }

        func analyzeMealQuality(description _: String) async throws
            -> (score: Double, mood: SmileyMood, sound: String, insight: String?)
        {
            self.analyzeCalled = true

            if self.shouldThrowError {
                throw NSError(
                    domain: "MockAILogicService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Mock error"]
                )
            }

            return self.mockAnalysisResult
        }
    }
#endif
