import XCTest
@testable import Yoga_of_Eating

/// Integration tests for the Highlight and Reflect text-entry save / restore lifecycle.
///
/// Regression suite for the "text vanishing" bug (same root cause as the old meal card issue):
/// - Debounce fires → ViewModel saves → contract changes → view resets local text
///   while the user is still typing (or immediately after a quality/feeling tap).
///
/// The fix: views only reset local text on `data.date` changes (date navigation),
/// not on any same-day background mutation. These tests verify the full save-restore
/// lifecycle at the ViewModel layer, confirming the contract behaviour the views rely on.
@MainActor
final class HighlightReflectTextEntryIntegrationTests: XCTestCase {
    // MARK: - Properties

    var sut: MainViewModel!
    var mockHistorical: MockHistoricalDataService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.sut = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: self.mockHistorical,
            skipDataLoading: true
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockHistorical = nil
        super.tearDown()
    }

    // MARK: - Highlight: Sleep Notes Save / Restore

    func test_sleepNotes_savedAndRestoredCorrectly() {
        self.sut.updateHighlightSleepNotes("Deep, restful sleep")

        let saved = self.sut.highlightViewData.sleepNotes
        XCTAssertEqual(saved, "Deep, restful sleep")
    }

    func test_sleepNotes_contractReflectsSavedValue_afterSave() {
        self.sut.updateHighlightSleepNotes("Woke up twice")
        let contract = self.sut.highlightViewData
        XCTAssertEqual(contract.sleepNotes, "Woke up twice")
    }

    func test_sleepNotes_emptyString_savesNil() {
        self.sut.updateHighlightSleepNotes("Some notes")
        self.sut.updateHighlightSleepNotes("")
        let saved = self.sut.highlightViewData.sleepNotes
        XCTAssertNil(saved, "Empty sleep notes must be stored as nil, not empty string")
    }

    func test_sleepNotes_savedToday_notVisibleYesterday() {
        self.sut.updateHighlightSleepNotes("Slept 8 hours")

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday

        XCTAssertNil(
            self.sut.highlightViewData.sleepNotes,
            "Today's sleep notes must not bleed into yesterday's contract"
        )
    }

    func test_sleepNotes_savedToday_restoredAfterNavigationAndReturn() {
        self.sut.updateHighlightSleepNotes("Vivid dreams")

        // Navigate to yesterday and back
        self.sut.navigateToPreviousDay()
        self.sut.navigateToNextDay()

        XCTAssertEqual(
            self.sut.highlightViewData.sleepNotes,
            "Vivid dreams",
            "Sleep notes must survive date navigation round-trip"
        )
    }

    // MARK: - Highlight: Morning Thoughts Save / Restore

    func test_morningThoughts_savedAndRestoredCorrectly() {
        self.sut.updateHighlightMorningThoughts("Grateful for the day ahead")

        XCTAssertEqual(
            self.sut.highlightViewData.morningThoughts,
            "Grateful for the day ahead"
        )
    }

    func test_morningThoughts_savedToday_notVisibleYesterday() {
        self.sut.updateHighlightMorningThoughts("Morning clarity")

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday

        XCTAssertNil(
            self.sut.highlightViewData.morningThoughts,
            "Today's morning thoughts must not bleed into yesterday's contract"
        )
    }

    func test_morningThoughts_savedToday_restoredAfterNavigationAndReturn() {
        self.sut.updateHighlightMorningThoughts("Focus on breathing")

        self.sut.navigateToPreviousDay()
        self.sut.navigateToNextDay()

        XCTAssertEqual(
            self.sut.highlightViewData.morningThoughts,
            "Focus on breathing",
            "Morning thoughts must survive date navigation round-trip"
        )
    }

    // MARK: - Reflect: Journal Text Save / Restore

    func test_journalText_savedAndRestoredCorrectly() {
        self.sut.updateReflectJournalText("Today was challenging but I grew from it")

        XCTAssertEqual(
            self.sut.reflectViewData.journalText,
            "Today was challenging but I grew from it"
        )
    }

    func test_journalText_emptyString_savesNil() {
        self.sut.updateReflectJournalText("Draft text")
        self.sut.updateReflectJournalText("")
        XCTAssertNil(
            self.sut.reflectViewData.journalText,
            "Empty journal text must be stored as nil, not empty string"
        )
    }

    func test_journalText_savedToday_notVisibleYesterday() {
        self.sut.updateReflectJournalText("Evening reflections")

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday

        XCTAssertNil(
            self.sut.reflectViewData.journalText,
            "Today's journal text must not bleed into yesterday's contract"
        )
    }

    func test_journalText_savedToday_restoredAfterNavigationAndReturn() {
        self.sut.updateReflectJournalText("Lessons learned today")

        self.sut.navigateToPreviousDay()
        self.sut.navigateToNextDay()

        XCTAssertEqual(
            self.sut.reflectViewData.journalText,
            "Lessons learned today",
            "Journal text must survive date navigation round-trip"
        )
    }

    // MARK: - Contract Date Stability Under Concurrent Same-Day Mutations

    /// Verifies that when multiple Highlight fields are updated on the same day,
    /// the contract's date field remains unchanged — so the view's onChange(of: data.date)
    /// does NOT fire and in-progress local text is preserved.
    func test_contractDate_stableUnderRapidSameDayMutations() {
        let dateBefore = self.sut.highlightViewData.date

        self.sut.updateHighlightSleepQuality(.good)
        self.sut.updateHighlightSleepNotes("Quick note")
        self.sut.updateHighlightMorningThoughts("Quick thought")
        self.sut.addHighlightTodo("Task 1")
        self.sut.addHighlightTodo("Task 2")

        XCTAssertEqual(
            self.sut.highlightViewData.date,
            dateBefore,
            "Rapid same-day mutations must not change the contract's date identity"
        )
    }

    func test_reflectContractDate_stableUnderRapidSameDayMutations() {
        let dateBefore = self.sut.reflectViewData.date

        self.sut.updateReflectFeeling(.calm)
        self.sut.updateReflectJournalText("Long journal entry")
        self.sut.updateReflectFeeling(.great)

        XCTAssertEqual(
            self.sut.reflectViewData.date,
            dateBefore,
            "Rapid same-day Reflect mutations must not change the contract's date identity"
        )
    }

    // MARK: - Cross-Field Independence (Highlight)

    /// Confirms that updating sleep quality does not alter the sleep notes contract value —
    /// the scenario where a quality tap historically could wipe typed-but-unsaved notes.
    func test_sleepQualityUpdate_doesNotAlterSleepNotesInContract() {
        // Simulate: user typed notes (debounce saved them)
        self.sut.updateHighlightSleepNotes("Rested well")

        // Simulate: user taps quality button (fires immediately, no debounce)
        let notesBefore = self.sut.highlightViewData.sleepNotes
        self.sut.updateHighlightSleepQuality(.good)
        let notesAfter = self.sut.highlightViewData.sleepNotes

        XCTAssertEqual(
            notesBefore,
            notesAfter,
            "Tapping sleep quality must not overwrite saved sleep notes in the contract"
        )
    }

    /// Confirms that adding a todo does not alter the morning thoughts contract value.
    func test_todoAddition_doesNotAlterMorningThoughtsInContract() {
        self.sut.updateHighlightMorningThoughts("Mindful morning")

        let thoughtsBefore = self.sut.highlightViewData.morningThoughts
        self.sut.addHighlightTodo("Meditate")
        let thoughtsAfter = self.sut.highlightViewData.morningThoughts

        XCTAssertEqual(
            thoughtsBefore,
            thoughtsAfter,
            "Adding a todo must not alter morning thoughts in the contract"
        )
    }

    // MARK: - Cross-Field Independence (Reflect)

    /// Confirms that updating feeling does not alter the journal text contract value —
    /// the scenario where a feeling tap historically could wipe typed-but-unsaved journal.
    func test_feelingUpdate_doesNotAlterJournalTextInContract() {
        self.sut.updateReflectJournalText("Great insights from today")

        let journalBefore = self.sut.reflectViewData.journalText
        self.sut.updateReflectFeeling(.calm)
        let journalAfter = self.sut.reflectViewData.journalText

        XCTAssertEqual(
            journalBefore,
            journalAfter,
            "Tapping a feeling must not overwrite saved journal text in the contract"
        )
    }

    // MARK: - Different Days Have Independent Text

    func test_highlightSleepNotes_independentPerDay() {
        self.sut.updateHighlightSleepNotes("Today: great sleep")

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday
        // Yesterday has no notes (independent)
        XCTAssertNil(self.sut.highlightViewData.sleepNotes)

        // Navigate back to today
        self.sut.navigateToToday()
        XCTAssertEqual(
            self.sut.highlightViewData.sleepNotes,
            "Today: great sleep",
            "Today's notes must be unaffected by viewing yesterday"
        )
    }

    func test_reflectJournal_independentPerDay() {
        self.sut.updateReflectJournalText("Today's journal")

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday
        XCTAssertNil(self.sut.reflectViewData.journalText)

        self.sut.navigateToToday()
        XCTAssertEqual(
            self.sut.reflectViewData.journalText,
            "Today's journal",
            "Today's journal must be unaffected by viewing yesterday"
        )
    }

    // MARK: - Security: Input Validation Enforced Before Save

    func test_sleepNotes_tooLong_notSaved() {
        let oversized = String(repeating: "x", count: InputValidator.sleepNotesMaxLength + 100)
        self.sut.updateHighlightSleepNotes(oversized)
        let saved = self.sut.highlightViewData.sleepNotes
        let savedLength = saved?.count ?? 0
        XCTAssertLessThanOrEqual(
            savedLength,
            InputValidator.sleepNotesMaxLength,
            "Oversized sleep notes must be rejected or truncated at save boundary"
        )
    }

    func test_journalText_tooLong_notSaved() {
        let oversized = String(repeating: "y", count: InputValidator.journalEntryMaxLength + 100)
        self.sut.updateReflectJournalText(oversized)
        let saved = self.sut.reflectViewData.journalText
        let savedLength = saved?.count ?? 0
        XCTAssertLessThanOrEqual(
            savedLength,
            InputValidator.journalEntryMaxLength,
            "Oversized journal text must be rejected or truncated at save boundary"
        )
    }

    func test_morningThoughts_tooLong_notSaved() {
        let oversized = String(repeating: "z", count: InputValidator.morningThoughtsMaxLength + 100)
        self.sut.updateHighlightMorningThoughts(oversized)
        let saved = self.sut.highlightViewData.morningThoughts
        let savedLength = saved?.count ?? 0
        XCTAssertLessThanOrEqual(
            savedLength,
            InputValidator.morningThoughtsMaxLength,
            "Oversized morning thoughts must be rejected or truncated at save boundary"
        )
    }
}
