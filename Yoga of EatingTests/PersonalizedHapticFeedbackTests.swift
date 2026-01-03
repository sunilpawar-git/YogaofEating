#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class PersonalizedHapticFeedbackTests: XCTestCase {
        var sut: SensoryService!
        var mockUserDefaults: UserDefaults!

        override func setUp() {
            super.setUp()
            self.mockUserDefaults = UserDefaults(suiteName: "TestDefaults")
            self.mockUserDefaults?.removePersistentDomain(forName: "TestDefaults")
            // Enable haptics by default for testing
            self.mockUserDefaults?.set(true, forKey: "haptics_enabled")
            self.sut = SensoryService.shared
        }

        override func tearDown() {
            self.mockUserDefaults?.removePersistentDomain(forName: "TestDefaults")
            self.mockUserDefaults = nil
            self.sut = nil
            super.tearDown()
        }

        // MARK: - Haptic Style Selection Tests

        func test_getFeedbackStyle_healthyMealLowRisk_returnsSoft() {
            // Given: Healthy meal (0.8) for low-risk user
            let healthScore = 0.8
            let riskLevel = HealthRiskLevel.low

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return soft haptic
            XCTAssertEqual(style, .soft)
        }

        func test_getFeedbackStyle_healthyMealHighRisk_returnsSoft() {
            // Given: Healthy meal (0.75) for high-risk user
            let healthScore = 0.75
            let riskLevel = HealthRiskLevel.high

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return soft haptic (celebrate healthy choice)
            XCTAssertEqual(style, .soft)
        }

        func test_getFeedbackStyle_unhealthyMealLowRisk_returnsLight() {
            // Given: Unhealthy meal (0.3) for low-risk user
            let healthScore = 0.3
            let riskLevel = HealthRiskLevel.low

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return light haptic (gentle nudge)
            XCTAssertEqual(style, .light)
        }

        func test_getFeedbackStyle_unhealthyMealMediumRisk_returnsMedium() {
            // Given: Unhealthy meal (0.25) for medium-risk user
            let healthScore = 0.25
            let riskLevel = HealthRiskLevel.medium

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return medium haptic (firmer nudge)
            XCTAssertEqual(style, .medium)
        }

        func test_getFeedbackStyle_unhealthyMealHighRisk_returnsHeavy() {
            // Given: Unhealthy meal (0.2) for high-risk user
            let healthScore = 0.2
            let riskLevel = HealthRiskLevel.high

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return heavy haptic (strong nudge for at-risk user)
            XCTAssertEqual(style, .heavy)
        }

        func test_getFeedbackStyle_neutralMeal_returnsLight() {
            // Given: Neutral meal (0.5) for any risk level
            let healthScore = 0.5
            let riskLevel = HealthRiskLevel.medium

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return light haptic
            XCTAssertEqual(style, .light)
        }

        func test_getFeedbackStyle_boundaryHealthy_returnsSoft() {
            // Given: Score at healthy boundary (0.66)
            let healthScore = 0.66
            let riskLevel = HealthRiskLevel.low

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return soft
            XCTAssertEqual(style, .soft)
        }

        func test_getFeedbackStyle_boundaryUnhealthy_returnsLight() {
            // Given: Score at unhealthy boundary (0.34) for low-risk
            let healthScore = 0.34
            let riskLevel = HealthRiskLevel.low

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return light
            XCTAssertEqual(style, .light)
        }

        // MARK: - Edge Cases

        func test_getFeedbackStyle_perfectScore_returnsSoft() {
            // Given: Perfect score (1.0)
            let healthScore = 1.0
            let riskLevel = HealthRiskLevel.low

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return soft
            XCTAssertEqual(style, .soft)
        }

        func test_getFeedbackStyle_worstScoreHighRisk_returnsHeavy() {
            // Given: Worst score (0.0) for high-risk user
            let healthScore = 0.0
            let riskLevel = HealthRiskLevel.high

            // When
            let style = self.sut.getFeedbackStyle(for: healthScore, riskLevel: riskLevel)

            // Then: Should return heavy
            XCTAssertEqual(style, .heavy)
        }

        // MARK: - Consistency Tests

        func test_getFeedbackStyle_consistency_acrossRiskLevels() {
            // Given: Very unhealthy meal (0.15)
            let healthScore = 0.15

            // When
            let lowRisk = self.sut.getFeedbackStyle(for: healthScore, riskLevel: .low)
            let mediumRisk = self.sut.getFeedbackStyle(for: healthScore, riskLevel: .medium)
            let highRisk = self.sut.getFeedbackStyle(for: healthScore, riskLevel: .high)

            // Then: Should escalate feedback intensity with risk level
            XCTAssertEqual(lowRisk, .light)
            XCTAssertEqual(mediumRisk, .medium)
            XCTAssertEqual(highRisk, .heavy)
        }

        func test_getFeedbackStyle_healthyMeal_sameForAllRiskLevels() {
            // Given: Healthy meal (0.8)
            let healthScore = 0.8

            // When
            let lowRisk = self.sut.getFeedbackStyle(for: healthScore, riskLevel: .low)
            let mediumRisk = self.sut.getFeedbackStyle(for: healthScore, riskLevel: .medium)
            let highRisk = self.sut.getFeedbackStyle(for: healthScore, riskLevel: .high)

            // Then: Should all be soft (celebrate healthy choice equally)
            XCTAssertEqual(lowRisk, .soft)
            XCTAssertEqual(mediumRisk, .soft)
            XCTAssertEqual(highRisk, .soft)
        }

        // MARK: - Integration with playMealFeedbackHaptic

        func test_playMealFeedbackHaptic_withHealthyMeal_doesNotThrow() {
            // Given: Healthy meal for low-risk user
            let healthScore = 0.8
            let riskLevel = HealthRiskLevel.low

            // When/Then: Should not throw
            XCTAssertNoThrow(
                self.sut.playMealFeedbackHaptic(for: healthScore, riskLevel: riskLevel)
            )
        }

        func test_playMealFeedbackHaptic_withUnhealthyMealHighRisk_doesNotThrow() {
            // Given: Unhealthy meal for high-risk user
            let healthScore = 0.2
            let riskLevel = HealthRiskLevel.high

            // When/Then: Should not throw
            XCTAssertNoThrow(
                self.sut.playMealFeedbackHaptic(for: healthScore, riskLevel: riskLevel)
            )
        }

        func test_playMealFeedbackHaptic_withHapticsDisabled_doesNotCrash() {
            // Given: Haptics disabled
            self.mockUserDefaults?.set(false, forKey: "haptics_enabled")

            // When/Then: Should handle gracefully
            XCTAssertNoThrow(
                self.sut.playMealFeedbackHaptic(for: 0.5, riskLevel: .medium, userDefaults: self.mockUserDefaults)
            )
        }

        func test_playMealFeedbackHaptic_respectsUserPreferences() {
            // Given: Haptics enabled
            self.mockUserDefaults?.set(true, forKey: "haptics_enabled")

            // When/Then: Should not crash with valid inputs
            XCTAssertNoThrow(
                self.sut.playMealFeedbackHaptic(for: 0.3, riskLevel: .high, userDefaults: self.mockUserDefaults)
            )

            // Given: Haptics disabled
            self.mockUserDefaults?.set(false, forKey: "haptics_enabled")

            // When/Then: Should still not crash (just skip haptic)
            XCTAssertNoThrow(
                self.sut.playMealFeedbackHaptic(for: 0.3, riskLevel: .high, userDefaults: self.mockUserDefaults)
            )
        }
    }
#endif
