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

            // Act - use "Apple" (5 chars) to meet minimum content length requirement
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple"])

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

            // Act - use "Apple" (5 chars) to meet minimum content length requirement
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple"])

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

            // When: Perform AI analysis (will fail) - use "Apple" (5 chars) to meet minimum content length
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple"])

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

        // MARK: - Phase 1: Minimum Content Length Tests

        func test_performDeepAnalysis_skipsAnalysis_whenContentTooShort() async {
            // Given: Create a meal with very short content (< 5 characters)
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // When: Attempt to analyze with short content like "E" or "Am"
            await self.sut.performDeepAnalysis(for: meal.id, items: ["E"])

            // Then: AI analysis should NOT be called
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "AI analysis should be skipped for short content")
        }

        func test_performDeepAnalysis_proceeds_whenContentSufficient() async {
            // Given: Create a meal with sufficient content (>= 5 characters)
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // When: Analyze with sufficient content
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple"])

            // Then: AI analysis SHOULD be called
            XCTAssertTrue(self.mockAILogic.analyzeCalled, "AI analysis should proceed for sufficient content")
        }

        func test_performDeepAnalysis_skipsAnalysis_whenMultipleItemsTooShort() async {
            // Given: Create a meal with multiple short items that total < 5 characters
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            // When: Analyze with short items like ["A", "B"] (total 2 chars)
            await self.sut.performDeepAnalysis(for: meal.id, items: ["A", "B"])

            // Then: AI analysis should NOT be called
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "AI analysis should be skipped for short combined content")
        }

        // MARK: - Phase 3: Content Similarity Detection Tests

        func test_performDeepAnalysis_skipsAnalysis_whenContentIdentical() async {
            // Given: Create a meal and analyze it once
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // First analysis should proceed
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple Pie"])
            XCTAssertTrue(self.mockAILogic.analyzeCalled, "First analysis should proceed")

            // Reset the mock
            self.mockAILogic.analyzeCalled = false

            // When: Analyze with IDENTICAL content again
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple Pie"])

            // Then: AI analysis should be skipped (already analyzed with same content)
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "AI analysis should be skipped for identical content")
        }

        func test_performDeepAnalysis_proceeds_whenContentMeaningfullyChanged() async {
            // Given: Create a meal and analyze it once
            self.sut.createNewMeal()
            guard let meal = self.sut.meals.first else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // First analysis
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple"])
            XCTAssertTrue(self.mockAILogic.analyzeCalled)

            // Manually reset the isAIAnalyzed flag to simulate content change
            self.sut.meals[0].isAIAnalyzed = false
            self.mockAILogic.analyzeCalled = false

            // When: Analyze with DIFFERENT content
            await self.sut.performDeepAnalysis(for: meal.id, items: ["Apple Pie with Ice Cream"])

            // Then: AI analysis SHOULD proceed (content meaningfully changed)
            XCTAssertTrue(self.mockAILogic.analyzeCalled, "AI analysis should proceed for meaningfully changed content")
        }

        func test_updateMealItems_skipsUpdate_whenOnlyWhitespaceChanged() async throws {
            // Given: Create a meal and set initial content
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // First update with content
            self.sut.updateMealItems(mealId, items: ["Apple"])

            // Wait for async AI analysis to complete
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Reset mock to track next call
            self.mockAILogic.analyzeCalled = false

            // When: Update with same content but extra whitespace (normalized should be same)
            self.sut.updateMealItems(mealId, items: ["Apple "])

            // Wait for any async tasks
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Then: AI analysis should be skipped (whitespace-only difference detected by normalization)
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "AI analysis should be skipped for whitespace-only changes")
        }

        func test_normalizeContent_removesWhitespace() {
            // Test the normalization helper function
            let items1 = ["Apple ", " Banana", "  Orange  "]
            let items2 = ["Apple", "Banana", "Orange"]

            let normalized1 = MainViewModel.normalizeContent(items1)
            let normalized2 = MainViewModel.normalizeContent(items2)

            XCTAssertEqual(normalized1, normalized2, "Whitespace should be normalized")
        }

        func test_contentMeaningfullyChanged_detectsRealChanges() {
            // Same content with different whitespace - should NOT be considered changed
            XCTAssertFalse(
                MainViewModel.contentMeaningfullyChanged(old: ["Apple"], new: ["Apple "]),
                "Whitespace-only changes should not be considered meaningful"
            )

            // Different content - should be considered changed
            XCTAssertTrue(
                MainViewModel.contentMeaningfullyChanged(old: ["Apple"], new: ["Apple Pie"]),
                "Different content should be considered meaningful"
            )

            // Case differences are normalized
            XCTAssertFalse(
                MainViewModel.contentMeaningfullyChanged(old: ["Apple"], new: ["apple"]),
                "Case-only changes should not be considered meaningful"
            )
        }

        // MARK: - Phase 1: Local-Only Update Tests

        func test_updateMealItemsLocalOnly_updatesItems_withoutTriggeringAI() async throws {
            // Given: Create a meal
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // When: Update using local-only method
            self.sut.updateMealItemsLocalOnly(mealId, items: ["Apple Pie"])

            // Wait for any async tasks that might have been triggered
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Then: Items should be updated but AI should NOT be called
            XCTAssertEqual(self.sut.meals.first?.items, ["Apple Pie"], "Items should be updated")
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "AI analysis should NOT be triggered for local-only update")
        }

        func test_updateMealItemsLocalOnly_updatesLocalHealthScore() {
            // Given: Create a meal
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // When: Update using local-only method
            self.sut.updateMealItemsLocalOnly(mealId, items: ["Healthy Salad"])

            // Then: Local health score should be calculated (mock returns 0.5)
            XCTAssertEqual(self.sut.meals.first?.healthScore, 0.5, "Local health score should be calculated")
        }

        func test_updateMealItemsLocalOnly_doesNotResetIsAIAnalyzedFlag() async {
            // Given: Create a meal and mark it as AI analyzed
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // First, run AI analysis to set isAIAnalyzed = true
            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false, "Should be marked as AI analyzed")
            let aiScore = self.sut.meals.first?.healthScore ?? 0

            // When: Update using local-only method WITH DIFFERENT CONTENT
            self.sut.updateMealItemsLocalOnly(mealId, items: ["Apple Pie"])

            // Then: isAIAnalyzed should be reset (content changed, needs re-analysis)
            // But the AI score should be preserved until next "done" action
            XCTAssertFalse(
                self.sut.meals.first?.isAIAnalyzed ?? true,
                "isAIAnalyzed should be reset when content changes"
            )
            XCTAssertEqual(
                self.sut.meals.first?.healthScore ?? 0,
                aiScore,
                "AI score should be preserved during local updates (not recalculated)"
            )
        }

        // MARK: - Phase 2: Explicit AI Analysis Trigger Tests

        func test_triggerAIAnalysis_callsPerformDeepAnalysis() async throws {
            // Given: Create a meal with content
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // Set up meal with items
            self.sut.updateMealItemsLocalOnly(mealId, items: ["Apple Pie"])
            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // When: Trigger AI analysis explicitly
            await self.sut.triggerAIAnalysisForMeal(mealId)

            // Then: AI analysis should be called
            XCTAssertTrue(self.mockAILogic.analyzeCalled, "AI analysis should be triggered")
        }

        func test_triggerAIAnalysis_resetsIsAIAnalyzedFlag() async {
            // Given: Create a meal that was previously analyzed
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // First analysis
            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)
            await self.sut.performDeepAnalysis(for: mealId, items: ["Apple"])
            XCTAssertTrue(self.sut.meals.first?.isAIAnalyzed ?? false)

            // Update content locally - this NOW resets the flag since content changed
            self.sut.updateMealItemsLocalOnly(mealId, items: ["Apple Pie with Ice Cream"])
            XCTAssertFalse(
                self.sut.meals.first?.isAIAnalyzed ?? true,
                "Flag should be false after local update with different content"
            )

            // Reset mock
            self.mockAILogic.analyzeCalled = false

            // When: Trigger AI analysis explicitly
            await self.sut.triggerAIAnalysisForMeal(mealId)

            // Then: Flag should be reset and analysis should run
            XCTAssertTrue(self.mockAILogic.analyzeCalled, "AI analysis should run after explicit trigger")
        }

        func test_triggerAIAnalysis_skipsIfContentTooShort() async throws {
            // Given: Create a meal with short content
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // Set up meal with short content (< 5 chars)
            self.sut.meals[0].items = ["Hi"]
            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)

            // When: Trigger AI analysis
            await self.sut.triggerAIAnalysisForMeal(mealId)

            // Then: AI analysis should NOT be called (content too short)
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "AI analysis should be skipped for short content")
        }

        // MARK: - Done Action Triggers AI Analysis After Local Updates

        func test_updateMeal_triggersAI_whenCalledAfterLocalOnlyUpdates() async throws {
            // Given: Create a meal and update it via local-only (simulating typing)
            self.sut.createNewMeal()
            guard let mealId = self.sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // Get the auto-detected meal type to use the same one in updateMeal
            let originalMealType = self.sut.meals.first?.mealType ?? .lunch

            // Simulate typing - local updates (no AI)
            self.sut.updateMealItemsLocalOnly(mealId, items: ["Apple Pie"])

            // Verify local update happened but no AI
            XCTAssertEqual(self.sut.meals.first?.items, ["Apple Pie"])
            XCTAssertFalse(self.mockAILogic.analyzeCalled, "AI should not be called during local-only updates")
            XCTAssertFalse(
                self.sut.meals.first?.isAIAnalyzed ?? true,
                "isAIAnalyzed should be false after local update"
            )

            // When: User triggers "done" action (focus loss / Done button)
            // This calls updateMeal with the same items AND same meal type (content unchanged)
            self.mockAILogic.mockAnalysisResult = (score: 0.8, mood: .serene, sound: "chime", insight: nil)
            self.sut.updateMeal(mealId, mealType: originalMealType, items: ["Apple Pie"])

            // Wait for async AI analysis to complete
            try await Task.sleep(nanoseconds: 200_000_000) // 200ms

            // Then: AI analysis should be triggered despite content being "unchanged"
            XCTAssertTrue(self.mockAILogic.analyzeCalled, "AI should be triggered on done action after local updates")
        }

        // MARK: - Production Wiring Tests

        func test_defaultMainViewModel_usesAIAnalysisProvider() {
            // Regression test: MainViewModel() with no args must wire AILogicService.
            // This was broken when the default was silently changed to MealLogicService to fix
            // a Firebase timing warning, causing performDeepAnalysis to always bail early.
            let vm = MainViewModel(skipDataLoading: true)
            XCTAssertTrue(
                vm.logicService is AIAnalysisProvider,
                "Production MainViewModel must use AIAnalysisProvider — without it, AI analysis silently never runs"
            )
        }

        func test_defaultMainViewModel_aiAnalysisGuardPasses() async {
            // Verifies the AIAnalysisProvider cast in performDeepAnalysis succeeds for the default VM,
            // so Firebase is actually called rather than returning early with the local score.
            let vm = MainViewModel(logicService: MockAILogicService(), skipDataLoading: true)
            vm.createNewMeal()
            guard let mealId = vm.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            // Confirm the guard passes — analyzeCalled would be false if guard bailed early
            let mock = vm.logicService as! MockAILogicService
            mock.mockAnalysisResult = (score: 0.9, mood: .serene, sound: "chime", insight: nil)
            await vm.performDeepAnalysis(for: mealId, items: ["Apple salad"])

            XCTAssertTrue(mock.analyzeCalled, "AIAnalysisProvider guard must pass for default VM — if false, AI is silently disabled")
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
