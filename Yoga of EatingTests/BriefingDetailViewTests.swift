import XCTest
@testable import Yoga_of_Eating

// Tests for BriefingDetailView: liveBreakdown parameter and day-derived title.
final class BriefingDetailViewTests: XCTestCase {
    private func makeInsight() -> DailyInsight {
        DailyInsight(
            date: Date(),
            headline: "Test headline",
            dimensions: .neutral,
            dominantInsight: "Test insight",
            correlationCards: [],
            nudge: ActionableNudge(
                suggestion: Strings.Insight.Nudge.defaultSuggestion,
                reasoning: Strings.Insight.Nudge.defaultReasoning
            ),
            causalExplanation: "",
            textSignals: [],
            confidence: 0.8
        )
    }

    private func makeContract() -> WellbeingBreakdownSheetContract {
        WellbeingBreakdownSheetContract(
            dimensions: WellbeingDimensions(
                physicalLoad: 0.85, emotionalTone: 0.5,
                cognitiveClarity: 0.31, behavioralMomentum: 0.1
            ),
            dominantDimension: .physicalLoad,
            causalNarrative: "Test narrative",
            weakDimensions: [.behavioralMomentum],
            mealCount: 2,
            currentMood: .neutral,
            overallScore: 0.44
        )
    }

    func test_briefingDetailView_withNilLiveBreakdown_canBeInstantiated() {
        let view = BriefingDetailView(insight: self.makeInsight(), liveBreakdown: nil)
        XCTAssertNotNil(view)
    }

    func test_briefingDetailView_withLiveBreakdown_canBeInstantiated() {
        let view = BriefingDetailView(
            insight: self.makeInsight(),
            liveBreakdown: self.makeContract()
        )
        XCTAssertNotNil(view)
    }

    func test_briefingDetailView_insightsTitle_containsDayName() {
        // Monday Jan 1 2024
        let monday = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let title = BriefingDetailView.insightsTitle(for: monday)
        XCTAssertTrue(title.contains("Monday"), "Title must contain the day name")
        XCTAssertTrue(title.contains("Insights"), "Title must contain 'Insights'")
    }

    func test_briefingDetailView_insightsTitle_formatMatchesStrings() {
        let date = Date()
        let title = BriefingDetailView.insightsTitle(for: date)
        XCTAssertFalse(title.isEmpty)
        XCTAssertFalse(title.contains("%@"), "Title must not contain unformatted placeholders")
    }
}
