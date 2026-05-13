#if canImport(XCTest)
    import XCTest

    @MainActor
    final class MealActionButtonVisibilityTests: XCTestCase {
        // MARK: - Done Button Visibility

        func test_doneButton_visibleWhenFocused() {
            let visibility = MealActionButtonVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertTrue(visibility.shouldShowDoneButton)
        }

        func test_doneButton_hiddenWhenNotFocused() {
            let visibility = MealActionButtonVisibility(
                isFocused: false,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertFalse(visibility.shouldShowDoneButton)
        }

        func test_doneButton_hiddenWhenFocusedButNoContent() {
            let visibility = MealActionButtonVisibility(
                isFocused: true,
                hasContent: false,
                hasRecentMeals: true
            )

            XCTAssertFalse(visibility.shouldShowDoneButton)
        }

        // MARK: - Recent Meals Button Visibility

        func test_recentMealsButton_hiddenWhenFocused() {
            let visibility = MealActionButtonVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertFalse(visibility.shouldShowRecentMealsButton)
        }

        func test_recentMealsButton_visibleWhenNotFocusedAndHasRecents() {
            let visibility = MealActionButtonVisibility(
                isFocused: false,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertTrue(visibility.shouldShowRecentMealsButton)
        }

        // Button is visible even when recentMeals is empty — sheet shows "No recent meals".
        func test_recentMealsButton_visibleWhenNotFocusedAndNoRecents() {
            let visibility = MealActionButtonVisibility(
                isFocused: false,
                hasContent: true,
                hasRecentMeals: false
            )

            XCTAssertTrue(visibility.shouldShowRecentMealsButton)
        }

        // MARK: - Timestamp Button Visibility

        func test_timestampButton_alwaysVisible() {
            let focusedState = MealActionButtonVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            let unfocusedState = MealActionButtonVisibility(
                isFocused: false,
                hasContent: false,
                hasRecentMeals: false
            )

            XCTAssertTrue(focusedState.shouldShowTimestampButton)
            XCTAssertTrue(unfocusedState.shouldShowTimestampButton)
        }

        // MARK: - Mutual Exclusion: Never More Than 2 Buttons

        func test_neverShowMoreThanTwoButtonsSimultaneously() {
            // When focused: Done button + timestamp button (no recent meals)
            let focusedState = MealActionButtonVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            let focusedButtonCount = [
                focusedState.shouldShowDoneButton,
                focusedState.shouldShowRecentMealsButton,
                focusedState.shouldShowTimestampButton
            ].count(where: { $0 })

            XCTAssertLessThanOrEqual(focusedButtonCount, 2, "Should never show more than 2 buttons when focused")

            // When unfocused: timestamp button + recent meals button (no done)
            let unfocusedState = MealActionButtonVisibility(
                isFocused: false,
                hasContent: true,
                hasRecentMeals: true
            )

            let unfocusedButtonCount = [
                unfocusedState.shouldShowDoneButton,
                unfocusedState.shouldShowRecentMealsButton,
                unfocusedState.shouldShowTimestampButton
            ].count(where: { $0 })

            XCTAssertLessThanOrEqual(unfocusedButtonCount, 2, "Should never show more than 2 buttons when unfocused")
        }

        // MARK: - Focus State Transitions

        func test_focusGain_hideRecentMealsShowDone() {
            let unfocused = MealActionButtonVisibility(
                isFocused: false,
                hasContent: true,
                hasRecentMeals: true
            )

            let focused = MealActionButtonVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertTrue(unfocused.shouldShowRecentMealsButton)
            XCTAssertFalse(unfocused.shouldShowDoneButton)

            XCTAssertFalse(focused.shouldShowRecentMealsButton)
            XCTAssertTrue(focused.shouldShowDoneButton)
        }

        func test_focusLoss_hideDoneShowRecentMeals() {
            let focused = MealActionButtonVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            let unfocused = MealActionButtonVisibility(
                isFocused: false,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertTrue(focused.shouldShowDoneButton)
            XCTAssertFalse(focused.shouldShowRecentMealsButton)

            XCTAssertFalse(unfocused.shouldShowDoneButton)
            XCTAssertTrue(unfocused.shouldShowRecentMealsButton)
        }

        // MARK: - Edge Cases

        func test_emptyTextField_noDoneButton() {
            let visibility = MealActionButtonVisibility(
                isFocused: true,
                hasContent: false,
                hasRecentMeals: true
            )

            XCTAssertFalse(visibility.shouldShowDoneButton, "Don't show Done button when field is empty")
        }

        func test_emptyTextField_stillShowRecentMeals() {
            let visibility = MealActionButtonVisibility(
                isFocused: false,
                hasContent: false,
                hasRecentMeals: true
            )

            XCTAssertTrue(visibility.shouldShowRecentMealsButton, "Show recent meals button even if field is empty")
        }
    }

    // MARK: - Test Helper: MealActionButtonVisibility

    /// Encapsulates button visibility logic for meal cards.
    /// Controls which action buttons appear based on editing state and available content.
    struct MealActionButtonVisibility {
        let isFocused: Bool
        let hasContent: Bool
        let hasRecentMeals: Bool

        /// Done button (checkmark) shown only when focused and has content.
        var shouldShowDoneButton: Bool {
            self.isFocused && self.hasContent
        }

        /// Recent meals (+) button shown whenever not focused.
        /// The sheet handles the empty-data state with a "No recent meals" message.
        var shouldShowRecentMealsButton: Bool {
            !self.isFocused
        }

        /// Timestamp button always shown (critical for user awareness of meal time).
        var shouldShowTimestampButton: Bool {
            true
        }
    }
#endif
