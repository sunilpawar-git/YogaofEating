// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for MindCheckService
    /// Phase 3: TDD - Tests written before implementation
    @MainActor
    final class MindCheckServiceTests: XCTestCase {
        // MARK: - Properties

        var sut: MindCheckService!
        var mockHistoricalService: MockHistoricalDataService!
        var testDate: Date!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.testDate = Date()
            self.mockHistoricalService = MockHistoricalDataService()
            self.sut = MindCheckService(historicalService: self.mockHistoricalService)
        }

        override func tearDown() {
            self.sut = nil
            self.mockHistoricalService = nil
            self.testDate = nil
            super.tearDown()
        }

        // MARK: - Tests: Save Morning Mind Check

        func test_saveMorningMindCheck_persistsToSnapshot() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .todo, text: "Buy groceries", timestamp: self.testDate, context: .morning),
                MindCheckEntry(category: .gratitude, text: "My health", timestamp: self.testDate, context: .morning)
            ]

            // Act
            self.sut.saveMorningMindCheck(entries, for: self.testDate)

            // Assert
            let snapshot = self.mockHistoricalService.getSnapshot(for: self.testDate)
            XCTAssertNotNil(snapshot)
            XCTAssertEqual(snapshot?.morningMindCheck?.count, 2)
            XCTAssertEqual(snapshot?.morningMindCheck?.first?.text, "Buy groceries")
        }

        func test_saveMorningMindCheck_mergesWithExistingSnapshot() {
            // Arrange - Create existing snapshot with meals
            let existingSnapshot = DailySmileySnapshotBuilder()
                .withDate(self.testDate)
                .withMeals([MealBuilder().withMealType(.breakfast).withItems(["Oatmeal"]).withScore(0.8).build()])
                .build()
            self.mockHistoricalService.historicalData.addOrUpdate(snapshot: existingSnapshot)

            let entries = [
                MindCheckEntry(category: .todo, text: "Task", timestamp: self.testDate, context: .morning)
            ]

            // Act
            self.sut.saveMorningMindCheck(entries, for: self.testDate)

            // Assert
            let snapshot = self.mockHistoricalService.getSnapshot(for: self.testDate)
            XCTAssertNotNil(snapshot?.morningMindCheck)
            XCTAssertEqual(snapshot?.meals.count, 1, "Existing meals should be preserved")
        }

        // MARK: - Tests: Save Evening Mind Check

        func test_saveEveningMindCheck_persistsToSnapshot() {
            // Arrange
            let entries = [
                MindCheckEntry(
                    category: .accomplished,
                    text: "Finished report",
                    timestamp: self.testDate,
                    context: .evening
                ),
                MindCheckEntry(category: .letGo, text: "Work stress", timestamp: self.testDate, context: .evening)
            ]

            // Act
            self.sut.saveEveningMindCheck(entries, for: self.testDate)

            // Assert
            let snapshot = self.mockHistoricalService.getSnapshot(for: self.testDate)
            XCTAssertNotNil(snapshot)
            XCTAssertEqual(snapshot?.eveningMindCheck?.count, 2)
            XCTAssertEqual(snapshot?.eveningMindCheck?.first?.text, "Finished report")
        }

        // MARK: - Tests: Get Mind Checks

        func test_getMorningMindCheck_returnsEntriesForToday() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .todo, text: "Task 1", timestamp: self.testDate, context: .morning)
            ]
            self.sut.saveMorningMindCheck(entries, for: self.testDate)

            // Act
            let result = self.sut.getMorningMindCheck(for: self.testDate)

            // Assert
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.count, 1)
            XCTAssertEqual(result?.first?.text, "Task 1")
        }

        func test_getMorningMindCheck_returnsNilWhenNotLogged() {
            // Act
            let result = self.sut.getMorningMindCheck(for: self.testDate)

            // Assert
            XCTAssertNil(result)
        }

        func test_getEveningMindCheck_returnsEntriesForToday() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .accomplished, text: "Done", timestamp: self.testDate, context: .evening)
            ]
            self.sut.saveEveningMindCheck(entries, for: self.testDate)

            // Act
            let result = self.sut.getEveningMindCheck(for: self.testDate)

            // Assert
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.count, 1)
        }

        func test_getEveningMindCheck_returnsNilWhenNotLogged() {
            // Act
            let result = self.sut.getEveningMindCheck(for: self.testDate)

            // Assert
            XCTAssertNil(result)
        }

        // MARK: - Tests: Has Mind Check For Today

        func test_hasMorningMindCheckForToday_returnsTrueWhenLogged() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .todo, text: "Task", timestamp: Date(), context: .morning)
            ]
            self.sut.saveMorningMindCheck(entries, for: Date())

            // Act
            let result = self.sut.hasMorningMindCheckForToday()

            // Assert
            XCTAssertTrue(result)
        }

        func test_hasMorningMindCheckForToday_returnsFalseWhenNotLogged() {
            // Act
            let result = self.sut.hasMorningMindCheckForToday()

            // Assert
            XCTAssertFalse(result)
        }

        func test_hasEveningMindCheckForToday_returnsTrueWhenLogged() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .accomplished, text: "Done", timestamp: Date(), context: .evening)
            ]
            self.sut.saveEveningMindCheck(entries, for: Date())

            // Act
            let result = self.sut.hasEveningMindCheckForToday()

            // Assert
            XCTAssertTrue(result)
        }

        func test_hasEveningMindCheckForToday_returnsFalseWhenNotLogged() {
            // Act
            let result = self.sut.hasEveningMindCheckForToday()

            // Assert
            XCTAssertFalse(result)
        }
    }
#endif
