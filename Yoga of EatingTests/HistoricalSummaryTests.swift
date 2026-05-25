import XCTest
@testable import Yoga_of_Eating

@MainActor
final class HistoricalSummaryTests: XCTestCase {
    // MARK: - Helpers

    private func makeService() -> HistoricalDataService {
        HistoricalDataService(persistenceService: MockPersistenceService())
    }

    private func snap(daysAgo: Int, score: Double, from ref: Date = Date()) -> DailySmileySnapshot {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Calendar.current.startOfDay(for: ref))!
        return DailySmileySnapshotBuilder()
            .withDate(date)
            .withMeals([MealBuilder().withScore(score).build()])
            .build()
    }

    private func snapWithDimensions(
        daysAgo: Int,
        dimensions: WellbeingDimensions,
        from ref: Date = Date()
    ) -> DailySmileySnapshot {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Calendar.current.startOfDay(for: ref))!
        var snapshot = DailySmileySnapshotBuilder()
            .withDate(date)
            .withMeals([MealBuilder().withScore(0.7).build()])
            .build()
        snapshot = snapshot.withWellbeingDimensions(dimensions)
        return snapshot
    }

    // MARK: - Tests

    func test_computeHistoricalSummary_30d_averagesFoodScoreCorrectly() {
        let service = self.makeService()
        let ref = Date()
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 1, score: 0.8, from: ref))
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 5, score: 0.6, from: ref))
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 10, score: 0.4, from: ref))

        let summary = service.computeHistoricalSummary(relativeTo: ref)

        XCTAssertEqual(summary.thirtyDayStats.averageFoodScore, (0.8 + 0.6 + 0.4) / 3.0, accuracy: 0.001)
    }

    func test_computeHistoricalSummary_withFewerThan7Days_returnsPartialStats() {
        let service = self.makeService()
        let ref = Date()
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 1, score: 0.7, from: ref))
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 2, score: 0.6, from: ref))
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 3, score: 0.5, from: ref))

        let summary = service.computeHistoricalSummary(relativeTo: ref)

        XCTAssertEqual(summary.thirtyDayStats.daysLogged, 3)
    }

    func test_computeHistoricalSummary_identifiesCurrentStreak() {
        let service = self.makeService()
        let ref = Calendar.current.startOfDay(for: Date())
        // 3 consecutive days
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 0, score: 0.7, from: ref))
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 1, score: 0.7, from: ref))
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 2, score: 0.7, from: ref))
        // gap: day 3 missing
        service.historicalData.addOrUpdate(snapshot: self.snap(daysAgo: 4, score: 0.7, from: ref))

        let summary = service.computeHistoricalSummary(relativeTo: ref)

        XCTAssertEqual(summary.currentStreak, 3)
    }

    func test_computeHistoricalSummary_identifiesBestAndWorstDimension() {
        let service = self.makeService()
        let ref = Date()
        let highPhysical = WellbeingDimensions(
            physicalLoad: 0.9,
            emotionalTone: 0.3,
            cognitiveClarity: 0.3,
            behavioralMomentum: 0.3
        )
        service.historicalData.addOrUpdate(
            snapshot: self.snapWithDimensions(daysAgo: 1, dimensions: highPhysical, from: ref)
        )

        let summary = service.computeHistoricalSummary(relativeTo: ref)

        XCTAssertEqual(summary.bestDimension, .physicalLoad)
        XCTAssertNotEqual(summary.worstDimension, .physicalLoad)
    }

    func test_computeHistoricalSummary_withNoSnapshots_returnsZeroStats() {
        let service = self.makeService()
        let summary = service.computeHistoricalSummary(relativeTo: Date())
        XCTAssertEqual(summary.thirtyDayStats.daysLogged, 0)
        XCTAssertEqual(summary.currentStreak, 0)
        XCTAssertNil(summary.bestDimension)
        XCTAssertNil(summary.worstDimension)
    }
}
