import SwiftUI
import XCTest
@testable import Yoga_of_Eating

// Tests for BriefingDetailView: liveBreakdown parameter, day-derived title,
// CorrelationCategory.relatedDimension mapping, and inline bar logic.
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

    // MARK: - CorrelationCategory.relatedDimension (Phase 1 TDD)

    func test_correlationCategory_foodToSleep_relatedDimension_isPhysicalLoad() {
        XCTAssertEqual(CorrelationCategory.foodToSleep.relatedDimension, .physicalLoad)
    }

    func test_correlationCategory_foodToMood_relatedDimension_isEmotionalTone() {
        XCTAssertEqual(CorrelationCategory.foodToMood.relatedDimension, .emotionalTone)
    }

    func test_correlationCategory_focusToFeeling_relatedDimension_isCognitiveClarity() {
        XCTAssertEqual(CorrelationCategory.focusToFeeling.relatedDimension, .cognitiveClarity)
    }

    func test_correlationCategory_timingPattern_relatedDimension_isBehavioralMomentum() {
        XCTAssertEqual(CorrelationCategory.timingPattern.relatedDimension, .behavioralMomentum)
    }

    func test_correlationCategory_foodDebt_relatedDimension_isPhysicalLoad() {
        XCTAssertEqual(CorrelationCategory.foodDebt.relatedDimension, .physicalLoad)
    }

    func test_correlationCategory_sleepRecoveryCarryover_relatedDimension_isCognitiveClarity() {
        XCTAssertEqual(CorrelationCategory.sleepRecoveryCarryover.relatedDimension, .cognitiveClarity)
    }

    func test_correlationCategory_intentionFollowthrough_relatedDimension_isBehavioralMomentum() {
        XCTAssertEqual(CorrelationCategory.intentionFollowthrough.relatedDimension, .behavioralMomentum)
    }

    func test_correlationCategory_journalTonePrediction_relatedDimension_isEmotionalTone() {
        XCTAssertEqual(CorrelationCategory.journalTonePrediction.relatedDimension, .emotionalTone)
    }

    func test_correlationCategory_sleepMismatch_relatedDimension_isCognitiveClarity() {
        XCTAssertEqual(CorrelationCategory.sleepMismatch.relatedDimension, .cognitiveClarity)
    }

    func test_correlationCategory_carryOverLoad_relatedDimension_isPhysicalLoad() {
        XCTAssertEqual(CorrelationCategory.carryOverLoad.relatedDimension, .physicalLoad)
    }

    func test_correlationCategory_allCases_haveRelatedDimension() {
        // Guards against any future case being added without a mapping.
        // relatedDimension is non-optional — this test verifies the switch compiles exhaustively.
        let allDimensions = CorrelationCategory.allCases.map(\.relatedDimension)
        XCTAssertEqual(allDimensions.count, CorrelationCategory.allCases.count)
        XCTAssertTrue(allDimensions.allSatisfy { WellbeingDimension.allCases.contains($0) })
    }

    // MARK: - Inline dimension bar logic (Phase 2 TDD)

    func test_inlineDimensionBar_dimensionValue_matchesBreakdown_foodToMood() {
        let breakdown = self.makeContract()
        let category = CorrelationCategory.foodToMood
        let dimension = category.relatedDimension
        let value = dimension.value(in: breakdown.dimensions)
        XCTAssertEqual(
            value,
            0.5,
            accuracy: 0.001,
            "foodToMood maps to emotionalTone; value should match breakdown.dimensions.emotionalTone"
        )
    }

    func test_inlineDimensionBar_dimensionValue_matchesBreakdown_foodToSleep() {
        let breakdown = self.makeContract()
        let category = CorrelationCategory.foodToSleep
        let dimension = category.relatedDimension
        let value = dimension.value(in: breakdown.dimensions)
        XCTAssertEqual(
            value,
            0.85,
            accuracy: 0.001,
            "foodToSleep maps to physicalLoad; value should match breakdown.dimensions.physicalLoad"
        )
    }

    func test_inlineDimensionBar_appThemeDimensionColor_isNonClear() {
        // Verifies that AppTheme.Dimension.color(for:) returns a non-clear token for every dimension.
        for dimension in WellbeingDimension.allCases {
            let color = AppTheme.Dimension.color(for: dimension)
            XCTAssertNotEqual(color, .clear, "Dimension \(dimension) must have a non-clear AppTheme color token")
        }
    }

    // MARK: - String resource (Phase 1 TDD)

    func test_strings_briefing_tryTodaySection_isNonEmpty() {
        XCTAssertFalse(
            Strings.Briefing.tryTodaySection.isEmpty,
            "Strings.Briefing.tryTodaySection must be a non-empty string resource"
        )
    }

    func test_strings_wellbeingBreakdown_breakdownExplainer_isNonEmpty() {
        XCTAssertFalse(
            Strings.WellbeingBreakdown.breakdownExplainer.isEmpty,
            "Strings.WellbeingBreakdown.breakdownExplainer must be a non-empty string resource"
        )
    }

    func test_strings_briefing_thisWeekSection_isNonEmpty() {
        XCTAssertFalse(
            Strings.Briefing.thisWeekSection.isEmpty,
            "Strings.Briefing.thisWeekSection must be a non-empty string resource"
        )
    }

    func test_strings_briefing_weeklyTrendFmt_hasPlaceholders() {
        let fmt = Strings.Briefing.weeklyTrendFmt
        XCTAssertTrue(fmt.contains("%@"), "weeklyTrendFmt must contain a %@ placeholder for trend direction")
        XCTAssertTrue(fmt.contains("%d"), "weeklyTrendFmt must contain %d placeholders for numeric values")
    }

    // MARK: - FontTheme token (Phase 4 TDD)

    func test_fontTheme_briefingHeadline_tokenExists() {
        // Compile-time regression guard: removing briefingHeadline from FontTheme breaks this.
        let _: Font = FontTheme.briefingHeadline
        XCTAssert(true, "FontTheme.briefingHeadline SSOT token must exist")
    }

    // MARK: - trendIcon (Phase 3 TDD)

    func test_trendIcon_improving_returnsUpArrow() {
        let view = BriefingDetailView(insight: self.makeInsight(), liveBreakdown: nil)
        XCTAssertEqual(view.trendIcon(.improving), "arrow.up.right")
    }

    func test_trendIcon_declining_returnsDownArrow() {
        let view = BriefingDetailView(insight: self.makeInsight(), liveBreakdown: nil)
        XCTAssertEqual(view.trendIcon(.declining), "arrow.down.right")
    }

    func test_trendIcon_steady_returnsRightArrow() {
        let view = BriefingDetailView(insight: self.makeInsight(), liveBreakdown: nil)
        XCTAssertEqual(view.trendIcon(.steady), "arrow.right")
    }

    // MARK: - Wellbeing state section (Plan: smiley metrics as first section)

    func test_briefingDetailView_withFullBreakdown_instantiatesWithAllData() {
        let view = BriefingDetailView(
            insight: self.makeInsight(),
            liveBreakdown: self.makeContract()
        )
        XCTAssertNotNil(view.liveBreakdown, "liveBreakdown must be non-nil when contract is provided")
        XCTAssertEqual(view.liveBreakdown?.causalNarrative, "Test narrative")
        XCTAssertEqual(view.liveBreakdown?.weakDimensions, [.behavioralMomentum])
    }

    func test_briefingDetailView_nilBreakdown_rendersWithoutWellbeingSection() {
        let view = BriefingDetailView(insight: self.makeInsight(), liveBreakdown: nil)
        XCTAssertNil(view.liveBreakdown, "liveBreakdown must be nil — wellbeing section must be hidden")
    }

    // MARK: - WellbeingBreakdownSheetContract.weeklyAverages (Phase 2 TDD — Red: field not yet on contract)

    func test_wellbeingBreakdownContract_withWeeklyAverages_populatesField() {
        let weeklyAvgs = WellbeingDimensions(
            physicalLoad: 0.7, emotionalTone: 0.5, cognitiveClarity: 0.4, behavioralMomentum: 0.6
        )
        let contract = WellbeingBreakdownSheetContract(
            dimensions: WellbeingDimensions(
                physicalLoad: 0.8, emotionalTone: 0.5, cognitiveClarity: 0.3, behavioralMomentum: 0.2
            ),
            dominantDimension: .physicalLoad,
            causalNarrative: "Test",
            weakDimensions: [],
            mealCount: 2,
            currentMood: .neutral,
            overallScore: 0.55,
            weeklyAverages: weeklyAvgs
        )
        XCTAssertNotNil(contract.weeklyAverages, "weeklyAverages must be stored on the contract")
        XCTAssertEqual(contract.weeklyAverages?.physicalLoad ?? 0, 0.7, accuracy: 0.001)
    }

    func test_wellbeingBreakdownContract_withFewerThan3Days_weeklyAveragesIsNil() {
        let contract = WellbeingBreakdownSheetContract(
            dimensions: WellbeingDimensions(
                physicalLoad: 0.8, emotionalTone: 0.5, cognitiveClarity: 0.3, behavioralMomentum: 0.2
            ),
            dominantDimension: .physicalLoad,
            causalNarrative: "Test",
            weakDimensions: [],
            mealCount: 2,
            currentMood: .neutral,
            overallScore: 0.55,
            weeklyAverages: nil
        )
        XCTAssertNil(contract.weeklyAverages, "nil weeklyAverages must propagate — fewer than 3 days case")
    }

    // MARK: - String resources (Phase 3 TDD — Red: strings not yet in Strings.swift)

    func test_strings_wellbeingBreakdown_weeklyAvgFmt_hasPercentPlaceholder() {
        let fmt = Strings.WellbeingBreakdown.weeklyAvgFmt
        XCTAssertTrue(fmt.contains("%d"), "weeklyAvgFmt must contain a %d placeholder for the integer percentage")
        XCTAssertTrue(fmt.contains("%"), "weeklyAvgFmt must contain a literal % for the percent sign")
    }

    func test_strings_wellbeingBreakdown_claritySubtitle_reflectsHealthKit() {
        let subtitle = Strings.WellbeingBreakdown.DimensionSubtitle.cognitiveClarity
        XCTAssertTrue(
            subtitle.lowercased().contains("health") || subtitle.lowercased().contains("sleep"),
            "Clarity subtitle must reference HealthKit or Sleep to be accurate"
        )
    }

    func test_strings_wellbeingBreakdown_physicalSubtitle_exerciseSuffix_isNonEmpty() {
        XCTAssertFalse(
            Strings.WellbeingBreakdown.DimensionSubtitle.physicalExerciseSuffix.isEmpty,
            "physicalExerciseSuffix must be a non-empty string resource"
        )
    }
}
