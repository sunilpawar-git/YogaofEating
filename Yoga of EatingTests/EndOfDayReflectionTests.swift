// swiftlint:disable force_unwrapping file_length
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for end-of-day reflection functionality
    /// Phase 3: TDD - Tests written before implementation
    @MainActor
    final class EndOfDayReflectionTests: XCTestCase {
        // MARK: - Properties

        var sut: MainViewModel!
        var mockLogic: MockMealLogicService!
        var mockPersistence: MockPersistenceService!
        var mockHistorical: MockHistoricalDataService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockLogic = MockMealLogicService()
            self.mockPersistence = MockPersistenceService()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = MainViewModel(
                logicService: self.mockLogic,
                persistenceService: self.mockPersistence,
                historicalService: self.mockHistorical
            )
        }

        override func tearDown() {
            self.sut = nil
            self.mockLogic = nil
            self.mockPersistence = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Tests: Reflection Sheet State

        func test_showReflectionSheet_defaultsToFalse() {
            XCTAssertFalse(self.sut.showReflectionSheet)
        }

        func test_showReflectionSheet_canBeToggled() {
            // When
            self.sut.showReflectionSheet = true

            // Then
            XCTAssertTrue(self.sut.showReflectionSheet)
        }

        // MARK: - Tests: Reflection Prompt Logic

        func test_shouldPromptReflection_returnsFalse_beforeEveningHour() {
            // Arrange - Mock time before 8 PM (e.g., 2 PM)
            let calendar = Calendar.current
            let earlyTime = calendar.date(
                bySettingHour: 14,
                minute: 0,
                second: 0,
                of: Date()
            )!

            // When
            let shouldPrompt = self.sut.shouldPromptReflection(at: earlyTime)

            // Then
            XCTAssertFalse(shouldPrompt, "Should not prompt for reflection before evening")
        }

        func test_shouldPromptReflection_returnsFalse_withNoMeals() {
            // Arrange - Evening time but no meals
            let calendar = Calendar.current
            let eveningTime = calendar.date(
                bySettingHour: 20,
                minute: 30,
                second: 0,
                of: Date()
            )!

            // When
            let shouldPrompt = self.sut.shouldPromptReflection(at: eveningTime)

            // Then
            XCTAssertFalse(shouldPrompt, "Should not prompt when no meals logged")
        }

        func test_shouldPromptReflection_returnsTrue_withMealsAfterEveningHour() {
            // Arrange - Evening time with meals
            let calendar = Calendar.current
            let eveningTime = calendar.date(
                bySettingHour: 20,
                minute: 30,
                second: 0,
                of: Date()
            )!
            self.sut.createNewMeal()

            // When
            let shouldPrompt = self.sut.shouldPromptReflection(at: eveningTime)

            // Then
            XCTAssertTrue(shouldPrompt, "Should prompt for reflection in evening with meals")
        }

        func test_shouldPromptReflection_returnsFalse_ifReflectionAlreadyExists() {
            // Arrange - Evening time with meals but reflection already saved
            let calendar = Calendar.current
            let eveningTime = calendar.date(
                bySettingHour: 21,
                minute: 0,
                second: 0,
                of: Date()
            )!
            self.sut.createNewMeal()

            // Save a reflection for today
            let reflection = DailyReflection(feeling: .calm)
            self.sut.saveReflection(reflection)

            // When
            let shouldPrompt = self.sut.shouldPromptReflection(at: eveningTime)

            // Then
            XCTAssertFalse(shouldPrompt, "Should not prompt if reflection already exists")
        }

        // MARK: - Tests: Save Reflection

        func test_saveReflection_callsHistoricalService() {
            // Arrange
            let reflection = DailyReflection(
                feeling: .great,
                sleepQuality: .great,
                note: "Perfect day!"
            )

            // When
            self.sut.saveReflection(reflection)

            // Then
            XCTAssertTrue(self.mockHistorical.updateReflectionCalled)
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.feeling, .great)
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.sleepQuality, .great)
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.note, "Perfect day!")
        }

        func test_saveReflection_savesForCurrentDate() {
            // Arrange
            let reflection = DailyReflection(feeling: .calm)
            let today = Calendar.current.startOfDay(for: Date())

            // When
            self.sut.saveReflection(reflection)

            // Then
            let savedDate = self.mockHistorical.lastReflectionDate
            XCTAssertNotNil(savedDate)
            XCTAssertTrue(Calendar.current.isDate(savedDate!, inSameDayAs: today))
        }

        func test_saveReflection_dismissesSheet() {
            // Arrange
            self.sut.showReflectionSheet = true
            let reflection = DailyReflection(feeling: .ok)

            // When
            self.sut.saveReflection(reflection)

            // Then
            XCTAssertFalse(self.sut.showReflectionSheet, "Sheet should be dismissed after saving")
        }

        // MARK: - Tests: Skip Reflection

        func test_skipReflection_dismissesSheet() {
            // Arrange
            self.sut.showReflectionSheet = true

            // When
            self.sut.skipReflection()

            // Then
            XCTAssertFalse(self.sut.showReflectionSheet, "Sheet should be dismissed after skipping")
        }

        func test_skipReflection_doesNotSaveReflection() {
            // Arrange
            self.sut.showReflectionSheet = true

            // When
            self.sut.skipReflection()

            // Then
            XCTAssertFalse(self.mockHistorical.updateReflectionCalled, "Should not save reflection when skipped")
        }

        // MARK: - Tests: Today's Reflection

        func test_todaysReflection_returnsNil_whenNoReflectionSaved() {
            // When
            let reflection = self.sut.todaysReflection

            // Then
            XCTAssertNil(reflection)
        }

        func test_todaysReflection_returnsReflection_whenSaved() {
            // Arrange
            let savedReflection = DailyReflection(feeling: .calm, sleepQuality: .good)
            self.sut.saveReflection(savedReflection)

            // When
            let reflection = self.sut.todaysReflection

            // Then
            XCTAssertNotNil(reflection)
            XCTAssertEqual(reflection?.feeling, .calm)
            XCTAssertEqual(reflection?.sleepQuality, .good)
        }

        // MARK: - Tests: Evening Hour Configuration

        func test_reflectionPromptHour_defaultsTo20() {
            XCTAssertEqual(MainViewModel.reflectionPromptHour, 20, "Default prompt hour should be 8 PM (20:00)")
        }

        // MARK: - Tests: Edge Cases

        func test_shouldPromptReflection_exactlyAtPromptHour_returnsTrue() {
            // Arrange - Exactly at 8 PM with meals
            let calendar = Calendar.current
            let exactPromptTime = calendar.date(
                bySettingHour: MainViewModel.reflectionPromptHour,
                minute: 0,
                second: 0,
                of: Date()
            )!
            self.sut.createNewMeal()

            // When
            let shouldPrompt = self.sut.shouldPromptReflection(at: exactPromptTime)

            // Then
            XCTAssertTrue(shouldPrompt)
        }

        func test_shouldPromptReflection_justBeforePromptHour_returnsFalse() {
            // Arrange - 7:59 PM with meals
            let calendar = Calendar.current
            let justBefore = calendar.date(
                bySettingHour: MainViewModel.reflectionPromptHour - 1,
                minute: 59,
                second: 59,
                of: Date()
            )!
            self.sut.createNewMeal()

            // When
            let shouldPrompt = self.sut.shouldPromptReflection(at: justBefore)

            // Then
            XCTAssertFalse(shouldPrompt)
        }

        func test_saveReflection_withAllFields_savesCorrectly() {
            // Arrange
            let reflection = DailyReflection(
                feeling: .heavy,
                sleepQuality: .terrible,
                note: "Overate at dinner, feeling sluggish"
            )

            // When
            self.sut.saveReflection(reflection)

            // Then
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.feeling, .heavy)
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.sleepQuality, .terrible)
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.note, "Overate at dinner, feeling sluggish")
        }

        func test_saveReflection_withMinimalFields_savesCorrectly() {
            // Arrange - Only required feeling field
            let reflection = DailyReflection(feeling: .tired)

            // When
            self.sut.saveReflection(reflection)

            // Then
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.feeling, .tired)
            XCTAssertNil(self.mockHistorical.lastUpdatedReflection?.sleepQuality)
            XCTAssertNil(self.mockHistorical.lastUpdatedReflection?.note)
        }

        // MARK: - Tests: Trigger Reflection Prompt

        func test_triggerReflectionPromptIfNeeded_setsShowReflectionSheet_whenConditionsMet() {
            // Arrange - Evening time with meals
            let calendar = Calendar.current
            let eveningTime = calendar.date(
                bySettingHour: 21,
                minute: 0,
                second: 0,
                of: Date()
            )!
            self.sut.createNewMeal()

            // When
            self.sut.triggerReflectionPromptIfNeeded(at: eveningTime)

            // Then
            XCTAssertTrue(self.sut.showReflectionSheet, "Sheet should be shown when conditions are met")
        }

        func test_triggerReflectionPromptIfNeeded_doesNotSetShowReflectionSheet_beforeEveningHour() {
            // Arrange - Afternoon time with meals
            let calendar = Calendar.current
            let afternoonTime = calendar.date(
                bySettingHour: 14,
                minute: 0,
                second: 0,
                of: Date()
            )!
            self.sut.createNewMeal()

            // When
            self.sut.triggerReflectionPromptIfNeeded(at: afternoonTime)

            // Then
            XCTAssertFalse(self.sut.showReflectionSheet, "Sheet should not be shown before evening")
        }

        func test_triggerReflectionPromptIfNeeded_doesNotSetShowReflectionSheet_withNoMeals() {
            // Arrange - Evening time but no meals
            let calendar = Calendar.current
            let eveningTime = calendar.date(
                bySettingHour: 21,
                minute: 0,
                second: 0,
                of: Date()
            )!

            // When
            self.sut.triggerReflectionPromptIfNeeded(at: eveningTime)

            // Then
            XCTAssertFalse(self.sut.showReflectionSheet, "Sheet should not be shown with no meals")
        }

        func test_triggerReflectionPromptIfNeeded_doesNotSetShowReflectionSheet_ifReflectionExists() {
            // Arrange - Evening time with meals but reflection already saved
            let calendar = Calendar.current
            let eveningTime = calendar.date(
                bySettingHour: 21,
                minute: 0,
                second: 0,
                of: Date()
            )!
            self.sut.createNewMeal()
            self.sut.saveReflection(DailyReflection(feeling: .calm))

            // When
            self.sut.triggerReflectionPromptIfNeeded(at: eveningTime)

            // Then
            XCTAssertFalse(self.sut.showReflectionSheet, "Sheet should not be shown if reflection exists")
        }
    }
#endif
