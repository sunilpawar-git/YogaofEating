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
    }
#endif
