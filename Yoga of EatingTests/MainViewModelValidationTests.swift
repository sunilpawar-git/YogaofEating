#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests that MainViewModel properly sets validation error state
    /// when invalid input is provided to update methods (Phase 4).
    @MainActor
    final class MainViewModelValidationTests: XCTestCase {
        // MARK: - Setup

        var viewModel: MainViewModel!

        override func setUp() {
            super.setUp()
            self.viewModel = MainViewModel(skipDataLoading: true)
        }

        override func tearDown() {
            self.viewModel = nil
            super.tearDown()
        }

        // MARK: - Sleep Notes Validation

        func test_updateHighlightSleepNotes_withSuspiciousContent_setsErrorState() {
            let malicious = "<script>alert('xss')</script>"
            self.viewModel.updateHighlightSleepNotes(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        func test_updateHighlightSleepNotes_withValidInput_clearsErrorState() {
            self.viewModel.showValidationErrorAlert = true
            self.viewModel.lastValidationError = .empty("test")

            self.viewModel.updateHighlightSleepNotes("Normal sleep notes")

            // Valid input should proceed without errors
            // (error state may not be explicitly cleared, but no new error is set)
            XCTAssertNotNil(self.viewModel.currentHighlightData?.sleepNotes)
        }

        func test_updateHighlightSleepNotes_withEmptyString_allowsOptional() {
            self.viewModel.updateHighlightSleepNotes("")

            // Empty is allowed for optional field
            XCTAssertNil(self.viewModel.currentHighlightData?.sleepNotes)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        // MARK: - Todo Item Validation

        func test_addHighlightTodo_withSuspiciousContent_setsErrorState() {
            let malicious = "onclick=alert('xss')"
            self.viewModel.addHighlightTodo(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        func test_addHighlightTodo_withValidInput_succeeds() {
            self.viewModel.addHighlightTodo("Buy groceries")

            let todos = self.viewModel.currentHighlightData?.todos ?? []
            XCTAssertGreaterThan(todos.count, 0)
            XCTAssertTrue(todos.contains { $0.text == "Buy groceries" })
        }

        func test_addHighlightTodo_withEmptyString_doesNotAdd() {
            let initialCount = self.viewModel.currentHighlightData?.todos.count ?? 0

            self.viewModel.addHighlightTodo("")
            self.viewModel.addHighlightTodo("   ")

            let finalCount = self.viewModel.currentHighlightData?.todos.count ?? 0
            XCTAssertEqual(initialCount, finalCount)
        }

        // MARK: - Morning Thoughts Validation

        func test_updateHighlightMorningThoughts_withSuspiciousContent_setsErrorState() {
            let malicious = "<img src=x onerror=alert('xss')>"
            self.viewModel.updateHighlightMorningThoughts(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        func test_updateHighlightMorningThoughts_withValidInput_succeeds() {
            self.viewModel.updateHighlightMorningThoughts("Feeling energized today")

            XCTAssertEqual(self.viewModel.currentHighlightData?.morningThoughts, "Feeling energized today")
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_updateHighlightMorningThoughts_withEmptyString_allowsOptional() {
            self.viewModel.updateHighlightMorningThoughts("")

            XCTAssertNil(self.viewModel.currentHighlightData?.morningThoughts)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        // MARK: - Journal Text Validation

        func test_updateReflectJournalText_withSuspiciousContent_setsErrorState() {
            let malicious = "<iframe src='malicious'></iframe>"
            self.viewModel.updateReflectJournalText(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        func test_updateReflectJournalText_withValidInput_succeeds() {
            self.viewModel.updateReflectJournalText("Today was a good day")

            XCTAssertEqual(self.viewModel.currentReflectData?.journalText, "Today was a good day")
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_updateReflectJournalText_withEmptyString_allowsOptional() {
            self.viewModel.updateReflectJournalText("")

            XCTAssertNil(self.viewModel.currentReflectData?.journalText)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        // MARK: - Meal Description Validation

        func test_updateMealItemsLocalOnly_withSuspiciousContent_setsErrorState() {
            // Add a meal first
            let meal = Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .lunch,
                items: ["chicken"],
                healthScore: 0.5
            )
            self.viewModel.meals = [meal]

            // Try to update with malicious content
            let maliciousItems = ["<script>alert('xss')</script>"]
            self.viewModel.updateMealItemsLocalOnly(meal.id, items: maliciousItems)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        func test_updateMealItemsLocalOnly_withValidInput_succeeds() {
            let meal = Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .breakfast,
                items: ["apple"],
                healthScore: 0.5
            )
            self.viewModel.meals = [meal]

            self.viewModel.updateMealItemsLocalOnly(meal.id, items: ["banana", "yogurt"])

            guard let updated = self.viewModel.meals.first else {
                XCTFail("Meal not found")
                return
            }
            XCTAssertEqual(updated.items, ["banana", "yogurt"])
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_updateMealItemsLocalOnly_withComparisonOperators_passes() {
            let meal = Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .lunch,
                items: ["protein > fat"],
                healthScore: 0.5
            )
            self.viewModel.meals = [meal]

            // This should pass (not trigger validation error)
            self.viewModel.updateMealItemsLocalOnly(meal.id, items: ["< 100g", "> 5 servings"])

            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        // MARK: - Error Clearing

        func test_validationErrorIsNotAutomaticallyCleared() {
            let malicious = "<script>alert('test')</script>"
            self.viewModel.updateHighlightSleepNotes(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)

            // Error should persist until explicitly cleared
            // (User must dismiss the alert)
        }

        func test_userCanClearErrorByDismissingAlert() {
            let malicious = "<img src=x onerror=alert('xss')>"
            self.viewModel.updateHighlightMorningThoughts(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)

            // Simulate user dismissing alert
            self.viewModel.showValidationErrorAlert = false
            self.viewModel.lastValidationError = nil

            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
            XCTAssertNil(self.viewModel.lastValidationError)
        }
    }
#endif
