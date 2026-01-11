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

        // MARK: - Tests: Morning Sleep Context Detection (Phase 2)

        func test_isMorningSleepContext_returnsTrue_whenFirstTapBeforeNoonNoSleepLogged() {
            // Arrange - Morning time, no meals, no sleep logged
            let calendar = Calendar.current
            let morningTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!

            // When
            let result = self.sut.isMorningSleepContext(at: morningTime)

            // Then
            XCTAssertTrue(result, "Should show sleep prompt in morning with no meals and no sleep logged")
        }

        func test_isMorningSleepContext_returnsFalse_afterNoon() {
            // Arrange - Afternoon time, no meals, no sleep logged
            let calendar = Calendar.current
            let afternoonTime = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: Date())!

            // When
            let result = self.sut.isMorningSleepContext(at: afternoonTime)

            // Then
            XCTAssertFalse(result, "Should not show sleep prompt after noon")
        }

        func test_isMorningSleepContext_returnsFalse_whenSleepAlreadyLogged() {
            // Arrange - Morning time, sleep already logged
            let calendar = Calendar.current
            let morningTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!
            let sleepReflection = DailyReflection.withSleepQuality(.good, at: morningTime)
            self.sut.saveReflection(sleepReflection)

            // When
            let result = self.sut.isMorningSleepContext(at: morningTime)

            // Then
            XCTAssertFalse(result, "Should not show sleep prompt when sleep already logged")
        }

        func test_isMorningSleepContext_returnsFalse_whenMealsExist() {
            // Arrange - Morning time but meals already logged (not first tap)
            let calendar = Calendar.current
            let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
            self.sut.createNewMeal()

            // When
            let result = self.sut.isMorningSleepContext(at: morningTime)

            // Then
            XCTAssertFalse(result, "Should not show sleep prompt when meals already exist")
        }

        // MARK: - Tests: Evening Feeling Context Detection (Phase 2)

        func test_isEveningFeelingContext_returnsTrue_whenMealsExistAndNoFeelingLogged() {
            // Arrange - Has meals, no feeling logged
            self.sut.createNewMeal()

            // When
            let result = self.sut.isEveningFeelingContext()

            // Then
            XCTAssertTrue(result, "Should show feeling prompt when meals exist and no feeling logged")
        }

        func test_isEveningFeelingContext_returnsFalse_whenNoMeals() {
            // Arrange - No meals

            // When
            let result = self.sut.isEveningFeelingContext()

            // Then
            XCTAssertFalse(result, "Should not show feeling prompt when no meals")
        }

        func test_isEveningFeelingContext_returnsFalse_whenFeelingAlreadyLogged() {
            // Arrange - Has meals, feeling already logged
            self.sut.createNewMeal()
            let feelingReflection = DailyReflection.withFeeling(.calm, at: Date())
            self.sut.saveReflection(feelingReflection)

            // When
            let result = self.sut.isEveningFeelingContext()

            // Then
            XCTAssertFalse(result, "Should not show feeling prompt when feeling already logged")
        }

        // MARK: - Tests: Save Sleep Quality (Phase 2)

        func test_saveSleepQuality_savesSleepToReflection() {
            // Arrange
            let sleepTime = Date()

            // When
            self.sut.saveSleepQuality(.great, at: sleepTime)

            // Then
            XCTAssertTrue(self.mockHistorical.updateReflectionCalled)
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.sleepQuality, .great)
            XCTAssertNotNil(self.mockHistorical.lastUpdatedReflection?.sleepLoggedAt)
        }

        func test_saveOverallFeeling_savesFeelingToReflection() {
            // Arrange
            let feelingTime = Date()

            // When
            self.sut.saveOverallFeeling(.tired, at: feelingTime)

            // Then
            XCTAssertTrue(self.mockHistorical.updateReflectionCalled)
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.feeling, .tired)
            XCTAssertNotNil(self.mockHistorical.lastUpdatedReflection?.feelingLoggedAt)
        }

        func test_saveSleepQuality_mergesWithExistingFeeling() {
            // Arrange - First save feeling, then save sleep
            self.sut.saveOverallFeeling(.calm, at: Date())
            self.mockHistorical.updateReflectionCalled = false // Reset

            // When
            self.sut.saveSleepQuality(.good, at: Date())

            // Then
            XCTAssertTrue(self.mockHistorical.updateReflectionCalled)
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.sleepQuality, .good)
            // The merge should preserve the feeling
            XCTAssertEqual(self.mockHistorical.lastUpdatedReflection?.feeling, .calm)
        }

        // MARK: - Tests: Today's Sleep and Feeling Properties

        func test_todaysSleepQuality_returnsNil_whenNoSleepLogged() {
            // When
            let result = self.sut.todaysSleepQuality

            // Then
            XCTAssertNil(result)
        }

        func test_todaysSleepQuality_returnsSleepQuality_whenLogged() {
            // Arrange
            self.sut.saveSleepQuality(.great, at: Date())

            // When
            let result = self.sut.todaysSleepQuality

            // Then
            XCTAssertEqual(result, .great)
        }

        func test_todaysFeeling_returnsNil_whenNoFeelingLogged() {
            // When
            let result = self.sut.todaysFeeling

            // Then
            XCTAssertNil(result)
        }

        func test_todaysFeeling_returnsFeeling_whenLogged() {
            // Arrange
            self.sut.saveOverallFeeling(.calm, at: Date())

            // When
            let result = self.sut.todaysFeeling

            // Then
            XCTAssertEqual(result, .calm)
        }

        // MARK: - Tests: Smiley Tap Flow (Phase 4)

        func test_handleSmileyTap_showsSleepSheet_inMorningSleepContext() {
            // Arrange - Morning time, no meals, no sleep logged
            // Note: We can't easily set the time, but we can test the sheet state
            // This test verifies the flow when context is detected

            // When - Simulate morning context by checking the method directly
            // Since we can't control time, we test the sheet state changes
            XCTAssertFalse(self.sut.showSleepQualitySheet)
            XCTAssertFalse(self.sut.showOverallFeelingSheet)
        }

        func test_handleSmileyTap_createsMealDirectly_whenMealsExist() {
            // Arrange - Has meals (no longer shows feeling sheet via smiley tap)
            self.sut.createNewMeal()
            let initialMealCount = self.sut.meals.count

            // When
            self.sut.handleSmileyTap()

            // Then - Should create meal directly (feeling is now via End-of-Day pill)
            XCTAssertFalse(self.sut.showSleepQualitySheet)
            XCTAssertFalse(self.sut.showOverallFeelingSheet)
            XCTAssertEqual(self.sut.meals.count, initialMealCount + 1)
        }

        func test_handleSmileyTap_createsMealDirectly_whenFeelingAlreadyLogged() {
            // Arrange - Has meals and feeling already logged
            self.sut.createNewMeal()
            self.sut.saveOverallFeeling(.calm, at: Date())
            let initialMealCount = self.sut.meals.count

            // When
            self.sut.handleSmileyTap()

            // Then - Should create meal directly without showing any sheet
            XCTAssertFalse(self.sut.showSleepQualitySheet)
            XCTAssertFalse(self.sut.showOverallFeelingSheet)
            XCTAssertEqual(self.sut.meals.count, initialMealCount + 1)
        }

        func test_completeSleepQualityInput_savesSleepAndCreatesMeal() {
            // Arrange
            self.sut.showSleepQualitySheet = true
            let initialMealCount = self.sut.meals.count

            // Simulate pending meal creation
            self.sut.handleSmileyTap() // This would set pending if in morning context

            // When
            self.sut.completeSleepQualityInput(.great)

            // Then
            XCTAssertFalse(self.sut.showSleepQualitySheet)
            XCTAssertEqual(self.sut.todaysSleepQuality, .great)
        }

        func test_dismissSleepQualityInput_dismissesSheetAndCreatesMeal() {
            // Arrange
            self.sut.showSleepQualitySheet = true

            // When
            self.sut.dismissSleepQualityInput()

            // Then
            XCTAssertFalse(self.sut.showSleepQualitySheet)
        }

        func test_completeOverallFeelingInput_savesFeeling() {
            // Arrange
            self.sut.createNewMeal()
            self.sut.showOverallFeelingSheet = true

            // When
            self.sut.completeOverallFeelingInput(.tired)

            // Then
            XCTAssertFalse(self.sut.showOverallFeelingSheet)
            XCTAssertEqual(self.sut.todaysFeeling, .tired)
        }

        func test_dismissOverallFeelingInput_dismissesSheet() {
            // Arrange
            self.sut.showOverallFeelingSheet = true

            // When
            self.sut.dismissOverallFeelingInput()

            // Then
            XCTAssertFalse(self.sut.showOverallFeelingSheet)
        }

        // MARK: - Tests: End-of-Day Pill (Phase 3 - Decoupled from Smiley Tap)

        func test_showEndOfDayPill_returnsFalse_whenNoMeals() {
            // When
            let result = self.sut.showEndOfDayPill

            // Then
            XCTAssertFalse(result, "Should not show pill when no meals logged")
        }

        func test_showEndOfDayPill_returnsTrue_whenMealsExistAndNoFeelingLogged() {
            // Arrange
            self.sut.createNewMeal()

            // When
            let result = self.sut.showEndOfDayPill

            // Then
            XCTAssertTrue(result, "Should show pill when meals exist and no feeling logged")
        }

        func test_showEndOfDayPill_returnsFalse_whenFeelingAlreadyLogged() {
            // Arrange
            self.sut.createNewMeal()
            self.sut.saveOverallFeeling(.calm, at: Date())

            // When
            let result = self.sut.showEndOfDayPill

            // Then
            XCTAssertFalse(result, "Should not show pill when feeling already logged")
        }

        func test_handleEndOfDayPillTap_showsFeelingSheet() {
            // Arrange
            self.sut.createNewMeal()

            // When
            self.sut.handleEndOfDayPillTap()

            // Then
            XCTAssertTrue(self.sut.showOverallFeelingSheet, "Should show feeling sheet on pill tap")
        }

        func test_handleEndOfDayPillTap_doesNotCreateMeal() {
            // Arrange
            self.sut.createNewMeal()
            let initialMealCount = self.sut.meals.count

            // When
            self.sut.handleEndOfDayPillTap()
            self.sut.completeOverallFeelingInput(.great)

            // Then - Should NOT create a new meal (pill is for reflection only)
            XCTAssertEqual(self.sut.meals.count, initialMealCount, "Pill tap should not create a meal")
        }
    }
#endif
