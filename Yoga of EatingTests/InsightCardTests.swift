// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for insight display properties using unified DailyInsight.
    @MainActor
    final class InsightCardTests: XCTestCase {
        // MARK: - DailyInsight display properties

        func test_dailyInsight_hasValidConfidence() {
            let insight = self.makeDailyInsight(confidence: 0.8)
            XCTAssertGreaterThanOrEqual(insight.confidence, 0.0)
            XCTAssertLessThanOrEqual(insight.confidence, 1.0)
        }

        func test_dailyInsight_isViewed_defaultsFalse() {
            let insight = self.makeDailyInsight()
            XCTAssertFalse(insight.isViewed)
        }

        func test_dailyInsight_markAsViewed_updatesFlag() {
            var insight = self.makeDailyInsight()
            insight.markAsViewed()
            XCTAssertTrue(insight.isViewed)
        }

        func test_dailyInsight_headline_isNonEmpty() {
            let insight = self.makeDailyInsight()
            XCTAssertFalse(insight.headline.isEmpty)
        }

        func test_dailyInsight_dominantInsight_isNonEmpty() {
            let insight = self.makeDailyInsight()
            XCTAssertFalse(insight.dominantInsight.isEmpty)
        }

        // MARK: - CorrelationCategory icons (replaces InsightType icons)

        func test_correlationCategory_foodToSleep_hasIcon() {
            XCTAssertFalse(CorrelationCategory.foodToSleep.icon.isEmpty)
        }

        func test_correlationCategory_foodToMood_hasIcon() {
            XCTAssertFalse(CorrelationCategory.foodToMood.icon.isEmpty)
        }

        func test_correlationCategory_allCases_haveNonEmptyIcons() {
            for category in CorrelationCategory.allCases {
                XCTAssertFalse(category.icon.isEmpty, "\(category) should have an icon")
                XCTAssertFalse(category.displayName.isEmpty, "\(category) should have a display name")
            }
        }

        // MARK: - Helpers

        private func makeDailyInsight(confidence: Double = 0.75) -> DailyInsight {
            DailyInsight(
                date: Date(),
                headline: Strings.Insight.Headline.steady,
                dimensions: .neutral,
                dominantInsight: "Your patterns show improvement.",
                correlationCards: [],
                nudge: ActionableNudge(
                    suggestion: Strings.Insight.Nudge.defaultSuggestion,
                    reasoning: Strings.Insight.Nudge.defaultReasoning
                ),
                causalExplanation: "",
                textSignals: [],
                confidence: confidence
            )
        }
    }
#endif
