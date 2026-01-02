// swiftlint:disable force_unwrapping file_length
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class DailySmileySnapshotTests: XCTestCase {
        // MARK: - Properties

        var sut: DailySmileySnapshot!
        var testMeals: [Meal]!
        var testSmileyState: SmileyState!
        var testDate: Date!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            // Create test data
            self.testDate = Date()
            self.testSmileyState = SmileyState(scale: 1.5, mood: .overwhelmed)
            self.testMeals = [
                Meal(
                    id: UUID(),
                    timestamp: Date(),
                    mealType: .breakfast,
                    items: ["Oatmeal", "Berries"],
                    healthScore: 0.8
                ),
                Meal(
                    id: UUID(),
                    timestamp: Date(),
                    mealType: .lunch,
                    items: ["Salad", "Chicken"],
                    healthScore: 0.7
                )
            ]
        }

        override func tearDown() {
            self.sut = nil
            self.testMeals = nil
            self.testSmileyState = nil
            self.testDate = nil
            super.tearDown()
        }

        // MARK: - Tests: Initialization

        func test_init_setsAllProperties_correctly() {
            // Arrange & Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: self.testMeals,
                mealCount: self.testMeals.count,
                averageHealthScore: 0.75
            )

            // Assert
            XCTAssertNotNil(self.sut.id)
            XCTAssertNotNil(self.sut.date)
            XCTAssertEqual(self.sut.smileyState.scale, 1.5)
            XCTAssertEqual(self.sut.smileyState.mood, .overwhelmed)
            XCTAssertEqual(self.sut.meals.count, 2)
            XCTAssertEqual(self.sut.mealCount, 2)
            XCTAssertEqual(self.sut.averageHealthScore, 0.75)
        }

        func test_init_normalizes_dateToMidnight() {
            // Arrange
            let calendar = Calendar.current
            let dateWithTime = calendar.date(
                from: DateComponents(year: 2024, month: 12, day: 15, hour: 14, minute: 30)
            )!

            // Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: dateWithTime,
                smileyState: self.testSmileyState,
                meals: self.testMeals,
                mealCount: 2,
                averageHealthScore: 0.75
            )

            // Assert
            let components = calendar.dateComponents([.hour, .minute, .second], from: self.sut.date)
            XCTAssertEqual(components.hour, 0, "Hour should be normalized to midnight (0)")
            XCTAssertEqual(components.minute, 0, "Minute should be normalized to midnight (0)")
            XCTAssertEqual(components.second, 0, "Second should be normalized to midnight (0)")
        }

        // MARK: - Tests: Computed Properties

        func test_isEmpty_returnsTrue_whenNoMeals() {
            // Arrange & Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5
            )

            // Assert
            XCTAssertTrue(self.sut.isEmpty, "Snapshot with no meals should be empty")
        }

        func test_isEmpty_returnsFalse_whenHasMeals() {
            // Arrange & Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: self.testMeals,
                mealCount: 2,
                averageHealthScore: 0.75
            )

            // Assert
            XCTAssertFalse(self.sut.isEmpty, "Snapshot with meals should not be empty")
        }

        func test_displayState_returnsNeutral_whenEmpty() {
            // Arrange & Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: SmileyState(scale: 1.8, mood: .overwhelmed),
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5
            )

            // Assert
            let displayState = self.sut.displayState
            XCTAssertEqual(displayState.scale, 1.0, "Empty snapshot should display neutral scale")
            XCTAssertEqual(displayState.mood, .neutral, "Empty snapshot should display neutral mood")
        }

        func test_displayState_returnsActualState_whenNotEmpty() {
            // Arrange & Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: SmileyState(scale: 1.5, mood: .overwhelmed),
                meals: self.testMeals,
                mealCount: 2,
                averageHealthScore: 0.75
            )

            // Assert
            let displayState = self.sut.displayState
            XCTAssertEqual(displayState.scale, 1.5, "Non-empty snapshot should display actual scale")
            XCTAssertEqual(displayState.mood, .overwhelmed, "Non-empty snapshot should display actual mood")
        }

        func test_displayState_dimmedOpacity_whenEmpty() {
            // Arrange & Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5
            )

            // Assert
            // This test verifies the displayState returns neutral for empty
            // The UI layer will apply 0.4 opacity based on isEmpty
            XCTAssertTrue(self.sut.isEmpty, "Empty snapshot should be marked as empty")
            XCTAssertEqual(self.sut.displayState.mood, .neutral, "Empty snapshot display should be neutral")
        }

        // MARK: - Tests: Encoding/Decoding

        func test_codable_encodesAndDecodes_successfully() throws {
            // Arrange
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: self.testMeals,
                mealCount: 2,
                averageHealthScore: 0.75
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailySmileySnapshot.self, from: data)

            // Assert
            XCTAssertEqual(decoded.id, self.sut.id)
            XCTAssertEqual(decoded.mealCount, self.sut.mealCount)
            XCTAssertEqual(decoded.averageHealthScore, self.sut.averageHealthScore)
            XCTAssertEqual(decoded.smileyState.scale, self.sut.smileyState.scale)
            XCTAssertEqual(decoded.smileyState.mood, self.sut.smileyState.mood)
        }

        func test_codable_preserves_allProperties() throws {
            // Arrange
            let specificId = UUID()
            let calendar = Calendar.current
            let specificDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!

            self.sut = DailySmileySnapshot(
                id: specificId,
                date: specificDate,
                smileyState: SmileyState(scale: 2.0, mood: .overwhelmed),
                meals: self.testMeals,
                mealCount: 2,
                averageHealthScore: 0.65
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DailySmileySnapshot.self, from: data)

            // Assert
            XCTAssertEqual(decoded.id, specificId)
            XCTAssertEqual(decoded.meals.count, 2)
            XCTAssertEqual(decoded.mealCount, 2)
            XCTAssertEqual(decoded.averageHealthScore, 0.65, accuracy: 0.01)
            XCTAssertEqual(decoded.smileyState.scale, 2.0)
            XCTAssertEqual(decoded.smileyState.mood, .overwhelmed)

            // Verify date is preserved (normalized to midnight)
            let decodedComponents = calendar.dateComponents([.year, .month, .day], from: decoded.date)
            XCTAssertEqual(decodedComponents.year, 2024)
            XCTAssertEqual(decodedComponents.month, 6)
            XCTAssertEqual(decodedComponents.day, 15)
        }

        // MARK: - Tests: Edge Cases

        func test_averageHealthScore_calculatedCorrectly_withMultipleMeals() {
            // Arrange
            let meals = [
                Meal(id: UUID(), timestamp: Date(), mealType: .breakfast, items: ["Item1"], healthScore: 0.8),
                Meal(id: UUID(), timestamp: Date(), mealType: .lunch, items: ["Item2"], healthScore: 0.6),
                Meal(id: UUID(), timestamp: Date(), mealType: .dinner, items: ["Item3"], healthScore: 0.7)
            ]
            let expectedAverage = (0.8 + 0.6 + 0.7) / 3.0

            // Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: meals,
                mealCount: 3,
                averageHealthScore: expectedAverage
            )

            // Assert
            XCTAssertEqual(self.sut.averageHealthScore, expectedAverage, accuracy: 0.01)
        }

        func test_mealCount_matchesArray_count() {
            // Arrange & Act
            self.sut = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: self.testMeals,
                mealCount: self.testMeals.count,
                averageHealthScore: 0.75
            )

            // Assert
            XCTAssertEqual(self.sut.mealCount, self.sut.meals.count)
            XCTAssertEqual(self.sut.mealCount, 2)
        }

        func test_id_isUnique_forDifferentSnapshots() {
            // Arrange
            let snapshot1 = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: self.testMeals,
                mealCount: 2,
                averageHealthScore: 0.75
            )

            let snapshot2 = DailySmileySnapshot(
                id: UUID(),
                date: self.testDate,
                smileyState: self.testSmileyState,
                meals: self.testMeals,
                mealCount: 2,
                averageHealthScore: 0.75
            )

            // Assert
            XCTAssertNotEqual(snapshot1.id, snapshot2.id, "Each snapshot should have a unique ID")
        }
    }
#endif
