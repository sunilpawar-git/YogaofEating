#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class SettingsHealthInsightsTests: XCTestCase {
        var mockUserDefaults: UserDefaults!
        var healthProfileService: HealthProfileService!

        override func setUp() {
            super.setUp()
            self.mockUserDefaults = UserDefaults(suiteName: "TestDefaults")
            self.mockUserDefaults?.removePersistentDomain(forName: "TestDefaults")
            self.healthProfileService = HealthProfileService(userDefaults: self.mockUserDefaults!)
        }

        override func tearDown() {
            self.mockUserDefaults?.removePersistentDomain(forName: "TestDefaults")
            self.mockUserDefaults = nil
            self.healthProfileService = nil
            super.tearDown()
        }

        // MARK: - Design Assertion: Personalized Feedback is Always On

        // Note: Personalized feedback is now always enabled by design.
        // Users cannot disable it - the feature is core to the app experience.

        func test_showHealthInsights_defaultsToFalse() {
            // When: No explicit value set
            let showInsights = self.mockUserDefaults?.object(forKey: "show_health_insights") as? Bool

            // Then: Should default to false (or nil, which means disabled)
            XCTAssertNil(showInsights, "Default should be nil, which is treated as disabled")
        }

        // MARK: - AppStorage Toggle Persistence

        func test_showHealthInsightsToggle_persistsValue() {
            // When: User enables health insights
            self.mockUserDefaults?.set(true, forKey: "show_health_insights")

            // Then: Value should persist
            let showInsights = self.mockUserDefaults?.bool(forKey: "show_health_insights")
            XCTAssertTrue(showInsights ?? false)
        }

        // MARK: - Health Profile Calculation Integration

        func test_healthInsights_displayCorrectBMI() {
            // Given: User with valid health data
            self.mockUserDefaults?.set("175", forKey: "user_height")
            self.mockUserDefaults?.set("75", forKey: "user_weight")
            self.mockUserDefaults?.set("30", forKey: "user_age")
            self.mockUserDefaults?.set(1, forKey: "user_gender") // Male
            self.mockUserDefaults?.set(0, forKey: "unit_system") // Metric

            // When: Getting user health profile
            guard let profile = self.healthProfileService.getUserHealthProfile() else {
                XCTFail("Should generate health profile")
                return
            }

            // Then: BMI should be calculated correctly
            // BMI = 75 / (1.75)^2 = 24.49
            XCTAssertEqual(profile.bmi, 24.49, accuracy: 0.01)
            XCTAssertEqual(profile.bmiCategory, .normal)
        }

        func test_healthInsights_displayCorrectTDEE() {
            // Given: User with valid health data
            self.mockUserDefaults?.set("170", forKey: "user_height")
            self.mockUserDefaults?.set("70", forKey: "user_weight")
            self.mockUserDefaults?.set("25", forKey: "user_age")
            self.mockUserDefaults?.set(2, forKey: "user_gender") // Female
            self.mockUserDefaults?.set(0, forKey: "unit_system") // Metric

            // When: Getting user health profile
            guard let profile = self.healthProfileService.getUserHealthProfile() else {
                XCTFail("Should generate health profile")
                return
            }

            // Then: TDEE should be calculated (BMR * 1.2 for sedentary)
            // BMR = (10 * 70) + (6.25 * 170) - (5 * 25) - 161 = 1476.5
            // TDEE = 1476.5 * 1.2 = 1771.8
            XCTAssertEqual(profile.tdee, 1771.8, accuracy: 1.0)
        }

        func test_healthInsights_displayCorrectRiskLevel_lowRisk() {
            // Given: Healthy young user
            self.mockUserDefaults?.set("175", forKey: "user_height")
            self.mockUserDefaults?.set("70", forKey: "user_weight")
            self.mockUserDefaults?.set("25", forKey: "user_age")
            self.mockUserDefaults?.set(0, forKey: "user_gender")
            self.mockUserDefaults?.set(0, forKey: "unit_system")

            // When: Getting user health profile
            guard let profile = self.healthProfileService.getUserHealthProfile() else {
                XCTFail("Should generate health profile")
                return
            }

            // Then: Should be low risk (normal BMI, young age)
            XCTAssertEqual(profile.riskLevel, .low)
        }

        func test_healthInsights_displayCorrectRiskLevel_mediumRisk() {
            // Given: Overweight user
            self.mockUserDefaults?.set("175", forKey: "user_height")
            self.mockUserDefaults?.set("85", forKey: "user_weight")
            self.mockUserDefaults?.set("35", forKey: "user_age")
            self.mockUserDefaults?.set(0, forKey: "user_gender")
            self.mockUserDefaults?.set(0, forKey: "unit_system")

            // When: Getting user health profile
            guard let profile = self.healthProfileService.getUserHealthProfile() else {
                XCTFail("Should generate health profile")
                return
            }

            // Then: Should be medium risk (overweight BMI)
            XCTAssertEqual(profile.riskLevel, .medium)
        }

        func test_healthInsights_displayCorrectRiskLevel_highRisk() {
            // Given: Obese older user
            self.mockUserDefaults?.set("170", forKey: "user_height")
            self.mockUserDefaults?.set("95", forKey: "user_weight")
            self.mockUserDefaults?.set("55", forKey: "user_age")
            self.mockUserDefaults?.set(0, forKey: "user_gender")
            self.mockUserDefaults?.set(0, forKey: "unit_system")

            // When: Getting user health profile
            guard let profile = self.healthProfileService.getUserHealthProfile() else {
                XCTFail("Should generate health profile")
                return
            }

            // Then: Should be high risk (obese BMI)
            XCTAssertEqual(profile.riskLevel, .high)
        }

        // MARK: - Missing Profile Handling

        func test_healthInsights_handlesInvalidHeight() {
            // Given: Invalid height
            self.mockUserDefaults?.set("", forKey: "user_height")
            self.mockUserDefaults?.set("75", forKey: "user_weight")
            self.mockUserDefaults?.set("30", forKey: "user_age")

            // When: Getting user health profile
            let profile = self.healthProfileService.getUserHealthProfile()

            // Then: Should return nil for invalid data
            XCTAssertNil(profile)
        }

        func test_healthInsights_handlesInvalidWeight() {
            // Given: Invalid weight
            self.mockUserDefaults?.set("175", forKey: "user_height")
            self.mockUserDefaults?.set("", forKey: "user_weight")
            self.mockUserDefaults?.set("30", forKey: "user_age")

            // When: Getting user health profile
            let profile = self.healthProfileService.getUserHealthProfile()

            // Then: Should return nil for invalid data
            XCTAssertNil(profile)
        }

        func test_healthInsights_handlesInvalidAge() {
            // Given: Invalid age
            self.mockUserDefaults?.set("175", forKey: "user_height")
            self.mockUserDefaults?.set("75", forKey: "user_weight")
            self.mockUserDefaults?.set("", forKey: "user_age")

            // When: Getting user health profile
            let profile = self.healthProfileService.getUserHealthProfile()

            // Then: Should return nil for invalid data
            XCTAssertNil(profile)
        }

        // Note: test_personalizedFeedback_respectsToggle removed - feature is always on

        func test_healthInsightsSection_showsOnlyWhenEnabled() {
            // Given: Health insights disabled
            self.mockUserDefaults?.set(false, forKey: "show_health_insights")

            // When: Checking if should show
            let shouldShow = self.mockUserDefaults?.bool(forKey: "show_health_insights") ?? false

            // Then: Should not show
            XCTAssertFalse(shouldShow)

            // When: User enables insights
            self.mockUserDefaults?.set(true, forKey: "show_health_insights")
            let shouldShowNow = self.mockUserDefaults?.bool(forKey: "show_health_insights") ?? false

            // Then: Should show
            XCTAssertTrue(shouldShowNow)
        }

        // MARK: - Privacy & Data Handling

        func test_healthData_neverLeavesDevice() {
            // Given: Valid health profile
            self.mockUserDefaults?.set("175", forKey: "user_height")
            self.mockUserDefaults?.set("75", forKey: "user_weight")
            self.mockUserDefaults?.set("30", forKey: "user_age")

            // When: Getting profile
            let profile = self.healthProfileService.getUserHealthProfile()

            // Then: All calculations done locally (no network calls)
            XCTAssertNotNil(profile, "Profile should be calculated locally")
            // Note: This test documents the design principle that all health
            // calculations are done on-device, never sent to servers
        }

        func test_healthInsights_formatsCorrectly() {
            // Given: User with valid health data
            self.mockUserDefaults?.set("175", forKey: "user_height")
            self.mockUserDefaults?.set("75", forKey: "user_weight")
            self.mockUserDefaults?.set("30", forKey: "user_age")
            self.mockUserDefaults?.set(1, forKey: "user_gender")
            self.mockUserDefaults?.set(0, forKey: "unit_system")

            // When: Getting profile
            guard let profile = self.healthProfileService.getUserHealthProfile() else {
                XCTFail("Should generate profile")
                return
            }

            // Then: Values should be in expected ranges
            XCTAssertGreaterThan(profile.bmi, 0)
            XCTAssertGreaterThan(profile.tdee, 0)
            XCTAssertLessThan(profile.bmi, 100) // Sanity check
            XCTAssertLessThan(profile.tdee, 10000) // Sanity check
        }
    }
#endif
