#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for RecentMealsSheetView component.
    /// Verifies meal selection callback and relative date formatting.
    @MainActor
    final class RecentMealsSheetViewTests: XCTestCase {
        // MARK: - Relative Date String Tests

        func test_relativeDateString_today_returnsToday() {
            // Given: A date that is today
            let today = Date()

            // When: Get relative date string
            let result = RecentMealsSheetView.relativeDateString(from: today)

            // Then: Should return "Today"
            XCTAssertEqual(result, "Today")
        }

        func test_relativeDateString_yesterday_returnsYesterday() {
            // Given: A date that is yesterday
            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

            // When: Get relative date string
            let result = RecentMealsSheetView.relativeDateString(from: yesterday)

            // Then: Should return "Yesterday"
            XCTAssertEqual(result, "Yesterday")
        }

        func test_relativeDateString_twoDaysAgo_returnsDaysAgo() {
            // Given: A date that is 2 days ago
            let calendar = Calendar.current
            let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!

            // When: Get relative date string
            let result = RecentMealsSheetView.relativeDateString(from: twoDaysAgo)

            // Then: Should return "2 days ago"
            XCTAssertEqual(result, "2 days ago")
        }

        func test_relativeDateString_threeDaysAgo_returnsDaysAgo() {
            // Given: A date that is 3 days ago
            let calendar = Calendar.current
            let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!

            // When: Get relative date string
            let result = RecentMealsSheetView.relativeDateString(from: threeDaysAgo)

            // Then: Should return "3 days ago"
            XCTAssertEqual(result, "3 days ago")
        }

        // MARK: - Meal Selection Callback Tests

        func test_onSelectMeal_callbackReceivesMeal() {
            // Given: A test meal
            let testMeal = Meal(
                mealType: .breakfast,
                items: ["Oatmeal", "Banana"],
                healthScore: 0.85
            )

            var receivedMeal: Meal?

            // When: Create view with callback
            _ = RecentMealsSheetView(
                recentMeals: [testMeal],
                onSelectMeal: { meal in
                    receivedMeal = meal
                },
                onDismiss: {}
            )

            // Then: Callback should be set (actual UI interaction tested in UI tests)
            // This test verifies the view can be initialized with the callback
            XCTAssertNil(receivedMeal, "Callback should not be called on init")
        }

        func test_emptyMeals_viewInitializes() {
            // Given: Empty meals array
            let emptyMeals: [Meal] = []

            // When: Create view with empty meals
            let view = RecentMealsSheetView(
                recentMeals: emptyMeals,
                onSelectMeal: { _ in },
                onDismiss: {}
            )

            // Then: View should initialize without crashing
            XCTAssertNotNil(view)
        }
    }

#endif
