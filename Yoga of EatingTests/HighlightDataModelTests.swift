import XCTest
@testable import Yoga_of_Eating

final class HighlightDataModelTests: XCTestCase {
    func test_defaultInit_hasNoContent() {
        let data = HighlightData()
        XCTAssertNil(data.sleepQuality)
        XCTAssertNil(data.sleepNotes)
        XCTAssertTrue(data.todos.isEmpty)
        XCTAssertNil(data.morningThoughts)
        XCTAssertFalse(data.hasContent)
        XCTAssertFalse(data.hasSleepLogged)
    }

    func test_hasContent_trueWhenSleepQualitySet() {
        let data = HighlightData(sleepQuality: .good)
        XCTAssertTrue(data.hasContent)
        XCTAssertTrue(data.hasSleepLogged)
    }

    func test_hasContent_trueWhenSleepNotesSet() {
        let data = HighlightData(sleepNotes: "Slept through the night")
        XCTAssertTrue(data.hasContent)
    }

    func test_hasContent_trueWhenTodosExist() {
        let todo = MindCheckEntry(category: .todo, text: "Meditate", context: .morning)
        let data = HighlightData(todos: [todo])
        XCTAssertTrue(data.hasContent)
    }

    func test_hasContent_trueWhenMorningThoughtsSet() {
        let data = HighlightData(morningThoughts: "Feeling grateful")
        XCTAssertTrue(data.hasContent)
    }

    func test_hasContent_falseForWhitespaceOnlyNotes() {
        let data = HighlightData(sleepNotes: "   ", morningThoughts: "\n  ")
        XCTAssertFalse(data.hasContent)
    }

    func test_encodeDecode_roundTrip() throws {
        let todo = MindCheckEntry(
            id: UUID(),
            category: .todo,
            text: "Buy groceries",
            timestamp: Date(),
            context: .morning
        )
        let original = HighlightData(
            sleepQuality: .great,
            sleepNotes: "Deep sleep",
            todos: [todo],
            morningThoughts: "Ready for today"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HighlightData.self, from: data)

        XCTAssertEqual(decoded.sleepQuality, original.sleepQuality)
        XCTAssertEqual(decoded.sleepNotes, original.sleepNotes)
        XCTAssertEqual(decoded.todos.count, original.todos.count)
        XCTAssertEqual(decoded.morningThoughts, original.morningThoughts)
    }

    func test_encodeDecode_nilFieldsRoundTrip() throws {
        let original = HighlightData()

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HighlightData.self, from: data)

        XCTAssertNil(decoded.sleepQuality)
        XCTAssertNil(decoded.sleepNotes)
        XCTAssertTrue(decoded.todos.isEmpty)
        XCTAssertNil(decoded.morningThoughts)
    }

    func test_equatable() {
        let fixedDate = Date(timeIntervalSince1970: 1_000_000)
        let a = HighlightData(sleepQuality: .good, morningThoughts: "Hello", lastModified: fixedDate)
        let b = HighlightData(sleepQuality: .good, morningThoughts: "Hello", lastModified: fixedDate)
        let c = HighlightData(sleepQuality: .poor, morningThoughts: "Hello", lastModified: fixedDate)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
