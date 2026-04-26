import XCTest
@testable import Yoga_of_Eating

final class TrendDataServiceTests: XCTestCase {
    func test_buildTrendPoints_empty_returnsEmpty() {
        let points = TrendDataService.buildTrendPoints(snapshots: [], days: 14)
        XCTAssertTrue(points.isEmpty)
    }

    func test_buildTrendPoints_filtersByWindow() {
        let old = DailySmileySnapshot.create(
            date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
            smileyState: .neutral,
            meals: []
        )
        let recent = DailySmileySnapshot.create(
            date: Date(),
            smileyState: .neutral,
            meals: []
        )
        let points = TrendDataService.buildTrendPoints(snapshots: [old, recent], days: 14)
        XCTAssertEqual(points.count, 1)
    }

    func test_buildTrendPoints_mapsProgressAndScores() {
        let snapshot = DailySmileySnapshot.create(
            date: Date(),
            smileyState: .neutral,
            meals: [Meal(mealType: .lunch, items: ["Salad"], healthScore: 0.8)],
            reflection: DailyReflection(
                feeling: .calm,
                sleepQuality: .good,
                morningEnergyLevel: 4,
                dailyIntention: "Stay light",
                focusRating: 2
            ),
            morningMindCheck: [
                MindCheckEntry(category: .todo, text: "Walk", context: .morning, isAccomplished: true)
            ],
            eveningMindCheck: [
                MindCheckEntry(category: .gratefulFor, text: "Family", context: .evening),
                MindCheckEntry(category: .observation, text: "Steady", context: .evening)
            ]
        )
        let points = TrendDataService.buildTrendPoints(snapshots: [snapshot], days: 14)
        XCTAssertEqual(points.count, 1)
        XCTAssertGreaterThan(points[0].bis, 0)
        XCTAssertGreaterThan(points[0].reflect, 0)
        XCTAssertGreaterThan(points[0].sleepScore, 0)
    }
}
