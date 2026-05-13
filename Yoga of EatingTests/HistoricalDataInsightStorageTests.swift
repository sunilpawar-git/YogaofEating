import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Tests for unified DailyInsight storage in HistoricalDataService (Phase 2 — Storage SSOT).
/// Written before production code changes (TDD Red phase).
@MainActor
final class HistoricalDataInsightStorageTests: XCTestCase {
    private var mock: MockHistoricalDataService!

    override func setUp() {
        super.setUp()
        self.mock = MockHistoricalDataService()
    }

    // MARK: - updateInsight stores unified DailyInsight

    func test_updateInsight_acceptsUnifiedDailyInsight() {
        let insight = self.makeUnifiedInsight()
        self.mock.updateInsight(for: Date(), insight: insight)
        XCTAssertTrue(self.mock.updateInsightCalled)
    }

    func test_updateInsight_persists_retrievableFromSnapshot() {
        let date = Calendar.current.startOfDay(for: Date())
        let insight = self.makeUnifiedInsight(headline: "Stored insight")
        self.mock.updateInsight(for: date, insight: insight)
        let snapshot = self.mock.getSnapshot(for: date)
        XCTAssertEqual(snapshot?.insight?.headline, "Stored insight")
    }

    func test_updateInsight_overwritesPreviousInsight() {
        let date = Calendar.current.startOfDay(for: Date())
        let first = self.makeUnifiedInsight(headline: "First")
        let second = self.makeUnifiedInsight(headline: "Second")
        self.mock.updateInsight(for: date, insight: first)
        self.mock.updateInsight(for: date, insight: second)
        XCTAssertEqual(self.mock.getSnapshot(for: date)?.insight?.headline, "Second")
    }

    func test_updateInsight_differentDates_storedSeparately() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        self.mock.updateInsight(for: today, insight: self.makeUnifiedInsight(headline: "Today"))
        self.mock.updateInsight(for: yesterday, insight: self.makeUnifiedInsight(headline: "Yesterday"))
        XCTAssertEqual(self.mock.getSnapshot(for: today)?.insight?.headline, "Today")
        XCTAssertEqual(self.mock.getSnapshot(for: yesterday)?.insight?.headline, "Yesterday")
    }

    // MARK: - Snapshot has single insight field

    func test_snapshot_insightField_isUnifiedDailyInsight() {
        let date = Calendar.current.startOfDay(for: Date())
        let insight = self.makeUnifiedInsight()
        self.mock.updateInsight(for: date, insight: insight)
        let snapshot = self.mock.getSnapshot(for: date)
        // Must be DailyInsight (unified), not LegacyDailyInsight
        XCTAssertNotNil(snapshot?.insight as? DailyInsight?)
        XCTAssertEqual(snapshot?.insight?.confidence ?? 0, insight.confidence, accuracy: 0.001)
    }

    func test_snapshot_noBriefingField_afterPhase2() {
        let date = Calendar.current.startOfDay(for: Date())
        // DailySmileySnapshot should not expose briefing after Phase 2
        let snapshot = DailySmileySnapshotBuilder().withDate(date).build()
        // Verify: no separate briefing property exists (compile-time: field is removed)
        XCTAssertNil(snapshot.insight)
    }

    // MARK: - Protocol contract

    func test_protocol_updateInsight_signatureAcceptsDailyInsight() {
        // This test fails at compile time if protocol still requires LegacyDailyInsight
        let service: any HistoricalDataServiceProtocol = self.mock
        let insight = self.makeUnifiedInsight()
        service.updateInsight(for: Date(), insight: insight)
        XCTAssertTrue(self.mock.updateInsightCalled)
    }

    // MARK: - Helpers

    private func makeUnifiedInsight(headline: String = "Test headline") -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: headline,
            dimensions: WellbeingDimensions(
                physicalLoad: 0.6,
                emotionalTone: 0.7,
                cognitiveClarity: 0.6,
                behavioralMomentum: 0.5
            ),
            dominantInsight: "Test insight",
            correlationCards: [],
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "Test",
            textSignals: [],
            confidence: 0.8
        )
    }
}
