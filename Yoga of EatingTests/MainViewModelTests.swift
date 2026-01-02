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
    }

#endif
