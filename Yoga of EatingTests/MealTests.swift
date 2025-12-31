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
    }
#endif
