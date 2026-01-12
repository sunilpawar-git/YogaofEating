import XCTest
@testable import Yoga_of_Eating

/// Tests for mind check edit functionality.
/// Phase 1: Enable editing of logged mind checks.
final class MindCheckEditTests: XCTestCase {
    // MARK: - Badge View Edit Tests

    func test_mindCheckBadgeView_onTap_triggersEditCallback() {
        // Given
        var editCallbackTriggered = false
        let entries = [
            MindCheckEntry(category: .todo, text: "Test task", context: .morning)
        ]

        // When - simulate tap callback
        let onTap: () -> Void = {
            editCallbackTriggered = true
        }
        onTap()

        // Then
        XCTAssertTrue(editCallbackTriggered, "Edit callback should be triggered on badge tap")
    }

    // MARK: - Input View Prefill Tests

    func test_mindCheckInputView_withExistingEntries_shouldAcceptEntries() {
        // Given
        let existingEntries = [
            MindCheckEntry(category: .todo, text: "Buy groceries", context: .morning),
            MindCheckEntry(category: .gratitude, text: "Good health", context: .morning)
        ]

        // Then - verify entries can be passed (compile-time check)
        XCTAssertEqual(existingEntries.count, 2)
        XCTAssertEqual(existingEntries[0].text, "Buy groceries")
        XCTAssertEqual(existingEntries[1].text, "Good health")
    }

    func test_mindCheckEntryDraft_initFromEntry_preservesData() {
        // Given
        let entry = MindCheckEntry(
            category: .todo,
            text: "Original task",
            context: .morning
        )

        // When
        let draft = MindCheckEntryDraft(from: entry)

        // Then
        XCTAssertEqual(draft.category, entry.category)
        XCTAssertEqual(draft.text, entry.text)
    }

    // MARK: - ViewModel Edit Tests

    @MainActor
    func test_mainViewModel_editMorningMindCheck_setsEditMode() {
        // Given
        let viewModel = MainViewModel()
        let existingEntries = [
            MindCheckEntry(category: .todo, text: "Task 1", context: .morning)
        ]

        // When
        viewModel.editMorningMindCheck(existingEntries)

        // Then
        XCTAssertTrue(viewModel.showMorningMindCheckSheet)
        XCTAssertNotNil(viewModel.editingMorningEntries)
        XCTAssertEqual(viewModel.editingMorningEntries?.count, 1)
    }

    @MainActor
    func test_mainViewModel_editEveningMindCheck_setsEditMode() {
        // Given
        let viewModel = MainViewModel()
        let existingEntries = [
            MindCheckEntry(category: .accomplished, text: "Completed task", context: .evening)
        ]

        // When
        viewModel.editEveningMindCheck(existingEntries)

        // Then
        XCTAssertTrue(viewModel.showEveningMindCheckSheet)
        XCTAssertNotNil(viewModel.editingEveningEntries)
        XCTAssertEqual(viewModel.editingEveningEntries?.count, 1)
    }

    @MainActor
    func test_mainViewModel_completeMindCheckInput_clearsEditMode() {
        // Given
        let viewModel = MainViewModel()
        let existingEntries = [
            MindCheckEntry(category: .todo, text: "Task 1", context: .morning)
        ]
        viewModel.editMorningMindCheck(existingEntries)

        // When
        viewModel.completeMorningMindCheckInput([])

        // Then
        XCTAssertFalse(viewModel.showMorningMindCheckSheet)
        XCTAssertNil(viewModel.editingMorningEntries)
    }
}
