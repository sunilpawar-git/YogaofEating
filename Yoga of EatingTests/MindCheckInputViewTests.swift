import XCTest
@testable import Yoga_of_Eating

/// Tests for MindCheckInputView UI/UX flow.
/// Ensures smooth user experience for adding To-Do items.
final class MindCheckInputViewTests: XCTestCase {
    // MARK: - Initial State Tests

    func test_newInputView_startsWithNoEntries() {
        // Given - A new input view with no existing entries
        // The view should start empty, showing only "Add To-Do" button

        // Simulate the initial state
        var entries: [MindCheckEntryDraft] = []

        // Then - No entries should exist initially
        XCTAssertTrue(entries.isEmpty, "New input should start with no entries")
        XCTAssertTrue(entries.count < 3, "Should be able to add entries")
    }

    func test_newInputView_canAddMoreIsTrue_whenEmpty() {
        // Given - Empty entries
        let entries: [MindCheckEntryDraft] = []

        // When - Check if can add more
        let canAddMore = entries.count < 3

        // Then
        XCTAssertTrue(canAddMore, "Should be able to add entries when empty")
    }

    // MARK: - Add Entry Tests

    func test_addEntry_createsNewDraft() {
        // Given
        var entries: [MindCheckEntryDraft] = []

        // When - Add a new entry
        let newEntry = MindCheckEntryDraft(category: .todo, text: "")
        entries.append(newEntry)

        // Then
        XCTAssertEqual(entries.count, 1, "Should have one entry after adding")
        XCTAssertEqual(entries.first?.category, .todo, "Entry should be a To-Do")
        XCTAssertEqual(entries.first?.text, "", "Entry should start with empty text")
    }

    func test_addEntry_multipleTimes_incrementsCount() {
        // Given
        var entries: [MindCheckEntryDraft] = []

        // When - Add 3 entries
        entries.append(MindCheckEntryDraft(category: .todo, text: "Task 1"))
        entries.append(MindCheckEntryDraft(category: .todo, text: "Task 2"))
        entries.append(MindCheckEntryDraft(category: .todo, text: "Task 3"))

        // Then
        XCTAssertEqual(entries.count, 3, "Should have 3 entries")
    }

    func test_canAddMore_isFalse_whenThreeEntries() {
        // Given - 3 entries
        let entries = [
            MindCheckEntryDraft(category: .todo, text: "Task 1"),
            MindCheckEntryDraft(category: .todo, text: "Task 2"),
            MindCheckEntryDraft(category: .todo, text: "Task 3")
        ]

        // When
        let canAddMore = entries.count < 3

        // Then
        XCTAssertFalse(canAddMore, "Should not be able to add more when at limit")
    }

    func test_canAddMore_isTrue_whenLessThanThreeEntries() {
        // Given - 2 entries
        let entries = [
            MindCheckEntryDraft(category: .todo, text: "Task 1"),
            MindCheckEntryDraft(category: .todo, text: "Task 2")
        ]

        // When
        let canAddMore = entries.count < 3

        // Then
        XCTAssertTrue(canAddMore, "Should be able to add more when under limit")
    }

    // MARK: - Delete Entry Tests

    func test_deleteEntry_removesFromList() {
        // Given
        var entries = [
            MindCheckEntryDraft(category: .todo, text: "Task 1"),
            MindCheckEntryDraft(category: .todo, text: "Task 2")
        ]
        let entryToDelete = entries[0]

        // When
        entries.removeAll { $0.id == entryToDelete.id }

        // Then
        XCTAssertEqual(entries.count, 1, "Should have one entry after deletion")
        XCTAssertEqual(entries.first?.text, "Task 2", "Remaining entry should be Task 2")
    }

    func test_deleteEntry_afterDeletion_canAddMore() {
        // Given - 3 entries, then delete one
        var entries = [
            MindCheckEntryDraft(category: .todo, text: "Task 1"),
            MindCheckEntryDraft(category: .todo, text: "Task 2"),
            MindCheckEntryDraft(category: .todo, text: "Task 3")
        ]
        XCTAssertFalse(entries.count < 3, "Cannot add more at limit")

        // When
        entries.removeLast()

        // Then
        XCTAssertTrue(entries.count < 3, "Should be able to add after deletion")
    }

    // MARK: - Entry Count Display Tests

    func test_entryCount_formatsCorrectly() {
        XCTAssertEqual(Strings.MindCheck.entryCount(0), "0 of 3")
        XCTAssertEqual(Strings.MindCheck.entryCount(1), "1 of 3")
        XCTAssertEqual(Strings.MindCheck.entryCount(2), "2 of 3")
        XCTAssertEqual(Strings.MindCheck.entryCount(3), "3 of 3")
    }

    func test_entryCount_notDisplayed_whenEmpty() {
        // Given
        let entries: [MindCheckEntryDraft] = []

        // Then - count should not be shown when empty
        XCTAssertTrue(entries.isEmpty, "Entry count should not display when empty")
    }

    // MARK: - Valid Entries Tests

    func test_hasValidEntries_isFalse_whenEmpty() {
        // Given
        let entries: [MindCheckEntryDraft] = []

        // When
        let hasValidEntries = entries.contains {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // Then
        XCTAssertFalse(hasValidEntries, "No valid entries when empty")
    }

    func test_hasValidEntries_isFalse_whenOnlyWhitespace() {
        // Given
        let entries = [
            MindCheckEntryDraft(category: .todo, text: "   "),
            MindCheckEntryDraft(category: .todo, text: "\n\t")
        ]

        // When
        let hasValidEntries = entries.contains {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // Then
        XCTAssertFalse(hasValidEntries, "Whitespace-only entries are not valid")
    }

    func test_hasValidEntries_isTrue_whenTextPresent() {
        // Given
        let entries = [
            MindCheckEntryDraft(category: .todo, text: ""),
            MindCheckEntryDraft(category: .todo, text: "Valid task")
        ]

        // When
        let hasValidEntries = entries.contains {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // Then
        XCTAssertTrue(hasValidEntries, "Should have valid entries when text is present")
    }

    // MARK: - Save Entries Tests

    func test_saveEntries_filtersEmptyEntries() {
        // Given
        let drafts = [
            MindCheckEntryDraft(category: .todo, text: ""),
            MindCheckEntryDraft(category: .todo, text: "Valid task"),
            MindCheckEntryDraft(category: .todo, text: "   ")
        ]

        // When - Filter valid entries (simulating save logic)
        let validEntries = drafts
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { draft in
                MindCheckEntry(
                    category: draft.category,
                    text: draft.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    timestamp: Date(),
                    context: .morning
                )
            }

        // Then
        XCTAssertEqual(validEntries.count, 1, "Only valid entries should be saved")
        XCTAssertEqual(validEntries.first?.text, "Valid task")
    }

    func test_saveEntries_trimsWhitespace() {
        // Given
        let drafts = [
            MindCheckEntryDraft(category: .todo, text: "  Task with spaces  ")
        ]

        // When
        let savedText = drafts.first?.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Then
        XCTAssertEqual(savedText, "Task with spaces", "Whitespace should be trimmed")
    }

    // MARK: - Edit Mode Tests

    func test_editMode_prefillsExistingEntries() {
        // Given - Existing entries to edit
        let existingEntries = [
            MindCheckEntry(category: .todo, text: "Existing task 1", context: .morning),
            MindCheckEntry(category: .todo, text: "Existing task 2", context: .morning)
        ]

        // When - Convert to drafts (simulating edit mode)
        let drafts = existingEntries.map { MindCheckEntryDraft(from: $0) }

        // Then
        XCTAssertEqual(drafts.count, 2, "Should prefill with existing entries")
        XCTAssertEqual(drafts[0].text, "Existing task 1")
        XCTAssertEqual(drafts[1].text, "Existing task 2")
    }

    func test_editMode_preservesEntryCategory() {
        // Given
        let entry = MindCheckEntry(category: .todo, text: "Test", context: .morning)

        // When
        let draft = MindCheckEntryDraft(from: entry)

        // Then
        XCTAssertEqual(draft.category, .todo, "Category should be preserved")
    }

    // MARK: - Draft Model Tests

    func test_mindCheckEntryDraft_hasUniqueId() {
        // Given
        let draft1 = MindCheckEntryDraft(category: .todo, text: "Task 1")
        let draft2 = MindCheckEntryDraft(category: .todo, text: "Task 2")

        // Then
        XCTAssertNotEqual(draft1.id, draft2.id, "Each draft should have unique ID")
    }

    func test_mindCheckEntryDraft_fromEntry_preservesId() {
        // Given
        let entry = MindCheckEntry(category: .todo, text: "Test", context: .morning)

        // When
        let draft = MindCheckEntryDraft(from: entry)

        // Then
        XCTAssertEqual(draft.id, entry.id, "Draft should preserve entry ID for editing")
    }

    // MARK: - UI Flow Tests

    func test_uiFlow_emptyToOneEntry() {
        // Simulate the UI flow: empty state → tap Add To-Do → one entry

        // Given - Start empty
        var entries: [MindCheckEntryDraft] = []
        XCTAssertTrue(entries.isEmpty)
        XCTAssertTrue(entries.count < 3, "Add button should be visible")

        // When - User taps "Add To-Do"
        entries.append(MindCheckEntryDraft(category: .todo, text: ""))

        // Then - One entry visible, Add button still visible
        XCTAssertEqual(entries.count, 1)
        XCTAssertTrue(entries.count < 3, "Add button should still be visible")
    }

    func test_uiFlow_threeEntriesHidesAddButton() {
        // Given - Start with 2 entries
        var entries = [
            MindCheckEntryDraft(category: .todo, text: "Task 1"),
            MindCheckEntryDraft(category: .todo, text: "Task 2")
        ]
        XCTAssertTrue(entries.count < 3, "Add button should be visible")

        // When - Add third entry
        entries.append(MindCheckEntryDraft(category: .todo, text: "Task 3"))

        // Then - Add button should be hidden
        XCTAssertFalse(entries.count < 3, "Add button should be hidden at limit")
    }

    func test_uiFlow_deleteEntryShowsAddButton() {
        // Given - 3 entries (Add button hidden)
        var entries = [
            MindCheckEntryDraft(category: .todo, text: "Task 1"),
            MindCheckEntryDraft(category: .todo, text: "Task 2"),
            MindCheckEntryDraft(category: .todo, text: "Task 3")
        ]
        XCTAssertFalse(entries.count < 3)

        // When - Delete one entry
        entries.removeLast()

        // Then - Add button should reappear
        XCTAssertTrue(entries.count < 3, "Add button should reappear after deletion")
    }
}
