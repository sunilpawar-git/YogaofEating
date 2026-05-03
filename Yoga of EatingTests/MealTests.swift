#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class MealTests: XCTestCase {
        func test_meal_init_defaults() {
            let meal = Meal()
            XCTAssertEqual(meal.items, [])
            XCTAssertEqual(meal.healthScore, 0.0, "New meal should have 0.0 default score (unanalyzed)")
            XCTAssertFalse(meal.isAIAnalyzed, "New meal should not be AI analyzed")
            // Auto-detected type depends on current time, but we can check it has a value
            XCTAssertNotNil(meal.mealType)
        }

        func test_meal_legacyInit_defaults() {
            let meal = Meal(description: "")
            XCTAssertEqual(meal.healthScore, 0.0, "Legacy init should default to 0.0")
            XCTAssertFalse(meal.isAIAnalyzed, "Legacy init should not be AI analyzed")
            XCTAssertNil(meal.aiInsight, "Legacy init should have no insight")
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

        // MARK: - Merge Items Tests (Recent Meal Append Feature)

        func test_mergeItems_emptyExisting_returnsNewItems() {
            let existingItems: [String] = []
            let newItems = ["Oatmeal", "Banana"]

            let merged = MealItemsMerger.merge(existing: existingItems, new: newItems)

            XCTAssertEqual(merged, ["Oatmeal", "Banana"])
        }

        func test_mergeItems_existingItems_appendsNewItems() {
            let existingItems = ["Coffee", "Toast"]
            let newItems = ["Eggs", "Bacon"]

            let merged = MealItemsMerger.merge(existing: existingItems, new: newItems)

            XCTAssertEqual(merged, ["Coffee", "Toast", "Eggs", "Bacon"])
        }

        func test_mergeItems_duplicateItems_areNotAdded() {
            let existingItems = ["Coffee", "Toast"]
            let newItems = ["Coffee", "Eggs"] // Coffee is duplicate

            let merged = MealItemsMerger.merge(existing: existingItems, new: newItems)

            XCTAssertEqual(merged, ["Coffee", "Toast", "Eggs"])
        }

        func test_mergeItems_caseInsensitiveDuplicates_areNotAdded() {
            let existingItems = ["Coffee", "Toast"]
            let newItems = ["COFFEE", "eggs"] // COFFEE is case-insensitive duplicate

            let merged = MealItemsMerger.merge(existing: existingItems, new: newItems)

            XCTAssertEqual(merged, ["Coffee", "Toast", "eggs"])
        }

        func test_mergeItems_whitespaceVariants_areNotAdded() {
            let existingItems = ["Coffee", "Toast"]
            let newItems = ["  Coffee  ", "Eggs"] // Coffee with whitespace is duplicate

            let merged = MealItemsMerger.merge(existing: existingItems, new: newItems)

            XCTAssertEqual(merged, ["Coffee", "Toast", "Eggs"])
        }

        // MARK: - AI Insight Tests (Phase 5: Gemini LLM Integration)

        func test_meal_aiInsight_defaultsToNil() {
            let meal = Meal()

            XCTAssertNil(meal.aiInsight, "AI insight should default to nil")
        }

        func test_meal_aiInsight_canBeSet() {
            var meal = Meal(mealType: .lunch, items: ["Salad"])
            meal.aiInsight = "High in fiber and vitamins. Great choice for lunch!"

            XCTAssertEqual(meal.aiInsight, "High in fiber and vitamins. Great choice for lunch!")
        }

        func test_meal_aiInsight_serialization_roundtrip() throws {
            var meal = Meal(mealType: .breakfast, items: ["Oatmeal", "Banana"])
            meal.aiInsight = "Excellent breakfast with complex carbs and potassium."
            meal.isAIAnalyzed = true

            // Encode
            let encoder = JSONEncoder()
            let data = try encoder.encode(meal)

            // Decode
            let decoder = JSONDecoder()
            let decodedMeal = try decoder.decode(Meal.self, from: data)

            XCTAssertEqual(decodedMeal.aiInsight, meal.aiInsight)
            XCTAssertTrue(decodedMeal.isAIAnalyzed)
        }

        func test_meal_aiInsight_nilPreserved_afterSerialization() throws {
            let meal = Meal(mealType: .dinner, items: ["Pizza"])
            XCTAssertNil(meal.aiInsight)

            // Encode
            let encoder = JSONEncoder()
            let data = try encoder.encode(meal)

            // Decode
            let decoder = JSONDecoder()
            let decodedMeal = try decoder.decode(Meal.self, from: data)

            XCTAssertNil(decodedMeal.aiInsight, "Nil aiInsight should be preserved after serialization")
        }

        func test_meal_hasAIInsight_computed() {
            var meal = Meal(mealType: .snacks, items: ["Apple"])

            XCTAssertFalse(meal.hasAIInsight, "Should be false when aiInsight is nil")

            meal.aiInsight = "Healthy snack choice."
            XCTAssertTrue(meal.hasAIInsight, "Should be true when aiInsight is set")

            meal.aiInsight = ""
            XCTAssertFalse(meal.hasAIInsight, "Should be false when aiInsight is empty string")
        }
    }
#endif
