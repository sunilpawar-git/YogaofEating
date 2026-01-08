#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for JournalBlockView state management during smiley updates.
    /// These tests verify that meal items are preserved when smiley state changes
    /// during text input (which was causing text to vanish).
    @MainActor
    final class JournalBlockViewTests: XCTestCase {
        var viewModel: MainViewModel!
        var mockLogic: MockMealLogicService!
        var mockPersistence: MockPersistenceService!
        var mockHistorical: MockHistoricalDataService!

        override func setUp() {
            super.setUp()
            self.mockLogic = MockMealLogicService()
            self.mockPersistence = MockPersistenceService()
            self.mockHistorical = MockHistoricalDataService()
            self.viewModel = MainViewModel(
                logicService: self.mockLogic,
                persistenceService: self.mockPersistence,
                historicalService: self.mockHistorical
            )
        }

        override func tearDown() {
            self.viewModel = nil
            self.mockLogic = nil
            self.mockPersistence = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Bug Reproduction: Text Vanishing During Smiley State Change

        /// Tests that meal items are preserved when smiley state changes during update.
        /// This reproduces the bug where typing in the callout box causes text to vanish
        /// because smiley state change triggers parent view re-render.
        func test_updateMeal_preservesItems_whenSmileyStateChanges() throws {
            // Given: A meal with text that user is "typing"
            self.viewModel.createNewMeal()
            let mealId = try XCTUnwrap(self.viewModel.meals.first?.id)
            let typedItems = ["Bhaats", "Dal"]

            // Simulate initial smiley state
            self.mockLogic.nextState = SmileyState(scale: 1.0, mood: .neutral)

            // When: User updates meal (which triggers smiley state change)
            self.mockLogic.mockScore = 0.7
            self.mockLogic.nextState = SmileyState(scale: 0.9, mood: .serene)
            self.viewModel.updateMeal(mealId, mealType: .dinner, items: typedItems)

            // Then: Meal items should be preserved after smiley state update
            let updatedMeal = try XCTUnwrap(self.viewModel.meals.first)
            XCTAssertEqual(updatedMeal.items, typedItems, "Meal items should be preserved after smiley state change")
            XCTAssertEqual(self.viewModel.smileyState.mood, .serene, "Smiley state should have updated")
        }

        /// Tests that rapid sequential updates don't lose meal items.
        /// Simulates user typing quickly where each keystroke triggers an update.
        func test_rapidMealUpdates_preserveLatestItems() throws {
            // Given: A meal being actively edited
            self.viewModel.createNewMeal()
            let mealId = try XCTUnwrap(self.viewModel.meals.first?.id)

            // When: Simulate rapid updates (like debounced typing)
            let sequences = [
                ["B"],
                ["Bh"],
                ["Bha"],
                ["Bhaa"],
                ["Bhaat"],
                ["Bhaats"]
            ]

            for items in sequences {
                self.mockLogic.mockScore = Double.random(in: 0.3...0.9) // Varying scores
                self.mockLogic.nextState = SmileyState(
                    scale: Double.random(in: 0.8...1.2),
                    mood: [.serene, .neutral, .overwhelmed].randomElement()!
                )
                self.viewModel.updateMeal(mealId, mealType: .dinner, items: items)
            }

            // Then: Final items should be the last update
            let finalMeal = try XCTUnwrap(self.viewModel.meals.first)
            XCTAssertEqual(finalMeal.items, ["Bhaats"], "Should preserve the final typed text")
        }

        /// Tests that updating meal items doesn't reset them to previous values.
        /// This tests the specific bug where local @State rawText could be reset.
        func test_mealItems_notResetAfterSmileyStateChange() throws {
            // Given: A meal with initial items
            self.viewModel.createNewMeal()
            let mealId = try XCTUnwrap(self.viewModel.meals.first?.id)

            // First update with initial items
            self.viewModel.updateMeal(mealId, mealType: .breakfast, items: ["Coffee"])

            // Capture the smiley state after first update
            let stateAfterFirst = self.viewModel.smileyState

            // When: Update with new items (simulating continued typing)
            let newItems = ["Coffee", "Toast", "Eggs"]
            self.mockLogic.mockScore = 0.85
            self.mockLogic.nextState = SmileyState(scale: 0.85, mood: .serene)
            self.viewModel.updateMeal(mealId, mealType: .breakfast, items: newItems)

            // Then: New items should be saved, not reverted to old state
            let finalMeal = try XCTUnwrap(self.viewModel.meals.first)
            XCTAssertEqual(finalMeal.items, newItems, "Items should be the new values, not reset to previous")
            XCTAssertNotEqual(finalMeal.items, ["Coffee"], "Items should not be reset to first update")

            // And smiley state should have changed
            XCTAssertNotEqual(
                self.viewModel.smileyState.scale,
                stateAfterFirst.scale,
                "Smiley state should have updated"
            )
        }

        /// Tests that meal items persisted to storage match in-memory items.
        func test_mealItemsSynced_betweenMemoryAndPersistence() throws {
            // Given: A meal being updated
            self.viewModel.createNewMeal()
            let mealId = try XCTUnwrap(self.viewModel.meals.first?.id)
            let expectedItems = ["Rice", "Curry", "Raita"]

            // When: Update meal
            self.viewModel.updateMeal(mealId, mealType: .lunch, items: expectedItems)

            // Then: Both in-memory and persisted data should match
            let inMemoryItems = self.viewModel.meals.first?.items
            let persistedItems = self.mockPersistence.savedData?.meals.first?.items

            XCTAssertEqual(inMemoryItems, expectedItems, "In-memory items should match expected")
            XCTAssertEqual(persistedItems, expectedItems, "Persisted items should match expected")
            XCTAssertEqual(inMemoryItems, persistedItems, "In-memory and persisted items should be identical")
        }
    }

#endif
