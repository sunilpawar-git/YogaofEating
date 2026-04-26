import XCTest
@testable import Yoga_of_Eating

final class ArchetypeClassifierTests: XCTestCase {
    func test_classify_insufficientData_returnsInconsistent() {
        let snapshots = (0..<3).map { Self.snapshot(daysAgo: $0, mealHour: 12, focus: 2) }
        XCTAssertEqual(ArchetypeClassifier.classify(snapshots: snapshots), .inconsistent)
    }

    func test_classify_steadyState() {
        let snapshots = (0..<7).map { Self.snapshot(daysAgo: $0, mealHour: 15, focus: 3) }
        XCTAssertEqual(ArchetypeClassifier.classify(snapshots: snapshots), .steadyState)
    }

    func test_classify_nocturnalOwl() {
        let snapshots = (0..<7).map { Self.snapshot(daysAgo: $0, mealHour: 21, focus: 2) }
        XCTAssertEqual(ArchetypeClassifier.classify(snapshots: snapshots), .nocturnalOwl)
    }

    func test_classify_earlyBird() {
        let snapshots = (0..<7).map { Self.snapshot(daysAgo: $0, mealHour: 9, focus: 2) }
        XCTAssertEqual(ArchetypeClassifier.classify(snapshots: snapshots), .earlyBird)
    }

    func test_classify_spikeDip() {
        let focuses = [1, 3, 1, 3, 1, 3, 2]
        let snapshots = focuses.enumerated().map { idx, focus in
            Self.snapshot(daysAgo: idx, mealHour: 15, focus: focus)
        }
        XCTAssertEqual(ArchetypeClassifier.classify(snapshots: snapshots), .spikeDip)
    }

    private static func snapshot(daysAgo: Int, mealHour: Int, focus: Int) -> DailySmileySnapshot {
        let baseDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let mealDate = Calendar.current.date(
            bySettingHour: mealHour,
            minute: 0,
            second: 0,
            of: baseDate
        ) ?? baseDate
        return DailySmileySnapshot.create(
            date: baseDate,
            smileyState: .neutral,
            meals: [Meal(timestamp: mealDate, mealType: .lunch, items: ["Meal"], healthScore: 0.6)],
            reflection: DailyReflection(focusRating: focus)
        )
    }
}
