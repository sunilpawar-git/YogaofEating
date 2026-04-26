import XCTest
@testable import Yoga_of_Eating

/// TDD tests for TodoAnalyticsService — computes todo completion analytics.
final class TodoAnalyticsServiceTests: XCTestCase {
    // MARK: - Empty Data

    func test_emptySnapshots_returnsZeroAnalytics() {
        let result = TodoAnalyticsService.compute(from: [])

        XCTAssertEqual(result.completionRate, 0.0, accuracy: 0.01)
        XCTAssertEqual(result.currentStreak, 0)
        XCTAssertEqual(result.bestStreak, 0)
        XCTAssertEqual(result.totalCompleted, 0)
        XCTAssertEqual(result.totalCreated, 0)
        XCTAssertEqual(result.averagePerDay, 0.0, accuracy: 0.01)
    }

    func test_snapshotsWithNoTodos_returnsZeroAnalytics() {
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.0
        )
        let result = TodoAnalyticsService.compute(from: [snapshot])

        XCTAssertEqual(result.totalCreated, 0)
        XCTAssertEqual(result.completionRate, 0.0, accuracy: 0.01)
    }

    // MARK: - Completion Rate

    func test_allTodosCompleted_rateIsOne() {
        let todos = [
            MindCheckEntry(category: .todo, text: "A", context: .morning, isAccomplished: true),
            MindCheckEntry(category: .todo, text: "B", context: .morning, isAccomplished: true)
        ]
        let snapshot = Self.makeSnapshot(date: Date(), todos: todos)
        let result = TodoAnalyticsService.compute(from: [snapshot])

        XCTAssertEqual(result.completionRate, 1.0, accuracy: 0.01)
        XCTAssertEqual(result.totalCompleted, 2)
        XCTAssertEqual(result.totalCreated, 2)
    }

    func test_halfTodosCompleted_rateIsFifty() {
        let todos = [
            MindCheckEntry(category: .todo, text: "A", context: .morning, isAccomplished: true),
            MindCheckEntry(category: .todo, text: "B", context: .morning, isAccomplished: false)
        ]
        let snapshot = Self.makeSnapshot(date: Date(), todos: todos)
        let result = TodoAnalyticsService.compute(from: [snapshot])

        XCTAssertEqual(result.completionRate, 0.5, accuracy: 0.01)
    }

    func test_unreviewed_todosNotCountedAsCompleted() {
        let todos = [
            MindCheckEntry(category: .todo, text: "A", context: .morning, isAccomplished: nil)
        ]
        let snapshot = Self.makeSnapshot(date: Date(), todos: todos)
        let result = TodoAnalyticsService.compute(from: [snapshot])

        XCTAssertEqual(result.totalCreated, 1)
        XCTAssertEqual(result.totalCompleted, 0)
        XCTAssertEqual(result.completionRate, 0.0, accuracy: 0.01)
    }

    // MARK: - Streaks

    func test_consecutiveDaysWithCompletions_buildsStreak() {
        let cal = Calendar.current
        let today = Date()
        let snapshots = (0..<3).map { daysAgo -> DailySmileySnapshot in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            let todo = MindCheckEntry(
                category: .todo, text: "Task", context: .morning, isAccomplished: true
            )
            return Self.makeSnapshot(date: date, todos: [todo])
        }
        let result = TodoAnalyticsService.compute(from: snapshots)

        XCTAssertEqual(result.currentStreak, 3)
        XCTAssertEqual(result.bestStreak, 3)
    }

    func test_brokenStreak_resetsCurrentButKeepsBest() {
        let cal = Calendar.current
        let today = Date()

        let day0 = Self.makeSnapshot(
            date: today,
            todos: [MindCheckEntry(category: .todo, text: "A", context: .morning, isAccomplished: true)]
        )
        let day1 = Self.makeSnapshot(
            date: cal.date(byAdding: .day, value: -1, to: today)!,
            todos: [MindCheckEntry(category: .todo, text: "B", context: .morning, isAccomplished: false)]
        )
        let day2 = Self.makeSnapshot(
            date: cal.date(byAdding: .day, value: -2, to: today)!,
            todos: [MindCheckEntry(category: .todo, text: "C", context: .morning, isAccomplished: true)]
        )
        let day3 = Self.makeSnapshot(
            date: cal.date(byAdding: .day, value: -3, to: today)!,
            todos: [MindCheckEntry(category: .todo, text: "D", context: .morning, isAccomplished: true)]
        )

        let result = TodoAnalyticsService.compute(from: [day0, day1, day2, day3])

        XCTAssertEqual(result.currentStreak, 1)
        XCTAssertEqual(result.bestStreak, 2)
    }

    // MARK: - Average Per Day

    func test_averagePerDay_calculatesCorrectly() {
        let cal = Calendar.current
        let today = Date()

        let day0 = Self.makeSnapshot(date: today, todos: [
            MindCheckEntry(category: .todo, text: "A", context: .morning, isAccomplished: true),
            MindCheckEntry(category: .todo, text: "B", context: .morning, isAccomplished: true)
        ])
        let day1 = Self.makeSnapshot(
            date: cal.date(byAdding: .day, value: -1, to: today)!,
            todos: [MindCheckEntry(category: .todo, text: "C", context: .morning, isAccomplished: true)]
        )

        let result = TodoAnalyticsService.compute(from: [day0, day1])

        XCTAssertEqual(result.averagePerDay, 1.5, accuracy: 0.01)
    }

    // MARK: - Non-Todo Entries Ignored

    func test_nonTodoEntries_areNotCounted() {
        let entries: [MindCheckEntry] = [
            MindCheckEntry(category: .todo, text: "Task", context: .morning, isAccomplished: true),
            MindCheckEntry(category: .gratitude, text: "Sun", context: .morning),
            MindCheckEntry(category: .thinking, text: "Idea", context: .morning)
        ]
        let snapshot = Self.makeSnapshot(date: Date(), todos: entries)
        let result = TodoAnalyticsService.compute(from: [snapshot])

        XCTAssertEqual(result.totalCreated, 1)
        XCTAssertEqual(result.totalCompleted, 1)
    }

    // MARK: - Helpers

    private static func makeSnapshot(date: Date, todos: [MindCheckEntry]) -> DailySmileySnapshot {
        DailySmileySnapshot(
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
