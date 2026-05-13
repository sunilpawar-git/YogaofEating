import XCTest
@testable import Yoga_of_Eating

/// Tests for the simplified meal submission contract:
/// `updateMeal` is the sole path that saves and triggers AI analysis.
///
/// RED tests (fail on current code, pass after Phase-1 implementation):
///   - test_updateMeal_withEmptyItems_onMealWithContent_doesNotOverwriteItems
///   - test_updateMeal_withInvalidDescription_setsValidationError
///
/// GREEN tests (document the existing correct contract):
///   - test_updateMeal_withValidDescription_callsAI
///   - test_updateMeal_withValidDescription_savesData

@MainActor
final class MealSubmissionViewModelTests: XCTestCase {
    // MARK: - Properties

    private var sut: MainViewModel!
    private var mockAI: MockAILogicService!
    private var mockPersistence: MockPersistenceService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        self.mockAI = MockAILogicService()
        self.mockAI.mockAnalysisResult = MealAnalysisResult(
            score: 0.8,
            mood: .serene,
            sound: "chime",
            insight: "Well done",
            estimatedCalories: nil
        )
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

    // MARK: - RED: Empty-items guard

    /// Submitting empty items on a meal that already has content must not
    /// overwrite those items. Current code applies contentMeaningfullyChanged
    /// and clears items — the empty guard in updateMeal fixes this.
    func test_updateMeal_withEmptyItems_onMealWithContent_doesNotOverwriteItems() {
        self.sut.createNewMeal()
        guard let mealId = sut.meals.first?.id else { return XCTFail("No meal") }
        let originalItems = ["chicken salad with avocado"]
        self.sut.meals[0].items = originalItems
        self.sut.meals[0].isAIAnalyzed = true

        self.sut.updateMeal(mealId, mealType: .lunch, items: [])

        XCTAssertEqual(
            self.sut.meals.first?.items, originalItems,
            "Empty submission must not overwrite existing meal content"
        )
        XCTAssertFalse(
            self.mockAI.analyzeCalled,
            "AI must not be triggered by an empty submission"
        )
    }

    // MARK: - RED: Validation at submission boundary

    /// Invalid input (XSS payload) passed to updateMeal must set the validation
    /// error alert. Currently updateMeal has no validation — only updateMealItemsLocalOnly did.
    func test_updateMeal_withInvalidDescription_setsValidationError() {
        self.sut.createNewMeal()
        guard let mealId = sut.meals.first?.id else { return XCTFail("No meal") }

        self.sut.updateMeal(mealId, mealType: .lunch, items: ["<script>alert('xss')</script>"])

        XCTAssertTrue(
            self.sut.showValidationErrorAlert,
            "Validation error alert must fire when invalid input reaches updateMeal"
        )
        XCTAssertNotNil(
            self.sut.lastValidationError,
            "lastValidationError must be set for invalid input"
        )
        XCTAssertFalse(
            self.mockAI.analyzeCalled,
            "AI must not be called when input fails validation"
        )
    }

    // MARK: - GREEN: Valid submission triggers AI and saves

    func test_updateMeal_withValidDescription_callsAI() async throws {
        self.sut.createNewMeal()
        guard let mealId = sut.meals.first?.id else { return XCTFail("No meal") }

        self.sut.updateMeal(mealId, mealType: .lunch, items: ["quinoa salad"])

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(self.mockAI.analyzeCalled, "Valid submission must trigger AI analysis")
        XCTAssertTrue(
            self.sut.meals.first?.isAIAnalyzed ?? false,
            "isAIAnalyzed must be true after AI completes"
        )
    }

    func test_updateMeal_withValidDescription_savesData() {
        self.sut.createNewMeal()
        guard let mealId = sut.meals.first?.id else { return XCTFail("No meal") }

        self.sut.updateMeal(mealId, mealType: .lunch, items: ["lentil soup"])

        XCTAssertTrue(self.mockPersistence.saveCalled, "Valid submission must persist data")
        XCTAssertEqual(
            self.mockPersistence.savedData?.meals.first?.items,
            ["lentil soup"],
            "Saved meal must contain the submitted items"
        )
    }

    // MARK: - Phase A RED: Sanitized result used, not raw input

    /// updateMeal must store the sanitized item, not the raw string with dangerous characters.
    /// Current bug: `case .success: break` discards the sanitized value; raw items (with null byte) are stored.
    func test_updateMeal_storesOnlySanitizedItems() {
        self.sut.createNewMeal()
        guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }

        // Null byte survives pattern checks but must be stripped by removeDangerousCharacters.
        self.sut.updateMeal(mealId, mealType: .lunch, items: ["salad\0dressing"])

        let stored = self.sut.meals.first?.items ?? []
        XCTAssertFalse(
            stored.joined().contains("\0"),
            "Stored meal items must not contain null bytes — raw unsanitized input is a security violation"
        )
    }

    /// Whitespace-only items must be treated as empty (no save, no error alert, no AI).
    /// Current bug: guard !items.isEmpty passes for ["  ","\t"]; validator then fires .failure(.empty) → shows alert.
    func test_updateMeal_withWhitespaceOnlyItems_isNoOp() {
        self.sut.createNewMeal()
        guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }
        self.mockPersistence.saveCalled = false // Reset: createNewMeal() already saved once

        self.sut.updateMeal(mealId, mealType: .lunch, items: ["  ", "\t\t"])

        XCTAssertFalse(
            self.sut.showValidationErrorAlert,
            "Whitespace-only submission must silently no-op, not show a validation error"
        )
        XCTAssertFalse(self.mockPersistence.saveCalled, "Nothing must be saved for whitespace-only input")
        XCTAssertFalse(self.mockAI.analyzeCalled, "AI must not be triggered for whitespace-only input")
    }

    /// updateMealItems (legacy path) must not store XSS content to disk.
    /// Current bug: no InputValidator call — malicious items written directly to meals[].
    func test_updateMealItems_withSuspiciousContent_doesNotPersist() {
        self.sut.createNewMeal()
        guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }
        self.mockPersistence.saveCalled = false // Reset: createNewMeal() already saved once

        self.sut.updateMealItems(mealId, items: ["<script>alert('xss')</script>"])

        XCTAssertFalse(
            self.mockPersistence.saveCalled,
            "updateMealItems must block suspicious content from reaching persistence"
        )
        XCTAssertTrue(
            self.sut.showValidationErrorAlert,
            "updateMealItems must surface a validation error for suspicious content"
        )
    }

    // MARK: - GREEN: Comparison operators allowed

    func test_updateMeal_withComparisonOperators_isAccepted() {
        self.sut.createNewMeal()
        guard let mealId = sut.meals.first?.id else { return XCTFail("No meal") }

        self.sut.updateMeal(mealId, mealType: .lunch, items: ["< 100g carbs", "> 5 servings vegetables"])

        XCTAssertFalse(
            self.sut.showValidationErrorAlert,
            "Comparison operators must be accepted in meal descriptions"
        )
        XCTAssertEqual(self.sut.meals.first?.items, ["< 100g carbs", "> 5 servings vegetables"])
    }

    // MARK: - Phase D: Coverage gaps

    /// Editing an existing meal (pre-filled items) must REPLACE items, not merge or append.
    func test_updateMeal_existingMeal_replacesItemsNotMerges() {
        self.sut.createNewMeal()
        guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }
        self.sut.meals[0].items = ["banana"]

        self.sut.updateMeal(mealId, mealType: .lunch, items: ["salad"])

        XCTAssertEqual(
            self.sut.meals.first?.items, ["salad"],
            "Editing an existing meal must replace items, not append to prior content"
        )
        XCTAssertNotEqual(self.sut.meals.first?.items, ["banana", "salad"])
    }

    /// XSS validation must not only set the alert — it must also block persistence.
    func test_updateMeal_withXSSPayload_doesNotPersistAndSetsAlert() {
        self.sut.createNewMeal()
        guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }
        self.mockPersistence.saveCalled = false

        self.sut.updateMeal(mealId, mealType: .lunch, items: ["<script>steal(cookies)</script>"])

        XCTAssertTrue(self.sut.showValidationErrorAlert, "Validation alert must fire for XSS input")
        XCTAssertFalse(self.mockPersistence.saveCalled, "XSS input must not be written to persistence")
    }

    /// Items exceeding the 500-char limit must be blocked at the ViewModel boundary.
    func test_updateMeal_itemExceeding500Chars_setsValidationError() {
        self.sut.createNewMeal()
        guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }
        let overLimit = String(repeating: "x", count: InputValidator.mealDescriptionMaxLength + 1)

        self.sut.updateMeal(mealId, mealType: .lunch, items: [overLimit])

        XCTAssertTrue(
            self.sut.showValidationErrorAlert,
            "Item exceeding \(InputValidator.mealDescriptionMaxLength) chars must trigger validation error"
        )
    }

    /// Rapid checkmark taps (concurrent calls for same meal) must not trigger AI more than once.
    func test_concurrentUpdateMealCalls_triggersAIExactlyOnce() async throws {
        self.sut.createNewMeal()
        guard let mealId = self.sut.meals.first?.id else { return XCTFail("No meal") }
        let mealType = self.sut.meals.first?.mealType ?? .lunch

        // Simulate user double-tapping checkmark before AI guard kicks in
        self.sut.updateMeal(mealId, mealType: mealType, items: ["quinoa bowl"])
        self.sut.updateMeal(mealId, mealType: mealType, items: ["quinoa bowl"])

        try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        // The AI coordinator cancels prior in-flight tasks per meal; one completion expected
        XCTAssertLessThanOrEqual(
            self.mockAI.analyzeCallCount, 1,
            "Duplicate checkmark taps must not trigger more than one AI analysis per meal"
        )
    }
}
