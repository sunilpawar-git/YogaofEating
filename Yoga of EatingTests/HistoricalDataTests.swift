// swiftlint:disable force_unwrapping file_length
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    @MainActor
    final class HistoricalDataTests: XCTestCase {
        // MARK: - Properties

        var sut: HistoricalData!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.sut = HistoricalData()
        }

        override func tearDown() {
            self.sut = nil
            super.tearDown()
        }

        // MARK: - Helper Methods

        private func createTestSnapshot(
            date: Date,
            meals: [Meal] = [],
            smileyState: SmileyState = .neutral
        ) -> DailySmileySnapshot {
            DailySmileySnapshot(
                id: UUID(),
                date: date,
                smileyState: smileyState,
                meals: meals,
                mealCount: meals.count,
                averageHealthScore: meals.isEmpty ? 0.5 : meals.map(\.healthScore).reduce(0, +) / Double(meals.count)
            )
        }

        private func createTestMeal(healthScore: Double = 0.7) -> Meal {
            Meal(
                id: UUID(),
                timestamp: Date(),
                mealType: .lunch,
                items: ["Test meal"],
                healthScore: healthScore
            )
        }

        // MARK: - Tests: Initialization

        func test_init_createsEmpty_dailySnapshots() {
            // Assert
            XCTAssertTrue(
                self.sut.dailySnapshots.isEmpty,
                "Newly initialized HistoricalData should have empty snapshots"
            )
        }

        func test_init_setsNil_lastSyncDate() {
            // Assert
            XCTAssertNil(self.sut.lastSyncDate, "Newly initialized HistoricalData should have nil lastSyncDate")
        }

        // MARK: - Tests: Add/Update

        func test_addSnapshot_addsNew_whenDateNotExists() {
            // Arrange
            let date = Date()
            let snapshot = self.createTestSnapshot(date: date)

            // Act
            self.sut.addOrUpdate(snapshot: snapshot)

            // Assert
            XCTAssertEqual(self.sut.dailySnapshots.count, 1)
            XCTAssertEqual(self.sut.dailySnapshots.first?.id, snapshot.id)
        }

        func test_addSnapshot_updates_whenDateExists() {
            // Arrange
            let date = Date()
            let snapshot1 = self.createTestSnapshot(
                date: date,
                smileyState: SmileyState(scale: 1.0, mood: .neutral)
            )
            let snapshot2 = self.createTestSnapshot(
                date: date,
                smileyState: SmileyState(scale: 1.5, mood: .overwhelmed)
            )

            // Act
            self.sut.addOrUpdate(snapshot: snapshot1)
            XCTAssertEqual(self.sut.dailySnapshots.count, 1)

            self.sut.addOrUpdate(snapshot: snapshot2)

            // Assert
            XCTAssertEqual(self.sut.dailySnapshots.count, 1, "Should still have only 1 snapshot after update")
            XCTAssertEqual(self.sut.dailySnapshots.first?.smileyState.scale, 1.5)
            XCTAssertEqual(self.sut.dailySnapshots.first?.smileyState.mood, .overwhelmed)
        }

        func test_addSnapshot_maintains_sortOrder_descendingByDate() {
            // Arrange
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

            // Act - Add in random order
            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: yesterday))
            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: today))
            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: twoDaysAgo))

            // Assert - Should be sorted newest first
            XCTAssertEqual(self.sut.dailySnapshots.count, 3)
            XCTAssertTrue(
                calendar.isDate(self.sut.dailySnapshots[0].date, inSameDayAs: today),
                "First snapshot should be today"
            )
            XCTAssertTrue(
                calendar.isDate(self.sut.dailySnapshots[1].date, inSameDayAs: yesterday),
                "Second snapshot should be yesterday"
            )
            XCTAssertTrue(
                calendar.isDate(self.sut.dailySnapshots[2].date, inSameDayAs: twoDaysAgo),
                "Third snapshot should be two days ago"
            )
        }

        func test_addSnapshot_preserves_otherSnapshots() {
            // Arrange
            let calendar = Calendar.current
            let date1 = calendar.date(byAdding: .day, value: -1, to: Date())!
            let date2 = calendar.date(byAdding: .day, value: -2, to: Date())!
            let date3 = calendar.date(byAdding: .day, value: -3, to: Date())!

            let snapshot1 = self.createTestSnapshot(date: date1)
            let snapshot2 = self.createTestSnapshot(date: date2)
            let snapshot3 = self.createTestSnapshot(date: date3)

            // Act
            self.sut.addOrUpdate(snapshot: snapshot1)
            self.sut.addOrUpdate(snapshot: snapshot2)
            self.sut.addOrUpdate(snapshot: snapshot3)

            // Assert
            XCTAssertEqual(self.sut.dailySnapshots.count, 3)
            XCTAssertTrue(self.sut.dailySnapshots.contains(where: { $0.id == snapshot1.id }))
            XCTAssertTrue(self.sut.dailySnapshots.contains(where: { $0.id == snapshot2.id }))
            XCTAssertTrue(self.sut.dailySnapshots.contains(where: { $0.id == snapshot3.id }))
        }

        // MARK: - Tests: Retrieval

        func test_snapshotForDate_returnsCorrect_snapshot() {
            // Arrange
            let calendar = Calendar.current
            let targetDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
            let snapshot = self.createTestSnapshot(date: targetDate)

            self.sut.addOrUpdate(snapshot: snapshot)

            // Act
            let retrieved = self.sut.snapshot(for: targetDate)

            // Assert
            XCTAssertNotNil(retrieved)
            XCTAssertEqual(retrieved?.id, snapshot.id)
        }

        func test_snapshotForDate_returnsNil_whenNotFound() {
            // Arrange
            let calendar = Calendar.current
            let existingDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
            let missingDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 20))!

            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: existingDate))

            // Act
            let retrieved = self.sut.snapshot(for: missingDate)

            // Assert
            XCTAssertNil(retrieved, "Should return nil when no snapshot exists for date")
        }

        func test_snapshotsInRange_returnsAll_withinRange() {
            // Arrange
            let calendar = Calendar.current
            let date1 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 10))!
            let date2 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
            let date3 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 20))!

            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: date1))
            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: date2))
            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: date3))

            // Act
            let rangeStart = calendar.date(from: DateComponents(year: 2024, month: 6, day: 12))!
            let rangeEnd = calendar.date(from: DateComponents(year: 2024, month: 6, day: 18))!
            let snapshots = self.sut.snapshots(in: rangeStart...rangeEnd)

            // Assert
            XCTAssertEqual(snapshots.count, 1, "Should return only snapshot within range")
            XCTAssertTrue(calendar.isDate(snapshots[0].date, inSameDayAs: date2))
        }

        func test_snapshotsInRange_excludes_outsideRange() {
            // Arrange
            let calendar = Calendar.current
            let date1 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 10))!
            let date2 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 25))!

            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: date1))
            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: date2))

            // Act
            let rangeStart = calendar.date(from: DateComponents(year: 2024, month: 6, day: 12))!
            let rangeEnd = calendar.date(from: DateComponents(year: 2024, month: 6, day: 18))!
            let snapshots = self.sut.snapshots(in: rangeStart...rangeEnd)

            // Assert
            XCTAssertEqual(snapshots.count, 0, "Should exclude snapshots outside range")
        }

        func test_snapshotsInRange_returnsEmpty_whenNoMatches() {
            // Arrange
            let calendar = Calendar.current
            let existingDate = calendar.date(from: DateComponents(year: 2024, month: 5, day: 15))!
            self.sut.addOrUpdate(snapshot: self.createTestSnapshot(date: existingDate))

            // Act
            let rangeStart = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1))!
            let rangeEnd = calendar.date(from: DateComponents(year: 2024, month: 6, day: 30))!
            let snapshots = self.sut.snapshots(in: rangeStart...rangeEnd)

            // Assert
            XCTAssertTrue(snapshots.isEmpty, "Should return empty array when no matches in range")
        }

        // MARK: - Tests: Edge Cases

        func test_multipleSnapshots_differentDays_storedCorrectly() {
            // Arrange
            let calendar = Calendar.current
            let snapshots = (1...10).map { day in
                self.createTestSnapshot(
                    date: calendar.date(from: DateComponents(year: 2024, month: 6, day: day))!
                )
            }

            // Act
            snapshots.forEach { self.sut.addOrUpdate(snapshot: $0) }

            // Assert
            XCTAssertEqual(self.sut.dailySnapshots.count, 10)
        }

        func test_codable_encodesAndDecodes_successfully() throws {
            // Arrange
            let calendar = Calendar.current
            let date = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
            let snapshot = self.createTestSnapshot(
                date: date,
                meals: [self.createTestMeal()],
                smileyState: SmileyState(scale: 1.5, mood: .overwhelmed)
            )

            self.sut.addOrUpdate(snapshot: snapshot)
            self.sut.lastSyncDate = Date()

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(HistoricalData.self, from: data)

            // Assert
            XCTAssertEqual(decoded.dailySnapshots.count, 1)
            XCTAssertNotNil(decoded.lastSyncDate)
        }

        func test_codable_preserves_allSnapshots() throws {
            // Arrange
            let calendar = Calendar.current
            let snapshots = [
                self.createTestSnapshot(date: calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!),
                self.createTestSnapshot(date: calendar.date(from: DateComponents(year: 2024, month: 6, day: 16))!),
                self.createTestSnapshot(date: calendar.date(from: DateComponents(year: 2024, month: 6, day: 17))!)
            ]

            snapshots.forEach { self.sut.addOrUpdate(snapshot: $0) }

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sut)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(HistoricalData.self, from: data)

            // Assert
            XCTAssertEqual(decoded.dailySnapshots.count, 3)
            for snapshot in snapshots {
                XCTAssertTrue(decoded.dailySnapshots.contains(where: { $0.id == snapshot.id }))
            }
        }

        func test_largeDataset_100Snapshots_performsWell() {
            // Arrange
            let calendar = Calendar.current
            let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!

            // Act
            measure {
                for day in 1...100 {
                    let date = calendar.date(byAdding: .day, value: day, to: startDate)!
                    let snapshot = self.createTestSnapshot(date: date)
                    self.sut.addOrUpdate(snapshot: snapshot)
                }
            }

            // Assert
            XCTAssertEqual(self.sut.dailySnapshots.count, 100)
        }
    }
#endif
