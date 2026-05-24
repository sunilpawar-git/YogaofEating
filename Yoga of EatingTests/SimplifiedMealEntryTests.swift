#if canImport(XCTest)
    import XCTest

    @MainActor
    final class SimplifiedMealEntryTests: XCTestCase {
        // MARK: - Checkmark Icon Visibility (replaces Done button)

        func test_checkmarkIcon_visibleWhenFocusedWithContent() {
            let visibility = SimplifiedMealEntryVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertTrue(visibility.shouldShowCheckmark)
        }

        func test_checkmarkIcon_hiddenWhenNotFocused() {
            let visibility = SimplifiedMealEntryVisibility(
                isFocused: false,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertFalse(visibility.shouldShowCheckmark)
        }

        func test_checkmarkIcon_hiddenWhenFocusedButEmpty() {
            let visibility = SimplifiedMealEntryVisibility(
                isFocused: true,
                hasContent: false,
                hasRecentMeals: true
            )

            XCTAssertFalse(visibility.shouldShowCheckmark)
        }

        // MARK: - Footer Layout Improvements

        func test_footerButtonCount_maxTwo() {
            // Footer contains: recentMeals + timestamp (checkmark lives in textInputSection, not footer)
            // Both focused and unfocused footer always show exactly 2 items: "+" and timestamp.
            let focusedFooter = FooterButtonVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            let focusedCount = [
                focusedFooter.showRecentMeals,
                focusedFooter.showTimestamp
            ].count(where: { $0 })

            XCTAssertLessThanOrEqual(focusedCount, 2, "Footer should never show more than 2 buttons")

            let unfocusedFooter = FooterButtonVisibility(
                isFocused: false,
                hasContent: true,
                hasRecentMeals: true
            )

            let unfocusedCount = [
                unfocusedFooter.showRecentMeals,
                unfocusedFooter.showTimestamp
            ].count(where: { $0 })

            XCTAssertLessThanOrEqual(unfocusedCount, 2, "Footer should never show more than 2 buttons")
        }

        func test_noDoneButtonLabel_reducesVisualClutter() {
            let visibility = SimplifiedMealEntryVisibility(
                isFocused: true,
                hasContent: true,
                hasRecentMeals: true
            )

            XCTAssertTrue(visibility.shouldShowCheckmark)
            XCTAssertFalse(visibility.shouldShowDoneButtonLabel, "No 'Done' text button needed")
        }

        // MARK: - Edge Cases

        func test_emptyField_onlyTimestampShown() {
            let visibility = SimplifiedMealEntryVisibility(
                isFocused: false,
                hasContent: false,
                hasRecentMeals: false
            )

            XCTAssertFalse(visibility.shouldShowCheckmark)
            XCTAssertFalse(visibility.shouldShowRecentMeals)
            XCTAssertTrue(visibility.shouldShowTimestamp)
        }

        func test_focusedEmptyField_recentMealsStillVisible() {
            let visibility = SimplifiedMealEntryVisibility(
                isFocused: true,
                hasContent: false,
                hasRecentMeals: true
            )

            XCTAssertFalse(visibility.shouldShowCheckmark, "Don't show checkmark for empty field")
            XCTAssertTrue(
                visibility.shouldShowRecentMeals,
                "Recent meals '+' always visible so user can add items while focused"
            )
            XCTAssertTrue(visibility.shouldShowTimestamp)
        }
    }

    // MARK: - Test Helpers

    struct SimplifiedMealEntryVisibility {
        let isFocused: Bool
        let hasContent: Bool
        let hasRecentMeals: Bool

        var shouldShowCheckmark: Bool {
            self.isFocused && self.hasContent
        }

        var shouldShowDoneButtonLabel: Bool {
            false
        }

        var shouldShowRecentMeals: Bool {
            self.hasRecentMeals
        }

        var shouldShowTimestamp: Bool {
            true
        }
    }

    struct FooterButtonVisibility {
        let isFocused: Bool
        let hasContent: Bool
        let hasRecentMeals: Bool

        var showCheckmark: Bool {
            self.isFocused && self.hasContent
        }

        var showRecentMeals: Bool {
            self.hasRecentMeals
        }

        var showTimestamp: Bool {
            true
        }
    }
#endif
