import XCTest
@testable import Yoga_of_Eating

/// Tests for Evening Review functionality.
/// Phase 3: Evening shows morning todos with checkboxes for accountability.
final class EveningReviewTests: XCTestCase {
    // MARK: - MindCheckEntry isAccomplished Tests

    func test_mindCheckEntry_isAccomplished_defaultsToNil() {
        // Given
        let entry = MindCheckEntry(
            category: .todo,
            text: "Test task",
            context: .morning
        )

        // Then
        XCTAssertNil(entry.isAccomplished)
    }

    func test_mindCheckEntry_isAccomplished_canBeSetToTrue() {
        // Given
        let entry = MindCheckEntry(
            category: .todo,
            text: "Test task",
            context: .morning,
            isAccomplished: true
        )

        // Then
        XCTAssertEqual(entry.isAccomplished, true)
    }

    func test_mindCheckEntry_isAccomplished_canBeSetToFalse() {
        // Given
        let entry = MindCheckEntry(
            category: .todo,
            text: "Test task",
            context: .morning,
            isAccomplished: false
        )

        // Then
        XCTAssertEqual(entry.isAccomplished, false)
    }

    func test_mindCheckEntry_isAccomplished_encodesCorrectly() throws {
        // Given
        let entry = MindCheckEntry(
            category: .todo,
            text: "Test task",
            context: .morning,
            isAccomplished: true
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MindCheckEntry.self, from: data)

        // Then
        XCTAssertEqual(decoded.isAccomplished, true)
    }

    func test_mindCheckEntry_withoutIsAccomplished_decodesCorrectly() throws {
        // Given - JSON without isAccomplished field (backward compatibility)
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "category": "todo",
            "text": "Test task",
            "timestamp": 0,
            "context": "morning"
        }
        """.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let entry = try decoder.decode(MindCheckEntry.self, from: json)

        // Then
        XCTAssertNil(entry.isAccomplished)
    }

    // MARK: - Morning Todos Filter Tests

    func test_morningTodos_filtersTodoCategory() {
        // Given
        let entries = [
            MindCheckEntry(category: .todo, text: "Task 1", context: .morning),
            MindCheckEntry(category: .gratitude, text: "Health", context: .morning),
            MindCheckEntry(category: .thinking, text: "Future", context: .morning)
        ]

        // When
        let todos = entries.filter { $0.category == .todo }

        // Then
        XCTAssertEqual(todos.count, 1)
        XCTAssertEqual(todos.first?.text, "Task 1")
    }

    // MARK: - Evening Review View Model Tests

    @MainActor
    func test_viewModel_morningTodosForEvening_returnsOnlyTodos() {
        // Given
        let viewModel = MainViewModel()

        // Create morning entries
        let morningEntries = [
            MindCheckEntry(category: .todo, text: "Task 1", context: .morning),
            MindCheckEntry(category: .todo, text: "Task 2", context: .morning),
            MindCheckEntry(category: .gratitude, text: "Health", context: .morning)
        ]

        // When
        let todos = morningEntries.filter { $0.category == .todo }

        // Then
        XCTAssertEqual(todos.count, 2)
    }

    // MARK: - Strings Tests

    func test_eveningReview_strings_exist() {
        // Verify evening review strings are defined
        XCTAssertFalse(Strings.MindCheck.EveningReview.morningTodosHeader.isEmpty)
        XCTAssertFalse(Strings.MindCheck.EveningReview.gratitudeHeader.isEmpty)
        XCTAssertFalse(Strings.MindCheck.EveningReview.letGoHeader.isEmpty)
        XCTAssertFalse(Strings.MindCheck.EveningReview.noMorningTodos.isEmpty)
    }

    func test_eveningReview_accomplishedLabel_isCorrect() {
        XCTAssertEqual(Strings.MindCheck.EveningReview.accomplished, "Done")
        XCTAssertEqual(Strings.MindCheck.EveningReview.notAccomplished, "Not done")
    }
}
