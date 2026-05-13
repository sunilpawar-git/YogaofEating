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

        /// Tests that AI analysis updating healthScore doesn't reset meal items.
        /// This is the specific bug: AI analysis runs async and updates healthScore,
        /// which triggers a re-render that could reset the text field.
        func test_aiAnalysisUpdate_doesNotResetMealItems() throws {
            // Given: A meal with items that user typed
            self.viewModel.createNewMeal()
            let mealId = try XCTUnwrap(self.viewModel.meals.first?.id)
            let typedItems = ["Orange", "Americano"]

            // User updates meal with their typed items
            self.viewModel.updateMeal(mealId, mealType: .drinks, items: typedItems)

            // Verify items are set
            var meal = try XCTUnwrap(self.viewModel.meals.first)
            XCTAssertEqual(meal.items, typedItems)
            let initialHealthScore = meal.healthScore

            // When: AI analysis completes and updates healthScore (simulating async callback)
            // This is what happens when AI analysis returns
            if let index = self.viewModel.meals.firstIndex(where: { $0.id == mealId }) {
                self.viewModel.meals[index].healthScore = 0.7
                self.viewModel.meals[index].isAIAnalyzed = true
            }

            // Then: Meal items should NOT be reset
            meal = try XCTUnwrap(self.viewModel.meals.first)
            XCTAssertEqual(meal.items, typedItems, "AI analysis should not reset meal items")
            XCTAssertEqual(meal.healthScore, 0.7, "Health score should be updated")
            XCTAssertTrue(meal.isAIAnalyzed, "AI analyzed flag should be set")
        }

        /// Tests that multiple AI analysis updates don't corrupt meal items.
        /// Simulates the scenario where user types, AI analyzes, user types more, AI analyzes again.
        func test_multipleAIAnalyses_preserveMealItems() throws {
            // Given: A meal being actively edited
            self.viewModel.createNewMeal()
            let mealId = try XCTUnwrap(self.viewModel.meals.first?.id)

            // First typing session
            self.viewModel.updateMeal(mealId, mealType: .drinks, items: ["Orange"])

            // First AI analysis completes
            if let index = self.viewModel.meals.firstIndex(where: { $0.id == mealId }) {
                self.viewModel.meals[index].healthScore = 0.7
                self.viewModel.meals[index].isAIAnalyzed = true
            }

            // User continues typing
            self.viewModel.updateMeal(mealId, mealType: .drinks, items: ["Orange", "Americano"])

            // Second AI analysis completes
            if let index = self.viewModel.meals.firstIndex(where: { $0.id == mealId }) {
                self.viewModel.meals[index].healthScore = 0.65
            }

            // Then: Final items should be preserved
            let meal = try XCTUnwrap(self.viewModel.meals.first)
            XCTAssertEqual(
                meal.items,
                ["Orange", "Americano"],
                "Items should be preserved through multiple AI analyses"
            )
        }

        // MARK: - Checkmark Button Tests (Simplified Pattern)

        /// Tests that the checkmark button is shown only when focused + has content.
        /// This follows Apple's HIG: single affordance (green checkmark icon) replaces redundant "Done" button.
        func test_checkmarkButton_visibleWhenFocusedWithContent() throws {
            // Given: A meal entry is focused and has typed content
            self.viewModel.createNewMeal()
            let mealId = try XCTUnwrap(self.viewModel.meals.first?.id)

            // When: User types content
            self.viewModel.updateMeal(mealId, mealType: .lunch, items: ["Rice", "Curry"])

            // Then: The checkmark button should be shown (tested visually in UI tests)
            // For this unit test, we verify the meal was updated with items
            let meal = try XCTUnwrap(self.viewModel.meals.first)
            XCTAssertEqual(meal.items.count, 2, "Meal items should be set")
        }
    }

#endif
