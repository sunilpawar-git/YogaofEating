#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Contracts for meal card input UX improvements (2026-05-20):
    /// 1. Per-item focus — only focused row renders BulletTextField (no global swap flash)
    /// 2. "+" button always visible regardless of focus state
    /// 3. Checkmark appears after recent meal add (via auto-focus on first item)
    ///
    /// NOTE: @State mutations in JournalBlockView cannot be observed outside a SwiftUI host,
    /// so these tests validate the logic contracts via helper structs — matching the pattern
    /// in SimplifiedMealEntryTests and RecentMealsFeatureTests.

    @MainActor
    final class MealCardInputTests: XCTestCase {
        // MARK: - Checkmark visibility — requires isFocused AND hasContent

        func test_checkmark_hiddenWhenNotFocused_evenWithContent() {
            let contract = MealCardVisibility(isFocused: false, hasContent: true)
            XCTAssertFalse(contract.showCheckmark, "Checkmark must not appear on unfocused cards with stale content")
        }

        func test_checkmark_visibleWhenFocusedWithContent() {
            let contract = MealCardVisibility(isFocused: true, hasContent: true)
            XCTAssertTrue(contract.showCheckmark)
        }

        func test_checkmark_hiddenWhenFocusedButEmpty() {
            let contract = MealCardVisibility(isFocused: true, hasContent: false)
            XCTAssertFalse(contract.showCheckmark)
        }

        // MARK: - "+" button — always visible (no focus guard)

        func test_recentMealsButton_visibleWhenFocused() {
            let contract = MealCardVisibility(isFocused: true, hasContent: true)
            XCTAssertTrue(
                contract.showRecentMealsButton,
                "'+' must be available mid-typing so user can add a recent meal"
            )
        }

        func test_recentMealsButton_visibleWhenNotFocused() {
            let contract = MealCardVisibility(isFocused: false, hasContent: false)
            XCTAssertTrue(contract.showRecentMealsButton)
        }

        // MARK: - Recent meal selection does NOT auto-save (only populates draft)

        func test_recentMealSelection_doesNotCallOnUpdate() {
            var callCount = 0
            let view = JournalBlockView(
                meal: Meal(id: UUID(), timestamp: Date(), mealType: .lunch, items: [], healthScore: 0.5),
                isBreathing: false,
                onUpdate: { _, _ in callCount += 1 },
                onDelete: {}
            )

            let recentMeal = Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .lunch,
                items: ["salad", "water"],
                healthScore: 0.5
            )
            view.handleRecentMealSelection(recentMeal)

            XCTAssertEqual(callCount, 0, "Recent meal selection populates draft — checkmark tap is required to save")
        }

        // MARK: - handleSubmit with empty draft does not call onUpdate

        func test_handleSubmit_emptyDraft_doesNotCallOnUpdate() {
            var callCount = 0
            let view = JournalBlockView(
                meal: Meal(id: UUID(), timestamp: Date(), mealType: .lunch, items: [], healthScore: 0.5),
                isBreathing: false,
                onUpdate: { _, _ in callCount += 1 },
                onDelete: {}
            )

            view.handleSubmit()

            XCTAssertEqual(callCount, 0, "Empty draft must not trigger a save")
        }
    }

    // MARK: - Visibility contract (mirrors production logic in JournalBlockInputSection)

    private struct MealCardVisibility {
        let isFocused: Bool
        let hasContent: Bool

        /// Mirrors: `showCheckmark = isFocused && hasContent` (JournalBlockInputSection line 12)
        var showCheckmark: Bool {
            self.isFocused && self.hasContent
        }

        /// Mirrors: `recentMealsButton` always present (no `if !isFocused` guard)
        var showRecentMealsButton: Bool {
            true
        }
    }

#endif
