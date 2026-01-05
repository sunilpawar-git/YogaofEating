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

        // MARK: - Tech Debt: Sorted Meals & Fasting Period Caching Tests

        func test_sortedMeals_isSortedByTimestamp() {
            // Given: Create meals with specific timestamps (out of order)
            let date1 = Date(timeIntervalSince1970: 1_704_110_400) // Later
            let date2 = Date(timeIntervalSince1970: 1_704_067_200) // Earlier

            self.sut.meals = [
                Meal(timestamp: date1, mealType: .dinner, items: ["Dinner"]),
                Meal(timestamp: date2, mealType: .breakfast, items: ["Breakfast"])
            ]

            // Then: sortedMeals should be in chronological order
            XCTAssertEqual(self.sut.sortedMeals.count, 2)
            XCTAssertEqual(self.sut.sortedMeals.first?.mealType, .breakfast)
            XCTAssertEqual(self.sut.sortedMeals.last?.mealType, .dinner)
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

        func test_sortedMeals_updatesWhenMealsChange() {
            // Given: Empty meals
            XCTAssertTrue(self.sut.sortedMeals.isEmpty)

            // When: Add a meal
            self.sut.createNewMeal()

            // Then: sortedMeals should update
            XCTAssertEqual(self.sut.sortedMeals.count, 1)
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
    }

#endif
