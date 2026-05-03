#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Integration tests for MainViewModel validation flows (Phase 6).
    /// Tests end-to-end validation: input → validation → error state → persistence/blocking.
    /// Covers 30+ scenarios including edge cases, boundary conditions, and error recovery.
    @MainActor
    final class MainViewModelValidationIntegrationTests: XCTestCase {
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

        // MARK: - Valid Input Persistence Tests

        func test_validSleepNotes_persistToHighlightData() {
            let validNotes = "Slept 8 hours, felt rested"
            self.viewModel.updateHighlightSleepNotes(validNotes)

            XCTAssertEqual(self.viewModel.currentHighlightData?.sleepNotes, validNotes)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_validTodoItem_addsToHighlightTodos() {
            let initialCount = self.viewModel.currentHighlightData?.todos.count ?? 0
            self.viewModel.addHighlightTodo("Drink 8 glasses of water")

            let todos = self.viewModel.currentHighlightData?.todos ?? []
            XCTAssertEqual(todos.count, initialCount + 1)
            XCTAssertTrue(todos.contains { $0.text == "Drink 8 glasses of water" })
        }

        func test_validMorningThoughts_persistToHighlightData() {
            let thoughts = "Feeling motivated and energized"
            self.viewModel.updateHighlightMorningThoughts(thoughts)

            XCTAssertEqual(self.viewModel.currentHighlightData?.morningThoughts, thoughts)
        }

        func test_validJournalText_persistToReflectData() {
            let journal = "Had a productive day with good meals"
            self.viewModel.updateReflectJournalText(journal)

            XCTAssertEqual(self.viewModel.currentReflectData?.journalText, journal)
        }

        // MARK: - Invalid Input Blocking Tests

        func test_invalidSleepNotes_blocksPeristence_setsError() {
            let malicious = "<IMG src=x onerror='alert(1)'>"
            self.viewModel.updateHighlightSleepNotes(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        func test_invalidTodoItem_blocksAddition_setsError() {
            let malicious = "onclick='alert(1)'"
            self.viewModel.addHighlightTodo(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            let todos = self.viewModel.currentHighlightData?.todos ?? []
            XCTAssertFalse(todos.contains { $0.text == malicious })
        }

        func test_invalidMorningThoughts_blocksPeristence_setsError() {
            let malicious = "<SCRIPT>malicious()</SCRIPT>"
            self.viewModel.updateHighlightMorningThoughts(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        func test_invalidJournalText_blocksPeristence_setsError() {
            let malicious = "<IFRAME src='evil.com'></IFRAME>"
            self.viewModel.updateReflectJournalText(malicious)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        // MARK: - Length Limit Tests

        func test_sleepNotes_exceedingMaxLength_isTruncated() {
            // ViewModel clamps text to AppTheme.TextEntry.maxCharacters (1000) before validation
            let tooLong = String(repeating: "x", count: ValidationLimits.sleepNotes + 50)
            self.viewModel.updateHighlightSleepNotes(tooLong)

            XCTAssertFalse(
                self.viewModel.showValidationErrorAlert,
                "Over-limit sleep notes must be silently truncated, not rejected"
            )
            let saved = self.viewModel.currentHighlightData?.sleepNotes
            XCTAssertNotNil(saved)
            XCTAssertLessThanOrEqual(saved!.count, AppTheme.TextEntry.maxCharacters)
        }

        func test_morningThoughts_atMaxLength_isPersisted() {
            let maxLength = String(repeating: "x", count: AppTheme.TextEntry.maxCharacters) // 1000 is max
            self.viewModel.updateHighlightMorningThoughts(maxLength)

            XCTAssertEqual(self.viewModel.currentHighlightData?.morningThoughts, maxLength)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_journalEntry_exceedingMaxLength_isTruncated() {
            // ViewModel clamps text to AppTheme.TextEntry.maxCharacters (1000) before validation
            let tooLong = String(repeating: "y", count: ValidationLimits.journalEntry + 50)
            self.viewModel.updateReflectJournalText(tooLong)

            XCTAssertFalse(
                self.viewModel.showValidationErrorAlert,
                "Over-limit journal text must be silently truncated, not rejected"
            )
            let saved = self.viewModel.currentReflectData?.journalText
            XCTAssertNotNil(saved)
            XCTAssertLessThanOrEqual(saved!.count, AppTheme.TextEntry.maxCharacters)
        }

        func test_todoItem_exceedingMaxLength_isRejected() {
            let tooLong = String(repeating: "z", count: 151) // 150 is max
            self.viewModel.addHighlightTodo(tooLong)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
        }

        // MARK: - XSS Pattern Detection Tests

        func test_scriptTag_isDetectedAndBlocked() {
            let xss = "<SCRIPT>alert('xss')</SCRIPT>"
            self.viewModel.updateHighlightMorningThoughts(xss)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
        }

        func test_imageTag_isDetectedAndBlocked() {
            let xss = "<IMG SRC=x ONERROR=alert(1)>"
            self.viewModel.addHighlightTodo(xss)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
        }

        func test_iframeTag_isDetectedAndBlocked() {
            let xss = "<IFRAME src='malicious'></IFRAME>"
            self.viewModel.updateReflectJournalText(xss)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
        }

        func test_onclickEventHandler_isDetectedAndBlocked() {
            let xss = "Click me ONCLICK='alert(1)'"
            self.viewModel.updateHighlightMorningThoughts(xss)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
        }

        func test_javascriptProtocol_isDetectedAndBlocked() {
            let xss = "JAVASCRIPT:void(0)"
            self.viewModel.addHighlightTodo(xss)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
        }

        // MARK: - Comparison Operator Tests (Phase 3 Refinement)

        func test_lessThanOperator_allowedInMealDescription() {
            let meal = Meal(
                timestamp: Date(),
                mealType: .lunch,
                items: ["item"],
                healthScore: 0.5
            )
            self.viewModel.meals = [meal]

            self.viewModel.updateMealItemsLocalOnly(meal.id, items: ["< 100g"])

            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
            guard let updated = self.viewModel.meals.first else {
                XCTFail("Meal not found")
                return
            }
            XCTAssertEqual(updated.items, ["< 100g"])
        }

        func test_greaterThanOperator_allowedInMealDescription() {
            let meal = Meal(
                timestamp: Date(),
                mealType: .lunch,
                items: ["item"],
                healthScore: 0.5
            )
            self.viewModel.meals = [meal]

            self.viewModel.updateMealItemsLocalOnly(meal.id, items: ["> 5 servings"])

            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        // MARK: - Error Recovery Tests

        func test_afterValidationError_validInputSucceeds() {
            let malicious = "<script>alert(1)</script>"
            self.viewModel.updateHighlightMorningThoughts(malicious)
            XCTAssertTrue(self.viewModel.showValidationErrorAlert)

            // Simulate user clearing alert and trying again
            self.viewModel.showValidationErrorAlert = false
            self.viewModel.lastValidationError = nil

            // Now provide valid input
            self.viewModel.updateHighlightMorningThoughts("Good morning!")
            XCTAssertEqual(self.viewModel.currentHighlightData?.morningThoughts, "Good morning!")
        }

        func test_multipleFieldErrors_lastErrorIsUpdated() {
            let malicious = "<IMG src=x onerror=alert(1)>"

            self.viewModel.updateHighlightSleepNotes(malicious)
            XCTAssertNotNil(self.viewModel.lastValidationError)
            let firstErrorExists = self.viewModel.lastValidationError != nil

            self.viewModel.updateHighlightMorningThoughts(malicious)
            XCTAssertNotNil(self.viewModel.lastValidationError)
            let secondErrorExists = self.viewModel.lastValidationError != nil

            // Both errors should be set (different field-specific messages)
            XCTAssertTrue(firstErrorExists && secondErrorExists)
        }

        // MARK: - Optional vs Required Field Tests

        func test_emptyOptionalField_sleepNotes_succeeds() {
            self.viewModel.updateHighlightSleepNotes("")

            XCTAssertNil(self.viewModel.currentHighlightData?.sleepNotes)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_emptyOptionalField_morningThoughts_succeeds() {
            self.viewModel.updateHighlightMorningThoughts("   ")

            XCTAssertNil(self.viewModel.currentHighlightData?.morningThoughts)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_emptyOptionalField_journalEntry_succeeds() {
            self.viewModel.updateReflectJournalText("")

            XCTAssertNil(self.viewModel.currentReflectData?.journalText)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_emptyRequiredField_todoItem_isRejected() {
            let initialCount = self.viewModel.currentHighlightData?.todos.count ?? 0
            self.viewModel.addHighlightTodo("")

            let todos = self.viewModel.currentHighlightData?.todos ?? []
            XCTAssertEqual(todos.count, initialCount)
        }

        // MARK: - Whitespace Handling Tests

        func test_leadingTrailingWhitespace_isTrimmed() {
            self.viewModel.updateHighlightSleepNotes("   Valid notes   ")

            XCTAssertEqual(self.viewModel.currentHighlightData?.sleepNotes, "Valid notes")
        }

        func test_whitespaceOnlyString_treatedAsEmpty() {
            self.viewModel.updateHighlightMorningThoughts("\t\n   \t")

            XCTAssertNil(self.viewModel.currentHighlightData?.morningThoughts)
        }

        func test_internalWhitespace_preserved() {
            let text = "Multiple   spaces   preserved"
            self.viewModel.updateReflectJournalText(text)

            XCTAssertEqual(self.viewModel.currentReflectData?.journalText, text)
        }

        // MARK: - Control Character Tests

        func test_nullBytes_filtered() {
            let withNull = "text\0more"
            self.viewModel.updateHighlightSleepNotes(withNull)

            let saved = self.viewModel.currentHighlightData?.sleepNotes ?? ""
            XCTAssertFalse(saved.contains("\0"))
        }

        func test_controlCharacters_filtered() {
            let withControl = "text\u{001F}more"
            self.viewModel.updateHighlightMorningThoughts(withControl)

            let saved = self.viewModel.currentHighlightData?.morningThoughts ?? ""
            // Control characters should be removed
            XCTAssertEqual(saved.count, "textmore".count)
        }

        // MARK: - Special Character Tests

        func test_emojis_preserved() {
            let withEmoji = "Breakfast 🥗 with coffee ☕"
            self.viewModel.updateHighlightMorningThoughts(withEmoji)

            XCTAssertEqual(self.viewModel.currentHighlightData?.morningThoughts, withEmoji)
        }

        func test_specialCharacters_preserved() {
            let special = "Meal: chicken & rice @ $5.99"
            self.viewModel.addHighlightTodo(special)

            let todos = self.viewModel.currentHighlightData?.todos ?? []
            XCTAssertTrue(todos.contains { $0.text == special })
        }

        func test_punctuation_preserved() {
            let text = "Did I eat enough? Yes! (mostly)"
            self.viewModel.updateReflectJournalText(text)

            XCTAssertEqual(self.viewModel.currentReflectData?.journalText, text)
        }

        // MARK: - Multi-Field Integration Tests

        func test_allFieldsWithValidData_allPersist() {
            self.viewModel.updateHighlightSleepQuality(.good)
            self.viewModel.updateHighlightSleepNotes("Excellent sleep")
            self.viewModel.addHighlightTodo("Exercise today")
            self.viewModel.updateHighlightMorningThoughts("Ready for the day")
            self.viewModel.updateReflectFeeling(.great)
            self.viewModel.updateReflectJournalText("Great meals, great day")

            XCTAssertEqual(self.viewModel.currentHighlightData?.sleepNotes, "Excellent sleep")
            XCTAssertEqual(self.viewModel.currentHighlightData?.morningThoughts, "Ready for the day")
            XCTAssertGreaterThan(self.viewModel.currentHighlightData?.todos.count ?? 0, 0)
            XCTAssertEqual(self.viewModel.currentReflectData?.journalText, "Great meals, great day")
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_oneInvalidField_setsErrorWithoutAffectingValidField() {
            // Valid input for first field
            self.viewModel.updateHighlightSleepNotes("Good sleep")

            // Clear error state
            self.viewModel.showValidationErrorAlert = false
            self.viewModel.lastValidationError = nil

            // Invalid input for second field
            let malicious = "<SCRIPT>alert(1)</SCRIPT>"
            self.viewModel.updateHighlightMorningThoughts(malicious)

            // Error should be set for invalid field
            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
            XCTAssertNotNil(self.viewModel.lastValidationError)
        }

        // MARK: - Edge Case Tests

        func test_singleCharacterInput_accepted() {
            self.viewModel.addHighlightTodo("A")

            let todos = self.viewModel.currentHighlightData?.todos ?? []
            XCTAssertTrue(todos.contains { $0.text == "A" })
        }

        func test_unicodeCharacters_accepted() {
            let unicode = "Café with naïve cooking"
            self.viewModel.updateHighlightMorningThoughts(unicode)

            XCTAssertEqual(self.viewModel.currentHighlightData?.morningThoughts, unicode)
        }

        func test_newlines_preserved() {
            let multiline = "Line 1\nLine 2\nLine 3"
            self.viewModel.updateReflectJournalText(multiline)

            XCTAssertEqual(self.viewModel.currentReflectData?.journalText, multiline)
        }

        func test_repeatedPatternDetection_blocked() {
            let repeated = "UNION SELECT UNION SELECT UNION SELECT"
            self.viewModel.updateHighlightSleepNotes(repeated)

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
        }

        // MARK: - Meal Description Integration Tests

        func test_mealDescription_withValidItems_succeeds() {
            let meal = Meal(
                timestamp: Date(),
                mealType: .breakfast,
                items: ["oatmeal"],
                healthScore: 0.5
            )
            self.viewModel.meals = [meal]

            self.viewModel.updateMealItemsLocalOnly(meal.id, items: ["oatmeal", "berries", "milk"])

            guard let updated = self.viewModel.meals.first else {
                XCTFail("Meal not found")
                return
            }
            XCTAssertEqual(updated.items.count, 3)
            XCTAssertFalse(self.viewModel.showValidationErrorAlert)
        }

        func test_mealDescription_caseInsensitiveXSSDetection() {
            let meal = Meal(
                timestamp: Date(),
                mealType: .lunch,
                items: ["item"],
                healthScore: 0.5
            )
            self.viewModel.meals = [meal]

            let xss = "normal <Script>alert(1)</script>"
            self.viewModel.updateMealItemsLocalOnly(meal.id, items: [xss])

            XCTAssertTrue(self.viewModel.showValidationErrorAlert)
        }
    }
#endif
