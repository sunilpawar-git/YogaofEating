// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for Mind Check UI Components
    /// Phase 4: TDD - Tests written before implementation
    @MainActor
    final class MindCheckUITests: XCTestCase {
        // MARK: - Tests: MindCheckPillView

        func test_mindCheckPillView_actionInvoked_whenTapped() {
            // Arrange
            var actionCalled = false
            let view = MindCheckPillView {
                actionCalled = true
            }

            // Act
            view.action()

            // Assert
            XCTAssertTrue(actionCalled)
        }

        // MARK: - Tests: MindCheckInputView

        func test_mindCheckInputView_morningContext_hasCorrectCategories() {
            // Phase 2: Morning now only offers To-Do category for new entries
            let availableMorningCategories = MindCheckCategory.categories(for: .morning)

            XCTAssertEqual(availableMorningCategories.count, 1, "Morning should only offer To-Do")
            XCTAssertTrue(availableMorningCategories.contains(.todo))
            // Note: .gratitude and .thinking still exist for backward compatibility
        }

        func test_mindCheckInputView_eveningContext_hasCorrectCategories() {
            // Evening categories: accomplished, gratefulFor, letGo
            let eveningCategories: [MindCheckCategory] = [.accomplished, .gratefulFor, .letGo]

            for category in eveningCategories {
                XCTAssertEqual(category.context, .evening, "\(category) should be an evening category")
            }
        }

        func test_mindCheckCategory_context_returnsCorrectValue() {
            // Morning
            XCTAssertEqual(MindCheckCategory.todo.context, .morning)
            XCTAssertEqual(MindCheckCategory.gratitude.context, .morning)
            XCTAssertEqual(MindCheckCategory.thinking.context, .morning)

            // Evening
            XCTAssertEqual(MindCheckCategory.accomplished.context, .evening)
            XCTAssertEqual(MindCheckCategory.gratefulFor.context, .evening)
            XCTAssertEqual(MindCheckCategory.letGo.context, .evening)
        }

        func test_mindCheckCategory_morningCategories_returnsOnlyTodo() {
            // Phase 2: Static morningCategories should only return To-Do
            let morningCategories = MindCheckCategory.morningCategories

            XCTAssertEqual(morningCategories.count, 1, "morningCategories should only contain To-Do")
            XCTAssertTrue(morningCategories.contains(.todo))
        }

        func test_mindCheckCategory_eveningCategories_returnsThreeCategories() {
            let eveningCategories = MindCheckCategory.eveningCategories

            XCTAssertEqual(eveningCategories.count, 3)
            XCTAssertTrue(eveningCategories.contains(.accomplished))
            XCTAssertTrue(eveningCategories.contains(.gratefulFor))
            XCTAssertTrue(eveningCategories.contains(.letGo))
        }

        // MARK: - Tests: MindCheckEntryRow

        func test_mindCheckEntryRow_displaysCategory() {
            // Arrange
            let entry = MindCheckEntry(
                category: .todo,
                text: "Buy groceries",
                timestamp: Date(),
                context: .morning
            )

            // Assert
            XCTAssertEqual(entry.category.emoji, "📝")
            XCTAssertEqual(entry.category.displayName, "To-Do")
        }

        func test_mindCheckEntryRow_displaysText() {
            // Arrange
            let entry = MindCheckEntry(
                category: .gratitude,
                text: "My family",
                timestamp: Date(),
                context: .morning
            )

            // Assert
            XCTAssertEqual(entry.text, "My family")
        }

        // MARK: - Tests: Mind Check Summary Badge

        func test_mindCheckSummaryBadge_countDisplaysCorrectly() {
            // Arrange
            let entries = [
                MindCheckEntry(category: .todo, text: "Task 1", timestamp: Date(), context: .morning),
                MindCheckEntry(category: .gratitude, text: "Health", timestamp: Date(), context: .morning),
                MindCheckEntry(category: .thinking, text: "Future", timestamp: Date(), context: .morning)
            ]

            // Assert
            XCTAssertEqual(entries.count, 3)
        }

        // MARK: - Tests: Input View Titles (Phase 2)

        func test_morningInput_showsCorrectTitle() {
            // Morning title should be "Morning Intentions"
            XCTAssertEqual(Strings.MindCheck.morningTitle, "Morning Intentions")
        }

        func test_morningInput_showsCorrectSubtitle() {
            // Morning subtitle should guide user about top 3 things
            XCTAssertEqual(Strings.MindCheck.morningSubtitle, "What are the top 3 things on your mind?")
        }

        func test_eveningInput_showsCorrectTitle() {
            // Evening title should be "Evening Review"
            XCTAssertEqual(Strings.MindCheck.eveningTitle, "Evening Review")
        }

        func test_entryLimitGuidance_showsCorrectText() {
            // Entry limit hint should say "Up to 3 thoughts"
            XCTAssertEqual(Strings.MindCheck.entryLimitHint, "Up to 3 thoughts")
        }

        func test_entryCount_formatsCorrectly() {
            // Entry count should format as "1 of 3", "2 of 3", etc.
            XCTAssertEqual(Strings.MindCheck.entryCount(1), "1 of 3")
            XCTAssertEqual(Strings.MindCheck.entryCount(2), "2 of 3")
            XCTAssertEqual(Strings.MindCheck.entryCount(3), "3 of 3")
        }
    }
#endif
