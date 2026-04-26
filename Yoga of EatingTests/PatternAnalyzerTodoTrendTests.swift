import XCTest
@testable import Yoga_of_Eating

/// TDD tests for PatternAnalyzer todo completion trend detection.
final class PatternAnalyzerTodoTrendTests: XCTestCase {
    var sut: PatternAnalyzer!

    override func setUp() {
        super.setUp()
        self.sut = PatternAnalyzer()
    }

    override func tearDown() {
        self.sut = nil
        super.tearDown()
    }

    func test_fewerThanFiveSnapshots_noPattern() {
        let snapshots = (0..<4).map { Self.makeSnapshot(daysAgo: $0, completed: 1, total: 1) }
        let result = self.sut.analyzeTodoCompletionTrend(from: snapshots)
        XCTAssertTrue(result.isEmpty)
    }

    func test_consistentCompletion_noPattern() {
        let snapshots = (0..<6).map { Self.makeSnapshot(daysAgo: $0, completed: 1, total: 2) }
        let result = self.sut.analyzeTodoCompletionTrend(from: snapshots)
        XCTAssertTrue(result.isEmpty)
    }

    func test_improvingTrend_detectedWithPositiveDescription() {
        var snapshots: [DailySmileySnapshot] = []
        // First half: low completion
        for day in 5..<8 {
            snapshots.append(Self.makeSnapshot(daysAgo: day, completed: 0, total: 3))
        }
        // Second half: high completion
        for day in 0..<3 {
            snapshots.append(Self.makeSnapshot(daysAgo: day, completed: 3, total: 3))
        }

        let result = self.sut.analyzeTodoCompletionTrend(from: snapshots)
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.description.contains("improving") ?? false)
    }

    func test_decliningTrend_detectedWithNegativeDescription() {
        var snapshots: [DailySmileySnapshot] = []
        // First half: high completion
        for day in 5..<8 {
            snapshots.append(Self.makeSnapshot(daysAgo: day, completed: 3, total: 3))
        }
        // Second half: low completion
        for day in 0..<3 {
            snapshots.append(Self.makeSnapshot(daysAgo: day, completed: 0, total: 3))
        }

        let result = self.sut.analyzeTodoCompletionTrend(from: snapshots)
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.description.contains("dipped") ?? false)
    }

    func test_snapshotsWithNoTodos_ignored() {
        let emptySnapshots = (0..<6).map { daysAgo -> DailySmileySnapshot in
            DailySmileySnapshot(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.0
            )
        }
        let result = self.sut.analyzeTodoCompletionTrend(from: emptySnapshots)
        XCTAssertTrue(result.isEmpty)
    }

    func test_trendReferences_haveTodoCategory() {
        var snapshots: [DailySmileySnapshot] = []
        for day in 5..<8 {
            snapshots.append(Self.makeSnapshot(daysAgo: day, completed: 0, total: 3))
        }
        for day in 0..<3 {
            snapshots.append(Self.makeSnapshot(daysAgo: day, completed: 3, total: 3))
        }

        let result = self.sut.analyzeTodoCompletionTrend(from: snapshots)
        let references = result.first?.references ?? []

        XCTAssertFalse(references.isEmpty)
        for ref in references {
            XCTAssertEqual(ref.category, .todo)
        }
    }

    // MARK: - Helpers

    private static func makeSnapshot(
        daysAgo: Int,
        completed: Int,
        total: Int
    ) -> DailySmileySnapshot {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        var todos: [MindCheckEntry] = []
        for idx in 0..<total {
            let isCompleted = idx < completed
            todos.append(MindCheckEntry(
                category: .todo,
                text: "Task \(idx)",
                context: .morning,
                isAccomplished: isCompleted
            ))
        }
        return DailySmileySnapshot(
            id: UUID(),
            date: date,
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0,
            morningMindCheck: todos
        )
    }
}
