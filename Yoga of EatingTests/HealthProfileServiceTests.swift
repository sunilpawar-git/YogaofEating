#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class HealthProfileServiceTests: XCTestCase {
        var sut: HealthProfileService!
        var mockUserDefaults: UserDefaults!

        override func setUp() {
            super.setUp()
            self.mockUserDefaults = UserDefaults(suiteName: "TestDefaults")
            self.mockUserDefaults?.removePersistentDomain(forName: "TestDefaults")
            self.sut = HealthProfileService(userDefaults: self.mockUserDefaults!)
        }

        override func tearDown() {
            self.sut = nil
            self.mockUserDefaults?.removePersistentDomain(forName: "TestDefaults")
            self.mockUserDefaults = nil
            super.tearDown()
        }

        // MARK: - BMI Calculation Tests

        func test_calculateBMI_metricUnits_returnsCorrectValue() {
            // Given: Height 173cm, Weight 69kg (from screenshot)
            let height = 173.0
            let weight = 69.0

            // When
            let bmi = self.sut.calculateBMI(height: height, weight: weight, unitSystem: .metric)

            // Then: BMI = 69 / (1.73^2) = 23.05
            XCTAssertEqual(bmi, 23.05, accuracy: 0.1)
        }

        func test_calculateBMI_imperialUnits_returnsCorrectValue() {
            // Given: Height 68 inches (5'8"), Weight 152 lbs
            let height = 68.0
            let weight = 152.0

            // When
            let bmi = self.sut.calculateBMI(height: height, weight: weight, unitSystem: .imperial)

            // Then: BMI = (152 / (68^2)) * 703 = 23.1
            XCTAssertEqual(bmi, 23.1, accuracy: 0.1)
        }

        func test_calculateBMI_zeroHeight_returnsZero() {
            // Given: Invalid height
            let height = 0.0
            let weight = 70.0

            // When
            let bmi = self.sut.calculateBMI(height: height, weight: weight, unitSystem: .metric)

            // Then
            XCTAssertEqual(bmi, 0.0)
        }

        func test_calculateBMI_zeroWeight_returnsZero() {
            // Given: Invalid weight
            let height = 170.0
            let weight = 0.0

            // When
            let bmi = self.sut.calculateBMI(height: height, weight: weight, unitSystem: .metric)

            // Then
            XCTAssertEqual(bmi, 0.0)
        }

        func test_calculateBMI_negativeValues_returnsZero() {
            // Given: Negative values
            let height = -170.0
            let weight = 70.0

            // When
            let bmi = self.sut.calculateBMI(height: height, weight: weight, unitSystem: .metric)

            // Then
            XCTAssertEqual(bmi, 0.0)
        }

        // MARK: - BMI Category Tests

        func test_getBMICategory_underweight_returnsCorrectCategory() {
            // Given: BMI 17.5
            let bmi = 17.5

            // When
            let category = self.sut.getBMICategory(bmi: bmi)

            // Then
            XCTAssertEqual(category, .underweight)
        }

        func test_getBMICategory_normal_returnsCorrectCategory() {
            // Given: BMI 22.0
            let bmi = 22.0

            // When
            let category = self.sut.getBMICategory(bmi: bmi)

            // Then
            XCTAssertEqual(category, .normal)
        }

        func test_getBMICategory_overweight_returnsCorrectCategory() {
            // Given: BMI 27.0
            let bmi = 27.0

            // When
            let category = self.sut.getBMICategory(bmi: bmi)

            // Then
            XCTAssertEqual(category, .overweight)
        }

        func test_getBMICategory_obese_returnsCorrectCategory() {
            // Given: BMI 32.0
            let bmi = 32.0

            // When
            let category = self.sut.getBMICategory(bmi: bmi)

            // Then
            XCTAssertEqual(category, .obese)
        }

        func test_getBMICategory_borderlineNormalOverweight_returnsCorrectCategory() {
            // Given: BMI exactly 25.0
            let bmi = 25.0

            // When
            let category = self.sut.getBMICategory(bmi: bmi)

            // Then
            XCTAssertEqual(category, .overweight)
        }

        // MARK: - BMR Calculation Tests (Mifflin-St Jeor equation)

        func test_calculateBMR_maleMetric_returnsCorrectValue() {
            // Given: Male, 41 years, 173cm, 69kg (from screenshot)
            let weight = 69.0
            let height = 173.0
            let age = 41
            let gender = Gender.male

            // When
            let bmr = self.sut.calculateBMR(
                weight: weight,
                height: height,
                age: age,
                gender: gender,
                unitSystem: .metric
            )

            // Then: BMR = (10 * 69) + (6.25 * 173) - (5 * 41) + 5 = 1571.25
            XCTAssertEqual(bmr, 1571.25, accuracy: 1.0)
        }

        func test_calculateBMR_femaleMetric_returnsCorrectValue() {
            // Given: Female, 35 years, 165cm, 60kg
            let weight = 60.0
            let height = 165.0
            let age = 35
            let gender = Gender.female

            // When
            let bmr = self.sut.calculateBMR(
                weight: weight,
                height: height,
                age: age,
                gender: gender,
                unitSystem: .metric
            )

            // Then: BMR = (10 * 60) + (6.25 * 165) - (5 * 35) - 161 = 1294.25
            XCTAssertEqual(bmr, 1294.25, accuracy: 1.0)
        }

        func test_calculateBMR_unspecifiedGender_usesDefaultFormula() {
            // Given: Unspecified gender
            let weight = 70.0
            let height = 170.0
            let age = 30
            let gender = Gender.unspecified

            // When
            let bmr = self.sut.calculateBMR(
                weight: weight,
                height: height,
                age: age,
                gender: gender,
                unitSystem: .metric
            )

            // Then: Should use average (baseMetabolism - 78)
            let weightContribution = 10.0 * 70.0
            let heightContribution = 6.25 * 170.0
            let ageContribution = 5.0 * 30.0
            let expectedBase = weightContribution + heightContribution - ageContribution
            let expected = expectedBase - 78.0
            XCTAssertEqual(bmr, expected, accuracy: 1.0)
        }

        func test_calculateBMR_imperialUnits_convertsCorrectly() {
            // Given: Imperial units - 150 lbs, 66 inches, 30 years, male
            let weight = 150.0
            let height = 66.0
            let age = 30
            let gender = Gender.male

            // When
            let bmr = self.sut.calculateBMR(
                weight: weight,
                height: height,
                age: age,
                gender: gender,
                unitSystem: .imperial
            )

            // Then: Should convert and calculate
            // 150 lbs = 68.04 kg, 66 inches = 167.64 cm
            // BMR = (10 * 68.04) + (6.25 * 167.64) - (5 * 30) + 5
            XCTAssertGreaterThan(bmr, 1500)
            XCTAssertLessThan(bmr, 1700)
        }

        // MARK: - TDEE Calculation Tests

        func test_calculateTDEE_sedentaryActivity_returnsCorrectValue() {
            // Given: BMR of 1500
            let bmr = 1500.0

            // When
            let tdee = self.sut.calculateTDEE(bmr: bmr, activityLevel: 1.2)

            // Then: TDEE = 1500 * 1.2 = 1800
            XCTAssertEqual(tdee, 1800.0)
        }

        func test_calculateTDEE_defaultActivity_usesSedentary() {
            // Given: BMR of 1500, no activity level specified
            let bmr = 1500.0

            // When
            let tdee = self.sut.calculateTDEE(bmr: bmr)

            // Then: Should default to 1.2 multiplier
            XCTAssertEqual(tdee, 1800.0)
        }

        // MARK: - Sensitivity Multiplier Tests

        func test_getSensitivityMultiplier_healthyYoung_returnsBaseValue() {
            // Given: BMI 22 (normal), Age 30
            let bmi = 22.0
            let age = 30

            // When
            let multiplier = self.sut.getSensitivityMultiplier(bmi: bmi, age: age)

            // Then: Should return 1.0 (no adjustment)
            XCTAssertEqual(multiplier, 1.0)
        }

        func test_getSensitivityMultiplier_overweightMiddleAge_returnsIncreasedValue() {
            // Given: BMI 28 (overweight), Age 45
            let bmi = 28.0
            let age = 45

            // When
            let multiplier = self.sut.getSensitivityMultiplier(bmi: bmi, age: age)

            // Then: +0.15 (overweight) + 0.1 (age 40-49) = 1.25
            XCTAssertEqual(multiplier, 1.25)
        }

        func test_getSensitivityMultiplier_obeseOlder_returnsHighSensitivity() {
            // Given: BMI 32 (obese), Age 55
            let bmi = 32.0
            let age = 55

            // When
            let multiplier = self.sut.getSensitivityMultiplier(bmi: bmi, age: age)

            // Then: +0.3 (obese) + 0.15 (age 50-59) = 1.45
            XCTAssertEqual(multiplier, 1.45)
        }

        func test_getSensitivityMultiplier_extremelyObeseVeryOld_clampedToMax() {
            // Given: BMI 40 (extremely obese), Age 70
            let bmi = 40.0
            let age = 70

            // When
            let multiplier = self.sut.getSensitivityMultiplier(bmi: bmi, age: age)

            // Then: Would be 1.5 (0.3 + 0.2), clamped to 1.5
            XCTAssertEqual(multiplier, 1.5)
        }

        func test_getSensitivityMultiplier_underweight_clampedToMin() {
            // Given: BMI 17 (underweight), Age 20
            let bmi = 17.0
            let age = 20

            // When
            let multiplier = self.sut.getSensitivityMultiplier(bmi: bmi, age: age)

            // Then: Would be 1.0 (no penalty for underweight), min is 0.5
            XCTAssertEqual(multiplier, 1.0)
        }

        // MARK: - Health Risk Level Tests

        func test_getHealthRiskLevel_healthyProfile_returnsLow() {
            // Given: BMI 22 (normal), Age 30
            let bmi = 22.0
            let age = 30

            // When
            let riskLevel = self.sut.getHealthRiskLevel(bmi: bmi, age: age)

            // Then
            XCTAssertEqual(riskLevel, .low)
        }

        func test_getHealthRiskLevel_overweightYoung_returnsMedium() {
            // Given: BMI 27 (overweight), Age 35
            let bmi = 27.0
            let age = 35

            // When
            let riskLevel = self.sut.getHealthRiskLevel(bmi: bmi, age: age)

            // Then
            XCTAssertEqual(riskLevel, .medium)
        }

        func test_getHealthRiskLevel_overweightOlder_returnsHigh() {
            // Given: BMI 27 (overweight), Age 55
            let bmi = 27.0
            let age = 55

            // When
            let riskLevel = self.sut.getHealthRiskLevel(bmi: bmi, age: age)

            // Then: Overweight + age >= 50 = high risk
            XCTAssertEqual(riskLevel, .high)
        }

        func test_getHealthRiskLevel_obese_returnsHigh() {
            // Given: BMI 32 (obese), Age 30
            let bmi = 32.0
            let age = 30

            // When
            let riskLevel = self.sut.getHealthRiskLevel(bmi: bmi, age: age)

            // Then: Obese always high risk
            XCTAssertEqual(riskLevel, .high)
        }

        func test_getHealthRiskLevel_normalVeryOld_returnsMedium() {
            // Given: BMI 23 (normal), Age 70
            let bmi = 23.0
            let age = 70

            // When
            let riskLevel = self.sut.getHealthRiskLevel(bmi: bmi, age: age)

            // Then: Normal BMI but age >= 65 = medium risk
            XCTAssertEqual(riskLevel, .medium)
        }

        // MARK: - User Profile Generation Tests

        func test_getUserHealthProfile_validData_returnsProfile() {
            // Given: Valid user data in UserDefaults (matching screenshot)
            self.mockUserDefaults.set("173", forKey: "user_height")
            self.mockUserDefaults.set("69", forKey: "user_weight")
            self.mockUserDefaults.set("41", forKey: "user_age")
            self.mockUserDefaults.set(1, forKey: "user_gender") // Male
            self.mockUserDefaults.set(0, forKey: "unit_system") // Metric

            // When
            let profile = self.sut.getUserHealthProfile()

            // Then
            XCTAssertNotNil(profile)
            if let profile {
                XCTAssertEqual(profile.age, 41)
                XCTAssertEqual(profile.bmi, 23.05, accuracy: 0.1)
                XCTAssertEqual(profile.bmiCategory, .normal)
                XCTAssertEqual(profile.riskLevel, .low) // Normal BMI, age < 65
                XCTAssertEqual(profile.sensitivityMultiplier, 1.1) // Age 40-49 bonus
            }
        }

        func test_getUserHealthProfile_missingHeight_returnsNil() {
            // Given: Missing height
            self.mockUserDefaults.set("69", forKey: "user_weight")
            self.mockUserDefaults.set("41", forKey: "user_age")

            // When
            let profile = self.sut.getUserHealthProfile()

            // Then
            XCTAssertNil(profile)
        }

        func test_getUserHealthProfile_missingWeight_returnsNil() {
            // Given: Missing weight
            self.mockUserDefaults.set("173", forKey: "user_height")
            self.mockUserDefaults.set("41", forKey: "user_age")

            // When
            let profile = self.sut.getUserHealthProfile()

            // Then
            XCTAssertNil(profile)
        }

        func test_getUserHealthProfile_missingAge_returnsNil() {
            // Given: Missing age
            self.mockUserDefaults.set("173", forKey: "user_height")
            self.mockUserDefaults.set("69", forKey: "user_weight")

            // When
            let profile = self.sut.getUserHealthProfile()

            // Then
            XCTAssertNil(profile)
        }

        func test_getUserHealthProfile_invalidStringValues_returnsNil() {
            // Given: Invalid string values
            self.mockUserDefaults.set("abc", forKey: "user_height")
            self.mockUserDefaults.set("def", forKey: "user_weight")
            self.mockUserDefaults.set("ghi", forKey: "user_age")

            // When
            let profile = self.sut.getUserHealthProfile()

            // Then
            XCTAssertNil(profile)
        }

        func test_getUserHealthProfile_zeroValues_returnsNil() {
            // Given: Zero values (invalid)
            self.mockUserDefaults.set("0", forKey: "user_height")
            self.mockUserDefaults.set("0", forKey: "user_weight")
            self.mockUserDefaults.set("0", forKey: "user_age")

            // When
            let profile = self.sut.getUserHealthProfile()

            // Then
            XCTAssertNil(profile)
        }

        func test_getUserHealthProfile_imperialUnits_convertsCorrectly() {
            // Given: Imperial units
            self.mockUserDefaults.set("68", forKey: "user_height") // inches
            self.mockUserDefaults.set("152", forKey: "user_weight") // lbs
            self.mockUserDefaults.set("30", forKey: "user_age")
            self.mockUserDefaults.set(1, forKey: "user_gender")
            self.mockUserDefaults.set(1, forKey: "unit_system") // Imperial

            // When
            let profile = self.sut.getUserHealthProfile()

            // Then
            XCTAssertNotNil(profile)
            if let profile {
                XCTAssertEqual(profile.bmi, 23.1, accuracy: 0.1)
            }
        }
    }
#endif
