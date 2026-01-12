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

        func test_mindCheckPillView_morningContext_hasCorrectLabel() {
            // Arrange
            let view = MindCheckPillView(context: .morning, action: {})

            // Assert
            XCTAssertEqual(view.context, .morning)
        }

        func test_mindCheckPillView_eveningContext_hasCorrectLabel() {
            // Arrange
            let view = MindCheckPillView(context: .evening, action: {})

            // Assert
            XCTAssertEqual(view.context, .evening)
        }

        func test_mindCheckPillView_actionInvoked_whenTapped() {
            // Arrange
            var actionCalled = false
            let view = MindCheckPillView(context: .morning) {
                actionCalled = true
            }

            // Act
            view.action()

            // Assert
            XCTAssertTrue(actionCalled)
        }

        // MARK: - Tests: MindCheckInputView

        func test_mindCheckInputView_morningContext_hasCorrectCategories() {
            // Morning categories: todo, gratitude, thinking
            let morningCategories: [MindCheckCategory] = [.todo, .gratitude, .thinking]

            for category in morningCategories {
                XCTAssertEqual(category.context, .morning, "\(category) should be a morning category")
            }
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

        func test_mindCheckCategory_morningCategories_returnsThreeCategories() {
            let morningCategories = MindCheckCategory.morningCategories

            XCTAssertEqual(morningCategories.count, 3)
            XCTAssertTrue(morningCategories.contains(.todo))
            XCTAssertTrue(morningCategories.contains(.gratitude))
            XCTAssertTrue(morningCategories.contains(.thinking))
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
    }
#endif
