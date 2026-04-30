#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class MainViewModelTests: XCTestCase {
        var sut: MainViewModel!
        var mockLogic: MockMealLogicService!
        var mockPersistence: MockPersistenceService!
        var mockHistorical: MockHistoricalDataService!

        override func setUp() {
            super.setUp()
            self.mockLogic = MockMealLogicService()
            self.mockPersistence = MockPersistenceService()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = MainViewModel(
                logicService: self.mockLogic,
                persistenceService: self.mockPersistence,
                historicalService: self.mockHistorical
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockLogic = nil
            self.mockPersistence = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        func test_initialState_isNeutral() {
            XCTAssertEqual(self.sut.smileyState.scale, 1.0)
            XCTAssertEqual(self.sut.smileyState.mood, .neutral)
            XCTAssertTrue(self.sut.meals.isEmpty)
        }

        func test_addingMeal_updatesStateAndMeals() {
            self.mockLogic.mockScore = 0.9
            self.mockLogic.nextState = SmileyState(scale: 0.9, mood: .serene)

            self.sut.createNewMeal()
            guard let mealId = sut.meals.first?.id else {
                XCTFail("Meal not created")
                return
            }

            self.sut.updateMeal(mealId, description: "Salad")

            XCTAssertEqual(self.sut.meals.count, 1)
            XCTAssertEqual(self.sut.meals.first?.items, ["Salad"])
            XCTAssertEqual(self.sut.smileyState.scale, 0.9)
        }

        func test_updatingMeal_withTypeAndItems_updatesCorrectly() throws {
            self.sut.createNewMeal()
            let mealId = try XCTUnwrap(self.sut.meals.first).id

            self.sut.updateMeal(mealId, mealType: .dinner, items: ["Soup", "Bread"])

            XCTAssertEqual(self.sut.meals.first?.mealType, .dinner)
            XCTAssertEqual(self.sut.meals.first?.items, ["Soup", "Bread"])
        }

        func test_deletingMeal_updatesState() throws {
            self.sut.createNewMeal()
            let mealId = try XCTUnwrap(self.sut.meals.first).id

            self.sut.deleteMeal(mealId)

            XCTAssertTrue(self.sut.meals.isEmpty)
            XCTAssertEqual(self.sut.smileyState.mood, .neutral)
        }

        func test_resetDay_clearsEverything() {
            self.sut.createNewMeal()
            self.sut.resetDay()

            XCTAssertTrue(self.sut.meals.isEmpty)
            XCTAssertEqual(self.sut.smileyState.mood, .neutral)
        }

        func test_resetDay_archivesData() {
            // Given
            self.sut.createNewMeal()
            let initialMeals = self.sut.meals
            let initialDate = self.sut.lastResetDate

            // When
            self.sut.resetDay()

            // Then
            XCTAssertNotNil(self.mockHistorical.archivedMeals)
            XCTAssertEqual(self.mockHistorical.archivedMeals?.count, initialMeals.count)
            XCTAssertEqual(self.mockHistorical.archivedDate, initialDate)
        }

        func test_deleteAllData_clearsAllState() {
            // Given: Create some meals to have data
            self.sut.createNewMeal()
            self.sut.createNewMeal()
            XCTAssertFalse(self.sut.meals.isEmpty)

            // When: Delete all data
            self.sut.deleteAllData()

            // Then: All state should be cleared
            XCTAssertTrue(self.sut.meals.isEmpty, "Meals should be empty after deleteAllData")
            XCTAssertEqual(self.sut.smileyState.mood, .neutral, "Smiley should be neutral after deleteAllData")
            XCTAssertTrue(
                self.mockHistorical.clearAllDataCalled,
                "Historical service should have clearAllData called"
            )
            XCTAssertTrue(
                self.mockPersistence.deleteAllCalled,
                "Persistence service should have deleteAll called"
            )
        }

        // MARK: - Phase 1: Timestamp Tests

        func test_createNewMeal_capturesCurrentTimestamp() {
            // Given: Note the time before creation
            let beforeCreation = Date()

            // When: Create a new meal
            self.sut.createNewMeal()
            let afterCreation = Date()

            // Then: Meal should have timestamp between before and after
            guard let meal = self.sut.meals.first else {
                XCTFail("No meal created")
                return
            }
            XCTAssertGreaterThanOrEqual(meal.timestamp, beforeCreation)
            XCTAssertLessThanOrEqual(meal.timestamp, afterCreation)
        }

        func test_createNewMeal_timestampIsSavedToPersistence() {
            // When: Create a new meal
            self.sut.createNewMeal()

            // Then: Persistence should be called with meal containing valid timestamp
            XCTAssertTrue(self.mockPersistence.saveCalled)
            guard let savedMeal = self.mockPersistence.savedData?.meals.first else {
                XCTFail("No meal saved to persistence")
                return
            }

            // Timestamp should be recent (within last 5 seconds)
            let timeDiff = abs(savedMeal.timestamp.timeIntervalSinceNow)
            XCTAssertLessThan(timeDiff, 5.0, "Saved meal timestamp should be recent")
        }

        func test_updateMeal_doesNotChangeTimestamp() throws {
            // Given: Create a meal and note its timestamp
            self.sut.createNewMeal()
            let mealId = try XCTUnwrap(self.sut.meals.first?.id)
            let originalTimestamp = try XCTUnwrap(self.sut.meals.first?.timestamp)

            // When: Update the meal
            self.sut.updateMeal(mealId, mealType: .dinner, items: ["Updated"])

            // Then: Timestamp should remain unchanged
            let updatedTimestamp = try XCTUnwrap(self.sut.meals.first?.timestamp)
            XCTAssertEqual(originalTimestamp, updatedTimestamp)
        }

        func test_multipleMeals_haveDistinctTimestamps() throws {
            // When: Create multiple meals
            self.sut.createNewMeal()
            let meal1Timestamp = try XCTUnwrap(self.sut.meals.first?.timestamp)

            // Small delay to ensure different timestamps
            Thread.sleep(forTimeInterval: 0.01) // 10ms

            self.sut.createNewMeal()
            let meal2Timestamp = try XCTUnwrap(self.sut.meals.last?.timestamp)

            // Then: Second meal should have later or equal timestamp
            XCTAssertGreaterThanOrEqual(meal2Timestamp, meal1Timestamp)
        }

        // MARK: - Meal Sorting & Fasting Period Caching Tests

        func test_mealsAreSortedCorrectly_viaFastingPeriods() {
            // Given: meals added out of chronological order
            let date1 = Date(timeIntervalSince1970: 1_704_110_400) // Later (dinner)
            let date2 = Date(timeIntervalSince1970: 1_704_067_200) // Earlier (breakfast)

            self.sut.meals = [
                Meal(timestamp: date1, mealType: .dinner, items: ["Dinner"]),
                Meal(timestamp: date2, mealType: .breakfast, items: ["Breakfast"])
            ]

            // Then: fastingPeriods are computed from sorted meals —
            // the start meal should be the earlier one (breakfast → dinner direction)
            XCTAssertEqual(self.sut.fastingPeriods.count, 1)
            let period = self.sut.fastingPeriods.first
            XCTAssertNotNil(period)
            // The fasting period duration equals the gap between breakfast and dinner
            XCTAssertEqual(period?.durationInHours ?? 0, 12.0, accuracy: 0.1)
        }

        func test_fastingPeriods_isCachedCorrectly() {
            // Given: Create two meals with known timestamps
            let date1 = Date(timeIntervalSince1970: 1_704_067_200) // 8 AM
            let date2 = Date(timeIntervalSince1970: 1_704_110_400) // 8 PM (12h later)

            self.sut.meals = [
                Meal(timestamp: date1, mealType: .breakfast, items: ["Coffee"]),
                Meal(timestamp: date2, mealType: .dinner, items: ["Salad"])
            ]

            // Then: fastingPeriods should have one period
            XCTAssertEqual(self.sut.fastingPeriods.count, 1)
            XCTAssertEqual(self.sut.fastingPeriods.first?.durationInHours ?? 0, 12.0, accuracy: 0.1)
        }

        func test_meals_updatesWhenMealCreated() {
            // Given: No meals
            XCTAssertTrue(self.sut.meals.isEmpty)

            // When: Add a meal
            self.sut.createNewMeal()

            // Then: meals count updates
            XCTAssertEqual(self.sut.meals.count, 1)
        }

        func test_fastingPeriods_emptyForSingleMeal() {
            // When: Create single meal
            self.sut.createNewMeal()

            // Then: No fasting periods (need at least 2 meals)
            XCTAssertTrue(self.sut.fastingPeriods.isEmpty)
        }

        // MARK: - Phase 2: Timestamp Editing Tests

        func test_updateMealTimestamp_changesTimestamp() throws {
            // Given: Create a meal
            self.sut.createNewMeal()
            let mealId = try XCTUnwrap(self.sut.meals.first?.id)
            let originalTimestamp = try XCTUnwrap(self.sut.meals.first?.timestamp)

            // When: Update the timestamp to a different time
            let newTimestamp = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024
            self.sut.updateMealTimestamp(mealId, timestamp: newTimestamp)

            // Then: Timestamp should be updated
            let updatedTimestamp = try XCTUnwrap(self.sut.meals.first?.timestamp)
            XCTAssertNotEqual(updatedTimestamp, originalTimestamp)
            XCTAssertEqual(updatedTimestamp, newTimestamp)
        }

        func test_updateMealTimestamp_savesPersistence() throws {
            // Given: Create a meal
            self.sut.createNewMeal()
            let mealId = try XCTUnwrap(self.sut.meals.first?.id)
            self.mockPersistence.saveCalled = false // Reset after meal creation

            // When: Update the timestamp
            let newTimestamp = Date(timeIntervalSince1970: 1_704_067_200)
            self.sut.updateMealTimestamp(mealId, timestamp: newTimestamp)

            // Then: Persistence should be called
            XCTAssertTrue(self.mockPersistence.saveCalled)
            let savedTimestamp = self.mockPersistence.savedData?.meals.first?.timestamp
            XCTAssertEqual(savedTimestamp, newTimestamp)
        }

        func test_updateMealTimestamp_invalidId_doesNothing() {
            // Given: Create a meal
            self.sut.createNewMeal()
            let invalidId = UUID() // Random ID that doesn't exist

            // When: Try to update with invalid ID
            let newTimestamp = Date(timeIntervalSince1970: 1_704_067_200)
            self.mockPersistence.saveCalled = false
            self.sut.updateMealTimestamp(invalidId, timestamp: newTimestamp)

            // Then: Nothing should change, no save called
            XCTAssertFalse(self.mockPersistence.saveCalled)
        }

        func test_updateMealTimestamp_preservesOtherMealProperties() throws {
            // Given: Create and configure a meal
            self.sut.createNewMeal()
            let mealId = try XCTUnwrap(self.sut.meals.first?.id)
            self.sut.updateMeal(mealId, mealType: .dinner, items: ["Pizza", "Salad"])

            let originalMealType = self.sut.meals.first?.mealType
            let originalItems = self.sut.meals.first?.items
            let originalHealthScore = self.sut.meals.first?.healthScore

            // When: Update only the timestamp
            let newTimestamp = Date(timeIntervalSince1970: 1_704_067_200)
            self.sut.updateMealTimestamp(mealId, timestamp: newTimestamp)

            // Then: Other properties should be unchanged
            XCTAssertEqual(self.sut.meals.first?.mealType, originalMealType)
            XCTAssertEqual(self.sut.meals.first?.items, originalItems)
            XCTAssertEqual(self.sut.meals.first?.healthScore, originalHealthScore)
        }

        // MARK: - Recent Meals & Copy Meal Tests (Phase: Repeat Meal Feature)

        func test_getRecentUniqueMeals_returnsLast3DaysMeals() {
            // Given: Historical data with meals from past 3 days
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Create snapshots for past 3 days with meals
            for daysAgo in 1...3 {
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
                let meal = Meal(
                    timestamp: date,
                    mealType: .breakfast,
                    items: ["Oatmeal Day \(daysAgo)"],
                    healthScore: 0.8
                )
                let snapshot = DailySmileySnapshot(
                    id: UUID(),
                    date: date,
                    smileyState: .neutral,
                    meals: [meal],
                    mealCount: 1,
                    averageHealthScore: 0.8
                )
                self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)
            }

            // When: Get recent unique meals
            let recentMeals = self.sut.getRecentUniqueMeals()

            // Then: Should return meals from last 3 days
            XCTAssertEqual(recentMeals.count, 3)
        }

        func test_getRecentUniqueMeals_deduplicatesByItems() {
            // Given: Historical data with duplicate meals (same items on different days)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Create snapshots with same meal on 2 different days
            for daysAgo in 1...2 {
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
                let meal = Meal(
                    timestamp: date,
                    mealType: .breakfast,
                    items: ["Oatmeal", "Banana"], // Same items
                    healthScore: 0.8
                )
                let snapshot = DailySmileySnapshot(
                    id: UUID(),
                    date: date,
                    smileyState: .neutral,
                    meals: [meal],
                    mealCount: 1,
                    averageHealthScore: 0.8
                )
                self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)
            }

            // When: Get recent unique meals
            let recentMeals = self.sut.getRecentUniqueMeals()

            // Then: Should deduplicate and return only 1 unique meal
            XCTAssertEqual(recentMeals.count, 1)
            XCTAssertEqual(recentMeals.first?.items, ["Oatmeal", "Banana"])
        }

        func test_getRecentUniqueMeals_returnsEmptyWhenNoHistory() {
            // Given: No historical data (mockHistorical starts empty)

            // When: Get recent unique meals
            let recentMeals = self.sut.getRecentUniqueMeals()

            // Then: Should return empty array
            XCTAssertTrue(recentMeals.isEmpty)
        }

        func test_copyMealToToday_createsNewMealWithTodayTimestamp() throws {
            // Given: A historical meal
            let historicalDate = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024
            let historicalMeal = Meal(
                timestamp: historicalDate,
                mealType: .lunch,
                items: ["Salad", "Chicken"],
                healthScore: 0.85
            )

            // When: Copy meal to today
            let beforeCopy = Date()
            self.sut.copyMealToToday(historicalMeal)
            let afterCopy = Date()

            // Then: New meal should have today's timestamp
            let copiedMeal = try XCTUnwrap(self.sut.meals.first)
            XCTAssertGreaterThanOrEqual(copiedMeal.timestamp, beforeCopy)
            XCTAssertLessThanOrEqual(copiedMeal.timestamp, afterCopy)
            XCTAssertNotEqual(copiedMeal.timestamp, historicalDate)
        }

        func test_copyMealToToday_preservesItemsAndMealType() throws {
            // Given: A historical meal with specific items and type
            let historicalMeal = Meal(
                timestamp: Date(timeIntervalSince1970: 1_704_067_200),
                mealType: .dinner,
                items: ["Pizza", "Salad", "Soda"],
                healthScore: 0.4
            )

            // When: Copy meal to today
            self.sut.copyMealToToday(historicalMeal)

            // Then: Items and meal type should be preserved
            let copiedMeal = try XCTUnwrap(self.sut.meals.first)
            XCTAssertEqual(copiedMeal.items, ["Pizza", "Salad", "Soda"])
            XCTAssertEqual(copiedMeal.mealType, .dinner)
            // ID should be different (new meal)
            XCTAssertNotEqual(copiedMeal.id, historicalMeal.id)
        }

        // MARK: - Tests: Mind Check (Phase 3)

        func test_saveMorningMindCheck_updatesHistoricalData() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .todo, text: "Buy groceries", timestamp: Date(), context: .morning)
            ]

            // Act
            self.sut.saveMorningMindCheck(entries)

            // Assert
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNotNil(snapshot?.morningMindCheck)
            XCTAssertEqual(snapshot?.morningMindCheck?.count, 1)
        }

        func test_saveEveningMindCheck_updatesHistoricalData() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .accomplished, text: "Finished work", timestamp: Date(), context: .evening)
            ]

            // Act
            self.sut.saveEveningMindCheck(entries)

            // Assert
            let snapshot = self.mockHistorical.getSnapshot(for: Date())
            XCTAssertNotNil(snapshot?.eveningMindCheck)
            XCTAssertEqual(snapshot?.eveningMindCheck?.count, 1)
        }

        func test_todaysMorningMindCheck_returnsEntriesWhenLogged() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .gratitude, text: "Family", timestamp: Date(), context: .morning)
            ]
            self.sut.saveMorningMindCheck(entries)

            // Assert
            XCTAssertNotNil(self.sut.todaysMorningMindCheck)
            XCTAssertEqual(self.sut.todaysMorningMindCheck?.count, 1)
        }

        func test_todaysEveningMindCheck_returnsEntriesWhenLogged() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .letGo, text: "Stress", timestamp: Date(), context: .evening)
            ]
            self.sut.saveEveningMindCheck(entries)

            // Assert
            XCTAssertNotNil(self.sut.todaysEveningMindCheck)
            XCTAssertEqual(self.sut.todaysEveningMindCheck?.count, 1)
        }

        // MARK: - AI Analysis Score Update Tests (Regression Prevention)

        /// Regression test: Verifies that meal healthScore is correctly updated after AI analysis completes.
        /// This test catches the bug where in-place array mutation didn't trigger SwiftUI view updates,
        /// causing the UI to display the local score (e.g., 50%) instead of the AI score (e.g., 80%).
        func test_performDeepAnalysis_updatesHealthScoreFromAI() async throws {
            // Given: Create ViewModel with AI-capable mock service
            let mockAILogic = RegressionTestAIMock()
            mockAILogic.localScore = 0.5 // Local calculation returns 50%
            mockAILogic.aiScore = 0.8 // AI returns 80%
            mockAILogic.nextState = SmileyState(scale: 0.9, mood: .serene)

            let viewModel = MainViewModel(
                logicService: mockAILogic,
                persistenceService: self.mockPersistence,
                historicalService: self.mockHistorical
            )

            // When: Create a meal (will get local score initially)
            viewModel.createNewMeal()
            let mealId = try XCTUnwrap(viewModel.meals.first?.id)
            viewModel.updateMealItems(mealId, items: ["Healthy Smoothie"])

            // Initial score should be local score (50%)
            XCTAssertEqual(viewModel.meals.first?.healthScore ?? 0, 0.5, accuracy: 0.01)

            // Wait for async AI analysis to complete
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Then: Score should be updated to AI score (80%)
            let updatedScore = try XCTUnwrap(viewModel.meals.first?.healthScore)
            XCTAssertEqual(
                updatedScore,
                0.8,
                accuracy: 0.01,
                "Health score should be updated to AI score (0.8), not local score (0.5)"
            )
            XCTAssertTrue(viewModel.meals.first?.isAIAnalyzed ?? false, "Meal should be marked as AI analyzed")
            XCTAssertEqual(mockAILogic.analyzeCallCount, 1, "AI analysis should be called exactly once")
        }

        /// Test that AI analysis failure gracefully falls back without crashing
        func test_performDeepAnalysis_handlesFailureGracefully() async throws {
            // Given: Create ViewModel with failing AI service
            let mockAILogic = RegressionTestAIMock()
            mockAILogic.localScore = 0.5
            mockAILogic.shouldFail = true

            let viewModel = MainViewModel(
                logicService: mockAILogic,
                persistenceService: self.mockPersistence,
                historicalService: self.mockHistorical
            )

            // When: Create a meal and trigger AI analysis
            viewModel.createNewMeal()
            let mealId = try XCTUnwrap(viewModel.meals.first?.id)
            viewModel.updateMealItems(mealId, items: ["Test Meal"])

            // Wait for async analysis to fail
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Then: Should still have local score, not crash
            let score = try XCTUnwrap(viewModel.meals.first?.healthScore)
            XCTAssertEqual(score, 0.5, accuracy: 0.01, "Should retain local score after AI failure")
            XCTAssertFalse(
                viewModel.meals.first?.isAIAnalyzed ?? true,
                "Should not be marked as AI analyzed after failure"
            )
        }

        /// Test that duplicate AI analysis requests are prevented
        func test_performDeepAnalysis_preventsDuplicateRequests() async throws {
            // Given: Create ViewModel with AI service
            let mockAILogic = RegressionTestAIMock()
            mockAILogic.localScore = 0.5
            mockAILogic.aiScore = 0.8

            let viewModel = MainViewModel(
                logicService: mockAILogic,
                persistenceService: self.mockPersistence,
                historicalService: self.mockHistorical
            )

            // When: Create meal and update items multiple times rapidly
            viewModel.createNewMeal()
            let mealId = try XCTUnwrap(viewModel.meals.first?.id)

            // Rapid updates that would trigger multiple analysis requests
            viewModel.updateMealItems(mealId, items: ["Meal v1"])

            // Wait for first analysis to complete
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Update again (should skip since already analyzed)
            let preCount = mockAILogic.analyzeCallCount
            viewModel.updateMealItems(mealId, items: ["Meal v1"]) // Same items

            try await Task.sleep(nanoseconds: 50_000_000) // 50ms

            // Then: Should not trigger another analysis for same items
            XCTAssertEqual(mockAILogic.analyzeCallCount, preCount, "Should skip analysis when items haven't changed")
        }
    }

    // MARK: - Regression Test Mock for AI Score Update Bug

    /// Mock AI service for regression testing that verifies @Published array triggers UI updates.
    /// This mock simulates the async AI analysis flow with configurable local vs AI scores.
    /// Named uniquely to avoid conflict with MockAILogicService in MainViewModelAIAnalysisTests.
    @MainActor
    class RegressionTestAIMock: MealLogicProvider, AIAnalysisProvider {
        var localScore: Double = 0.5
        var aiScore: Double = 0.8
        var aiMood: SmileyMood = .serene
        var aiSound: String = "chime"
        var aiInsight: String? = "Test insight"
        var nextState = SmileyState.neutral
        var analyzeCallCount = 0
        var shouldFail = false

        func calculateHealthScore(for _: String) -> Double {
            self.localScore
        }

        func calculateHealthScore(for items: [String]) -> Double {
            guard !items.isEmpty else { return 0.5 }
            return self.localScore
        }

        func calculateNextState(from _: SmileyState, healthScore _: Double) -> SmileyState {
            self.nextState
        }

        func analyzeMealQuality(description _: String) async throws -> (
            score: Double,
            mood: SmileyMood,
            sound: String,
            insight: String?
        ) {
            self.analyzeCallCount += 1
            if self.shouldFail {
                throw NSError(domain: "AI", code: 1, userInfo: [NSLocalizedDescriptionKey: "AI analysis failed"])
            }
            // Simulate network delay
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return (self.aiScore, self.aiMood, self.aiSound, self.aiInsight)
        }
    }

#endif
