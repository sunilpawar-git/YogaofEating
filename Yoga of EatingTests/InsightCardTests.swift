// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for InsightCardView and insight display
    /// Phase 7: TDD - Tests written before implementation
    @MainActor
    final class InsightCardTests: XCTestCase {
        // MARK: - Tests: Insight Display Properties

        func test_insightType_icon_isValid() {
            // Assert all types have valid SF Symbol icons
            for insightType in InsightType.allCases {
                XCTAssertFalse(insightType.icon.isEmpty, "\(insightType) should have an icon")
            }
        }

        func test_insightType_displayName_isValid() {
            // Assert all types have display names
            for insightType in InsightType.allCases {
                XCTAssertFalse(insightType.displayName.isEmpty, "\(insightType) should have a display name")
            }
        }

        func test_dailyInsight_hasValidConfidence() {
            // Arrange
            let insight = LegacyDailyInsight(
                date: Date(),
                insightText: "Test insight",
                insightType: .foodSleep,
                confidence: 0.8
            )

            // Assert
            XCTAssertGreaterThanOrEqual(insight.confidence, 0.0)
            XCTAssertLessThanOrEqual(insight.confidence, 1.0)
        }

        func test_dailyInsight_isViewed_defaultsFalse() {
            // Arrange
            let insight = LegacyDailyInsight(
                date: Date(),
                insightText: "Test insight",
                insightType: .pattern,
                confidence: 0.7
            )

            // Assert
            XCTAssertFalse(insight.isViewed)
        }

        func test_dailyInsight_markAsViewed_updatesFlag() {
            // Arrange
            var insight = LegacyDailyInsight(
                date: Date(),
                insightText: "Test insight",
                insightType: .encouragement,
                confidence: 0.6
            )

            // Act
            insight.markAsViewed()

            // Assert
            XCTAssertTrue(insight.isViewed)
        }

        // MARK: - Tests: Insight Type Selection

        // Note: ViewModel integration tests removed as insight persistence is not yet implemented

        func test_insightType_foodSleep_hasCorrectIcon() {
            XCTAssertEqual(InsightType.foodSleep.icon, "moon.zzz.fill")
        }

        func test_insightType_mindsetFeeling_hasCorrectIcon() {
            XCTAssertEqual(InsightType.mindsetFeeling.icon, "brain.head.profile")
        }

        func test_insightType_pattern_hasCorrectIcon() {
            XCTAssertEqual(InsightType.pattern.icon, "chart.line.uptrend.xyaxis")
        }

        func test_insightType_encouragement_hasCorrectIcon() {
            XCTAssertEqual(InsightType.encouragement.icon, "sparkles")
        }
    }
#endif
