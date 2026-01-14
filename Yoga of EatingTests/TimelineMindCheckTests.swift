// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for Mind Check integration in the timeline
    /// Phase 5: TDD - Tests written before implementation
    @MainActor
    final class TimelineMindCheckTests: XCTestCase {
        // MARK: - Properties

        var viewModel: MainViewModel!
        var mockHistorical: MockHistoricalDataService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockHistorical = MockHistoricalDataService()
            self.viewModel = MainViewModel(
                logicService: MockMealLogicService(),
                persistenceService: MockPersistenceService(),
                historicalService: self.mockHistorical
            )
        }

        override func tearDown() {
            self.viewModel = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Tests: Morning Mind Check Pill Placement

        func test_morningMindCheckPill_showsAfterSleepQualityLogged() {
            // Arrange: Log sleep quality
            self.viewModel.saveSleepQuality(.good)

            // Assert: Pill should show
            XCTAssertTrue(self.viewModel.showMorningMindCheckPill)
        }

        func test_morningMindCheckPill_hidesAfterMindCheckLogged() {
            // Arrange: Log sleep quality and mind check
            self.viewModel.saveSleepQuality(.good)
            let entries = [
                MindCheckEntry(category: .todo, text: "Task", timestamp: Date(), context: .morning)
            ]
            self.viewModel.saveMorningMindCheck(entries)

            // Assert: Pill should hide
            XCTAssertFalse(self.viewModel.showMorningMindCheckPill)
        }

        // MARK: - Tests: Evening Mind Check Pill Placement

        func test_eveningMindCheckPill_showsWhenMealsExist() {
            // Arrange: Create a meal
            self.viewModel.createNewMeal()

            // Assert: Pill should show
            XCTAssertTrue(self.viewModel.showEveningMindCheckPill)
        }

        func test_eveningMindCheckPill_hidesAfterMindCheckLogged() {
            // Arrange: Create a meal and log evening mind check
            self.viewModel.createNewMeal()
            let entries = [
                MindCheckEntry(category: .accomplished, text: "Done", timestamp: Date(), context: .evening)
            ]
            self.viewModel.saveEveningMindCheck(entries)

            // Assert: Pill should hide
            XCTAssertFalse(self.viewModel.showEveningMindCheckPill)
        }

        // MARK: - Tests: Mind Check Badge Display

        func test_morningMindCheckBadge_showsAfterLogging() {
            // Arrange: Log morning mind check
            let entries = [
                MindCheckEntry(category: .todo, text: "Task", timestamp: Date(), context: .morning)
            ]
            self.viewModel.saveMorningMindCheck(entries)

            // Assert: Badge data should be available
            XCTAssertNotNil(self.viewModel.todaysMorningMindCheck)
            XCTAssertEqual(self.viewModel.todaysMorningMindCheck?.count, 1)
        }

        func test_eveningMindCheckBadge_showsAfterLogging() {
            // Arrange: Log evening mind check
            let entries = [
                MindCheckEntry(category: .accomplished, text: "Done", timestamp: Date(), context: .evening)
            ]
            self.viewModel.saveEveningMindCheck(entries)

            // Assert: Badge data should be available
            XCTAssertNotNil(self.viewModel.todaysEveningMindCheck)
            XCTAssertEqual(self.viewModel.todaysEveningMindCheck?.count, 1)
        }

        // MARK: - Tests: Sheet Triggers

        func test_openMorningMindCheckSheet_setsSheetState() {
            // Act
            self.viewModel.showMorningMindCheckSheet = true

            // Assert
            XCTAssertTrue(self.viewModel.showMorningMindCheckSheet)
        }

        func test_openEveningMindCheckSheet_setsSheetState() {
            // Act
            self.viewModel.showEveningMindCheckSheet = true

            // Assert
            XCTAssertTrue(self.viewModel.showEveningMindCheckSheet)
        }

        func test_completeMorningMindCheck_closesSheetAndSavesData() {
            // Arrange
            self.viewModel.showMorningMindCheckSheet = true
            let entries = [
                MindCheckEntry(category: .gratitude, text: "Family", timestamp: Date(), context: .morning)
            ]

            // Act
            self.viewModel.completeMorningMindCheckInput(entries)

            // Assert
            XCTAssertFalse(self.viewModel.showMorningMindCheckSheet)
            XCTAssertNotNil(self.viewModel.todaysMorningMindCheck)
        }

        func test_completeEveningMindCheck_closesSheetAndSavesData() {
            // Arrange
            self.viewModel.showEveningMindCheckSheet = true
            let entries = [
                MindCheckEntry(category: .letGo, text: "Stress", timestamp: Date(), context: .evening)
            ]

            // Act
            self.viewModel.completeEveningMindCheckInput(entries)

            // Assert
            XCTAssertFalse(self.viewModel.showEveningMindCheckSheet)
            XCTAssertNotNil(self.viewModel.todaysEveningMindCheck)
        }

        // MARK: - Tests: Historical Day Mind Check Display (Phase 1)

        func test_historicalSnapshot_containsMorningMindCheck() {
            // Given: A snapshot with morning todos
            let testDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let morningEntries = [
                MindCheckEntry(
                    category: .todo,
                    text: "Buy groceries",
                    timestamp: testDate,
                    context: .morning,
                    isAccomplished: true
                ),
                MindCheckEntry(
                    category: .todo,
                    text: "Call mom",
                    timestamp: testDate,
                    context: .morning,
                    isAccomplished: false
                )
            ]
            let snapshot = DailySmileySnapshot.create(
                date: testDate,
                smileyState: .neutral,
                meals: [],
                morningMindCheck: morningEntries
            )

            // Then: Snapshot should contain morning mind check data
            XCTAssertNotNil(snapshot.morningMindCheck)
            XCTAssertEqual(snapshot.morningMindCheck?.count, 2)
            XCTAssertTrue(snapshot.hasMorningMindCheck)
        }

        func test_historicalSnapshot_preservesTodoCompletionStatus() {
            // Given: A snapshot with completed and incomplete todos
            let testDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let morningEntries = [
                MindCheckEntry(
                    category: .todo,
                    text: "Task 1",
                    timestamp: testDate,
                    context: .morning,
                    isAccomplished: true
                ),
                MindCheckEntry(
                    category: .todo,
                    text: "Task 2",
                    timestamp: testDate,
                    context: .morning,
                    isAccomplished: false
                )
            ]
            let snapshot = DailySmileySnapshot.create(
                date: testDate,
                smileyState: .neutral,
                meals: [],
                morningMindCheck: morningEntries
            )

            // Then: Completion status should be preserved
            let todos = snapshot.morningMindCheck ?? []
            let completedTodos = todos.filter { $0.isAccomplished == true }
            let incompleteTodos = todos.filter { $0.isAccomplished == false }

            XCTAssertEqual(completedTodos.count, 1)
            XCTAssertEqual(incompleteTodos.count, 1)
            XCTAssertEqual(completedTodos.first?.text, "Task 1")
            XCTAssertEqual(incompleteTodos.first?.text, "Task 2")
        }

        func test_historicalSnapshot_containsEveningMindCheck() {
            // Given: A snapshot with evening entries
            let testDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let eveningEntries = [
                MindCheckEntry(
                    category: .gratefulFor,
                    text: "Good health",
                    timestamp: testDate,
                    context: .evening
                )
            ]
            let snapshot = DailySmileySnapshot.create(
                date: testDate,
                smileyState: .neutral,
                meals: [],
                eveningMindCheck: eveningEntries
            )

            // Then: Snapshot should contain evening mind check data
            XCTAssertNotNil(snapshot.eveningMindCheck)
            XCTAssertEqual(snapshot.eveningMindCheck?.count, 1)
            XCTAssertTrue(snapshot.hasEveningMindCheck)
        }

        func test_historicalStrings_exist() {
            // Verify all required strings for historical display exist
            XCTAssertFalse(Strings.MindCheck.Historical.mindCheckSectionTitle.isEmpty)
            XCTAssertFalse(Strings.MindCheck.Historical.morningHeader.isEmpty)
            XCTAssertFalse(Strings.MindCheck.Historical.eveningHeader.isEmpty)
            XCTAssertFalse(Strings.MindCheck.Historical.completed.isEmpty)
            XCTAssertFalse(Strings.MindCheck.Historical.notCompleted.isEmpty)
        }
    }
#endif
