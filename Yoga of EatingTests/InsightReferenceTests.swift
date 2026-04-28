import XCTest
@testable import Yoga_of_Eating

/// Tests for InsightReference model.
/// Phase 4: Date-referenced insights for rich context.
final class InsightReferenceTests: XCTestCase {
    // MARK: - Basic Tests

    func test_insightReference_initialization() {
        // Given
        let date = Date()
        let description = "Late evening coffee"

        // When
        let reference = InsightReference(
            date: date,
            description: description,
            category: .food
        )

        // Then
        XCTAssertEqual(reference.description, description)
        XCTAssertEqual(reference.category, .food)
    }

    func test_insightReference_encodesDateAndDescription() throws {
        // Given
        let reference = InsightReference(
            date: Date(),
            description: "Heavy dinner at 10pm",
            category: .food
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(reference)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(InsightReference.self, from: data)

        // Then
        XCTAssertEqual(decoded.description, reference.description)
        XCTAssertEqual(decoded.category, reference.category)
    }

    func test_insightReference_formatsDateCorrectly() {
        // Given - January 12, 2026
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 12
        let date = calendar.date(from: components)!

        let reference = InsightReference(
            date: date,
            description: "Test",
            category: .food
        )

        // Then
        XCTAssertEqual(reference.formattedDate, "12 Jan")
    }

    // MARK: - Category Tests

    func test_referenceCategory_allCasesExist() {
        XCTAssertEqual(ReferenceCategory.allCases.count, 4)
        XCTAssertTrue(ReferenceCategory.allCases.contains(.food))
        XCTAssertTrue(ReferenceCategory.allCases.contains(.todo))
        XCTAssertTrue(ReferenceCategory.allCases.contains(.sleep))
        XCTAssertTrue(ReferenceCategory.allCases.contains(.feeling))
    }

    func test_referenceCategory_hasDisplayName() {
        XCTAssertEqual(ReferenceCategory.food.displayName, "Food")
        XCTAssertEqual(ReferenceCategory.todo.displayName, "Todo")
        XCTAssertEqual(ReferenceCategory.sleep.displayName, "Sleep")
        XCTAssertEqual(ReferenceCategory.feeling.displayName, "Feeling")
    }

    // MARK: - Equatable Tests

    func test_insightReference_equatable() {
        // Given
        let date = Date()
        let ref1 = InsightReference(id: UUID(), date: date, description: "Test", category: .food)
        let ref2 = InsightReference(id: ref1.id, date: date, description: "Test", category: .food)

        // Then
        XCTAssertEqual(ref1, ref2)
    }
}
