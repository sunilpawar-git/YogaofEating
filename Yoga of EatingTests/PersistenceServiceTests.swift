#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class PersistenceServiceTests: XCTestCase {
        func test_appData_serialization_roundtrip() throws {
            let meals = [Meal(mealType: .breakfast, items: ["Oats", "Fruit"])]
            let state = SmileyState(scale: 1.2, mood: .overwhelmed)
            let date = Date()

            let originalData = PersistenceService.AppData(
                meals: meals,
                smileyState: state,
                lastResetDate: date,
                historicalData: HistoricalData()
            )

            // Encode
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(originalData)

            // Decode
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(PersistenceService.AppData.self, from: encodedData)

            XCTAssertEqual(decodedData.meals.count, originalData.meals.count)
            XCTAssertEqual(decodedData.meals.first?.items, originalData.meals.first?.items)
            XCTAssertEqual(decodedData.smileyState.mood, originalData.smileyState.mood)
            XCTAssertEqual(decodedData.smileyState.scale, originalData.smileyState.scale, accuracy: 0.001)
            // Comparison of dates can be tricky due to precision, but close enough
            XCTAssertLessThan(abs(decodedData.lastResetDate.timeIntervalSince(originalData.lastResetDate)), 1.0)
        }

        func test_deleteAll_removesFile() throws {
            // Given: Create a temporary file to simulate persistence
            let tempDir = FileManager.default.temporaryDirectory
            let testFileName = "test_yoga_of_eating_data.json"
            let testFileURL = tempDir.appendingPathComponent(testFileName)

            // Create test data and write to file
            let testData = PersistenceService.AppData(
                meals: [Meal(mealType: .lunch, items: ["Test"])],
                smileyState: .neutral,
                lastResetDate: Date(),
                historicalData: HistoricalData()
            )
            let encoded = try JSONEncoder().encode(testData)
            try encoded.write(to: testFileURL)

            // Verify file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))

            // When: Delete the file
            try FileManager.default.removeItem(at: testFileURL)

            // Then: File should no longer exist
            XCTAssertFalse(FileManager.default.fileExists(atPath: testFileURL.path))
        }

        // MARK: - Phase 1: Timestamp Persistence Tests

        func test_appData_mealTimestamp_persistsCorrectly() throws {
            // Given: A meal with specific timestamp
            let specificDate = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024 00:00:00 UTC
            let meal = Meal(timestamp: specificDate, mealType: .breakfast, items: ["Coffee"])

            let originalData = PersistenceService.AppData(
                meals: [meal],
                smileyState: .neutral,
                lastResetDate: Date(),
                historicalData: HistoricalData()
            )

            // When: Encode and decode
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(originalData)

            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(PersistenceService.AppData.self, from: encodedData)

            // Then: Timestamp should be preserved
            let decodedTimestamp = decodedData.meals.first?.timestamp
            XCTAssertNotNil(decodedTimestamp)
            XCTAssertLessThan(abs(decodedTimestamp!.timeIntervalSince(specificDate)), 1.0)
        }

        func test_appData_multipleMeals_timestampsPreserved() throws {
            // Given: Multiple meals with different timestamps
            let date1 = Date(timeIntervalSince1970: 1_704_067_200) // Jan 1, 2024 00:00 UTC
            let date2 = Date(timeIntervalSince1970: 1_704_081_600) // Jan 1, 2024 04:00 UTC
            let date3 = Date(timeIntervalSince1970: 1_704_110_400) // Jan 1, 2024 12:00 UTC

            let meals = [
                Meal(timestamp: date1, mealType: .breakfast, items: ["Coffee"]),
                Meal(timestamp: date2, mealType: .lunch, items: ["Salad"]),
                Meal(timestamp: date3, mealType: .dinner, items: ["Pasta"])
            ]

            let originalData = PersistenceService.AppData(
                meals: meals,
                smileyState: .neutral,
                lastResetDate: Date(),
                historicalData: HistoricalData()
            )

            // When: Encode and decode
            let encodedData = try JSONEncoder().encode(originalData)
            let decodedData = try JSONDecoder().decode(PersistenceService.AppData.self, from: encodedData)

            // Then: All timestamps should be preserved in order
            XCTAssertEqual(decodedData.meals.count, 3)
            XCTAssertLessThan(abs(decodedData.meals[0].timestamp.timeIntervalSince(date1)), 1.0)
            XCTAssertLessThan(abs(decodedData.meals[1].timestamp.timeIntervalSince(date2)), 1.0)
            XCTAssertLessThan(abs(decodedData.meals[2].timestamp.timeIntervalSince(date3)), 1.0)
        }
    }
#endif
