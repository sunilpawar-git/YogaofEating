// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for MindCheckEntry model and related enums
    /// Phase 1: TDD - Tests written before implementation
    @MainActor
    final class MindCheckEntryTests: XCTestCase {
        // MARK: - Properties

        var testDate: Date!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.testDate = Date()
        }

        override func tearDown() {
            self.testDate = nil
            super.tearDown()
        }

        // MARK: - Tests: MindCheckCategory Morning Cases

        func test_mindCheckCategory_morning_hasExpectedCases() {
            // Assert morning categories exist
            let morningCategories: [MindCheckCategory] = [.todo, .gratitude, .thinking]
            for category in morningCategories {
                XCTAssertEqual(category.context, .morning, "\(category) should be a morning category")
            }
        }

        func test_mindCheckCategory_evening_hasExpectedCases() {
            // Assert evening categories exist
            let eveningCategories: [MindCheckCategory] = [.accomplished, .gratefulFor, .letGo]
            for category in eveningCategories {
                XCTAssertEqual(category.context, .evening, "\(category) should be an evening category")
            }
        }

        func test_mindCheckCategory_allCases_hasCorrectCount() {
            // Assert total count is 6 (3 morning + 3 evening)
            XCTAssertEqual(MindCheckCategory.allCases.count, 6, "MindCheckCategory should have exactly 6 cases")
        }

        // MARK: - Tests: MindCheckContext Enum

        func test_mindCheckContext_hasExpectedCases() {
            // Assert both contexts exist
            let allContexts = MindCheckContext.allCases
            XCTAssertEqual(allContexts.count, 2, "MindCheckContext should have exactly 2 cases")
            XCTAssertTrue(allContexts.contains(.morning))
            XCTAssertTrue(allContexts.contains(.evening))
        }

        func test_mindCheckContext_rawValues_areCorrect() {
            XCTAssertEqual(MindCheckContext.morning.rawValue, "morning")
            XCTAssertEqual(MindCheckContext.evening.rawValue, "evening")
        }

        // MARK: - Tests: MindCheckEntry Initialization

        func test_mindCheckEntry_init_setsAllProperties() {
            // Arrange
            let id = UUID()
            let category = MindCheckCategory.todo
            let text = "Buy groceries"
            let timestamp = self.testDate!
            let context = MindCheckContext.morning

            // Act
            let entry = MindCheckEntry(
                id: id,
                category: category,
                text: text,
                timestamp: timestamp,
                context: context
            )

            // Assert
            XCTAssertEqual(entry.id, id)
            XCTAssertEqual(entry.category, category)
            XCTAssertEqual(entry.text, text)
            XCTAssertEqual(entry.timestamp, timestamp)
            XCTAssertEqual(entry.context, context)
        }

        func test_mindCheckEntry_identifiable_hasUniqueId() {
            // Arrange & Act
            let entry1 = MindCheckEntry(
                id: UUID(),
                category: .todo,
                text: "Task 1",
                timestamp: self.testDate,
                context: .morning
            )
            let entry2 = MindCheckEntry(
                id: UUID(),
                category: .todo,
                text: "Task 2",
                timestamp: self.testDate,
                context: .morning
            )

            // Assert
            XCTAssertNotEqual(entry1.id, entry2.id, "Each entry should have a unique ID")
        }

        // MARK: - Tests: MindCheckEntry Codable

        func test_mindCheckEntry_codable_encodesAndDecodes() throws {
            // Arrange
            let entry = MindCheckEntry(
                id: UUID(),
                category: .gratitude,
                text: "My health",
                timestamp: self.testDate,
                context: .morning
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(entry)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(MindCheckEntry.self, from: data)

            // Assert
            XCTAssertEqual(decoded.id, entry.id)
            XCTAssertEqual(decoded.category, entry.category)
            XCTAssertEqual(decoded.text, entry.text)
            XCTAssertEqual(decoded.context, entry.context)
            XCTAssertEqual(
                decoded.timestamp.timeIntervalSince1970,
                entry.timestamp.timeIntervalSince1970,
                accuracy: 0.001
            )
        }

        func test_mindCheckEntry_codable_allCategories() throws {
            // Test each category encodes and decodes correctly
            for category in MindCheckCategory.allCases {
                let entry = MindCheckEntry(
                    id: UUID(),
                    category: category,
                    text: "Test",
                    timestamp: self.testDate,
                    context: category.context
                )

                let encoder = JSONEncoder()
                let data = try encoder.encode(entry)
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(MindCheckEntry.self, from: data)

                XCTAssertEqual(decoded.category, category, "Failed for category: \(category)")
            }
        }

        // MARK: - Tests: MindCheckCategory Emoji

        func test_mindCheckCategory_emoji_returnsCorrectEmoji() {
            // Morning categories
            XCTAssertEqual(MindCheckCategory.todo.emoji, "📝")
            XCTAssertEqual(MindCheckCategory.gratitude.emoji, "🙏")
            XCTAssertEqual(MindCheckCategory.thinking.emoji, "💭")

            // Evening categories
            XCTAssertEqual(MindCheckCategory.accomplished.emoji, "✅")
            XCTAssertEqual(MindCheckCategory.gratefulFor.emoji, "🙏")
            XCTAssertEqual(MindCheckCategory.letGo.emoji, "🍃")
        }

        // MARK: - Tests: MindCheckCategory DisplayName

        func test_mindCheckCategory_displayName_returnsCorrectName() {
            // Morning categories
            XCTAssertEqual(MindCheckCategory.todo.displayName, "To-Do")
            XCTAssertEqual(MindCheckCategory.gratitude.displayName, "Grateful for")
            XCTAssertEqual(MindCheckCategory.thinking.displayName, "Thinking about")

            // Evening categories
            XCTAssertEqual(MindCheckCategory.accomplished.displayName, "Accomplished")
            XCTAssertEqual(MindCheckCategory.gratefulFor.displayName, "Grateful for")
            XCTAssertEqual(MindCheckCategory.letGo.displayName, "Let go of")
        }

        // MARK: - Tests: MindCheckCategory Context

        func test_mindCheckCategory_context_returnsCorrectContext() {
            // Morning categories
            XCTAssertEqual(MindCheckCategory.todo.context, .morning)
            XCTAssertEqual(MindCheckCategory.gratitude.context, .morning)
            XCTAssertEqual(MindCheckCategory.thinking.context, .morning)

            // Evening categories
            XCTAssertEqual(MindCheckCategory.accomplished.context, .evening)
            XCTAssertEqual(MindCheckCategory.gratefulFor.context, .evening)
            XCTAssertEqual(MindCheckCategory.letGo.context, .evening)
        }

        // MARK: - Tests: MindCheckCategory Static Methods

        func test_mindCheckCategory_categoriesForContext_morning() {
            // Phase 2: Morning now only allows To-Do category
            let morningCategories = MindCheckCategory.categories(for: .morning)
            XCTAssertEqual(morningCategories.count, 1, "Morning should only have To-Do category")
            XCTAssertTrue(morningCategories.contains(.todo))
            // Note: .gratitude and .thinking still exist in enum for backward compatibility
            // but are no longer offered for new morning entries
        }

        func test_mindCheckCategory_categoriesForContext_evening() {
            let eveningCategories = MindCheckCategory.categories(for: .evening)
            XCTAssertEqual(eveningCategories.count, 3)
            XCTAssertTrue(eveningCategories.contains(.accomplished))
            XCTAssertTrue(eveningCategories.contains(.gratefulFor))
            XCTAssertTrue(eveningCategories.contains(.letGo))
        }

        // MARK: - Tests: MindCheckEntry Equatable

        func test_mindCheckEntry_equatable_returnsTrueForIdenticalEntries() {
            // Arrange
            let id = UUID()
            let entry1 = MindCheckEntry(
                id: id,
                category: .todo,
                text: "Test",
                timestamp: self.testDate,
                context: .morning
            )
            let entry2 = MindCheckEntry(
                id: id,
                category: .todo,
                text: "Test",
                timestamp: self.testDate,
                context: .morning
            )

            // Assert
            XCTAssertEqual(entry1, entry2)
        }

        func test_mindCheckEntry_equatable_returnsFalseForDifferentIds() {
            // Arrange
            let entry1 = MindCheckEntry(
                id: UUID(),
                category: .todo,
                text: "Test",
                timestamp: self.testDate,
                context: .morning
            )
            let entry2 = MindCheckEntry(
                id: UUID(),
                category: .todo,
                text: "Test",
                timestamp: self.testDate,
                context: .morning
            )

            // Assert
            XCTAssertNotEqual(entry1, entry2)
        }

        // MARK: - Tests: Edge Cases

        func test_mindCheckEntry_withEmptyText_handlesCorrectly() throws {
            // Arrange
            let entry = MindCheckEntry(
                id: UUID(),
                category: .todo,
                text: "",
                timestamp: self.testDate,
                context: .morning
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(entry)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(MindCheckEntry.self, from: data)

            // Assert
            XCTAssertEqual(decoded.text, "")
        }

        func test_mindCheckEntry_withSpecialCharacters_handlesCorrectly() throws {
            // Arrange
            let specialText = "Grateful for 🎉 family & friends! <test>"
            let entry = MindCheckEntry(
                id: UUID(),
                category: .gratitude,
                text: specialText,
                timestamp: self.testDate,
                context: .morning
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(entry)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(MindCheckEntry.self, from: data)

            // Assert
            XCTAssertEqual(decoded.text, specialText)
        }

        func test_mindCheckEntry_withLongText_handlesCorrectly() throws {
            // Arrange
            let longText = String(repeating: "This is a test. ", count: 10)
            let entry = MindCheckEntry(
                id: UUID(),
                category: .thinking,
                text: longText,
                timestamp: self.testDate,
                context: .morning
            )

            // Act
            let encoder = JSONEncoder()
            let data = try encoder.encode(entry)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(MindCheckEntry.self, from: data)

            // Assert
            XCTAssertEqual(decoded.text, longText)
        }
    }
#endif
