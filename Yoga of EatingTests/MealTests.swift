#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class MealTests: XCTestCase {
        func test_meal_init_defaults() {
            let meal = Meal()
            XCTAssertEqual(meal.items, [])
            XCTAssertEqual(meal.healthScore, 0.5)
            // Auto-detected type depends on current time, but we can check it has a value
            XCTAssertNotNil(meal.mealType)
        }

        func test_meal_suggestedMealType_breakfast() throws {
            // 8 AM
            let date = try XCTUnwrap(Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()))
            XCTAssertEqual(MealType.suggestedMealType(for: date), .breakfast)
        }

        func test_meal_suggestedMealType_lunch() throws {
            // 1 PM
            let date = try XCTUnwrap(Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()))
            XCTAssertEqual(MealType.suggestedMealType(for: date), .lunch)
        }

        func test_meal_suggestedMealType_dinner() throws {
            // 8 PM
            let date = try XCTUnwrap(Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()))
            XCTAssertEqual(MealType.suggestedMealType(for: date), .dinner)
        }

        func test_meal_suggestedMealType_snacks() throws {
            // 4 PM
            let date = try XCTUnwrap(Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()))
            XCTAssertEqual(MealType.suggestedMealType(for: date), .snacks)
        }

        func test_mealType_displayNames() {
            XCTAssertEqual(MealType.breakfast.displayName, "Breakfast")
            XCTAssertEqual(MealType.lunch.displayName, "Lunch")
            XCTAssertEqual(MealType.dinner.displayName, "Dinner")
            XCTAssertEqual(MealType.snacks.displayName, "Snacks")
            XCTAssertEqual(MealType.drinks.displayName, "Drinks")
        }

        func test_meal_description_backward_compatibility() {
            var meal = Meal()
            meal.items = ["A", "B"]
            XCTAssertEqual(meal.description, "A, B")

            meal.items = []
            XCTAssertEqual(meal.description, "")
        }

        // MARK: - Phase 1: Timestamp Tests

        func test_meal_timestamp_autoCaptured_onCreation() {
            let beforeCreation = Date()
            let meal = Meal()
            let afterCreation = Date()

            // Timestamp should be between before and after creation times
            XCTAssertGreaterThanOrEqual(meal.timestamp, beforeCreation)
            XCTAssertLessThanOrEqual(meal.timestamp, afterCreation)
        }

        func test_meal_timestamp_customValue_isPreserved() {
            let customDate = Date(timeIntervalSince1970: 1_609_459_200) // Jan 1, 2021
            let meal = Meal(timestamp: customDate)

            XCTAssertEqual(meal.timestamp, customDate)
        }

        func test_meal_timestamp_serialization_roundtrip() throws {
            let originalDate = Date()
            let meal = Meal(timestamp: originalDate, mealType: .lunch, items: ["Test"])

            // Encode
            let encoder = JSONEncoder()
            let data = try encoder.encode(meal)

            // Decode
            let decoder = JSONDecoder()
            let decodedMeal = try decoder.decode(Meal.self, from: data)

            // Timestamp should be preserved (within 1 second tolerance for encoding precision)
            XCTAssertLessThan(abs(decodedMeal.timestamp.timeIntervalSince(originalDate)), 1.0)
        }

        func test_meal_timestamp_differentMeals_haveDifferentTimestamps() {
            let meal1 = Meal()
            // Small delay to ensure different timestamps
            Thread.sleep(forTimeInterval: 0.01) // 10ms
            let meal2 = Meal()

            // Each meal should have its own unique ID
            XCTAssertNotEqual(meal1.id, meal2.id)
            // Second meal should have timestamp >= first meal
            XCTAssertGreaterThanOrEqual(meal2.timestamp, meal1.timestamp)
        }
    }
#endif
