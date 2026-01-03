#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class PersonalizedMealScoringTests: XCTestCase {
        var sut: MealLogicService!
        var mockHealthProfileService: MockHealthProfileService!

        override func setUp() {
            super.setUp()
            self.mockHealthProfileService = MockHealthProfileService()
            self.sut = MealLogicService(healthProfileService: self.mockHealthProfileService)
        }

        override func tearDown() {
            self.sut = nil
            self.mockHealthProfileService = nil
            super.tearDown()
        }

        // MARK: - Baseline Scoring (No Personalization)

        func test_calculateHealthScore_healthyMeal_returnsHighScore() {
            // Given: Healthy meal
            let description = "Green salad with avocado"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Should return high score
            XCTAssertGreaterThanOrEqual(score, 0.6)
        }

        func test_calculateHealthScore_unhealthyMeal_returnsLowScore() {
            // Given: Unhealthy meal
            let description = "Double cheeseburger and fries"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Should return low score
            XCTAssertLessThanOrEqual(score, 0.4)
        }

        func test_calculateHealthScore_neutralMeal_returnsNeutralScore() {
            // Given: Neutral meal
            let description = "Toast"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Should return neutral score
            XCTAssertEqual(score, 0.5, accuracy: 0.1)
        }

        // MARK: - Personalized Scoring Tests

        func test_calculateHealthScore_unhealthyMealForAtRiskUser_returnsLowerScore() {
            // Given: High-risk user (BMI 32, age 55) eating unhealthy food
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 55,
                bmi: 32.0,
                bmiCategory: .obese,
                bmr: 1650.0,
                tdee: 1980.0,
                riskLevel: .high,
                sensitivityMultiplier: 1.45
            )
            let description = "Pizza and coke"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Score should be penalized more than base calculation
            // Base score would be ~0.3, with 1.45x sensitivity it should be lower
            XCTAssertLessThan(score, 0.3)
        }

        func test_calculateHealthScore_healthyMealForAtRiskUser_returnsHigherScore() {
            // Given: High-risk user eating healthy food
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 55,
                bmi: 32.0,
                bmiCategory: .obese,
                bmr: 1650.0,
                tdee: 1980.0,
                riskLevel: .high,
                sensitivityMultiplier: 1.45
            )
            let description = "Green salad with vegetables"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Should get bonus points for healthy choice
            XCTAssertGreaterThan(score, 0.7)
        }

        func test_calculateHealthScore_missingUserProfile_usesDefaultScoring() {
            // Given: No user profile available
            self.mockHealthProfileService.mockProfile = nil
            let description = "Salad"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Should fall back to base scoring (0.5 + 0.1 = 0.6)
            XCTAssertEqual(score, 0.6, accuracy: 0.05)
        }

        // MARK: - Sensitivity Multiplier Application Tests

        func test_applySensitivity_lowRiskUser_minimalAdjustment() {
            // Given: Low-risk user (BMI 22, age 30)
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 30,
                bmi: 22.0,
                bmiCategory: .normal,
                bmr: 1500.0,
                tdee: 1800.0,
                riskLevel: .low,
                sensitivityMultiplier: 1.0
            )
            let description = "Burger"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Standard penalty (base would be ~0.4)
            XCTAssertEqual(score, 0.4, accuracy: 0.1)
        }

        func test_applySensitivity_highRiskUser_significantAdjustment() {
            // Given: High-risk user (obese + older)
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 60,
                bmi: 35.0,
                bmiCategory: .obese,
                bmr: 1700.0,
                tdee: 2040.0,
                riskLevel: .high,
                sensitivityMultiplier: 1.5
            )
            let description = "Fried chicken"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Significant penalty due to high sensitivity
            XCTAssertLessThan(score, 0.25)
        }

        // MARK: - Contextual Adjustments Tests

        func test_contextualAdjustment_friedFoodForHighRisk_significantlyWorse() {
            // Given: High-risk user eating fried food
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 55,
                bmi: 32.0,
                bmiCategory: .obese,
                bmr: 1650.0,
                tdee: 1980.0,
                riskLevel: .high,
                sensitivityMultiplier: 1.45
            )
            let description = "Deep-fried samosa"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Should have contextual penalty for fried food
            XCTAssertLessThan(score, 0.3)
        }

        func test_contextualAdjustment_friedFoodForLowRisk_moderatePenalty() {
            // Given: Low-risk user eating fried food
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 25,
                bmi: 21.0,
                bmiCategory: .normal,
                bmr: 1400.0,
                tdee: 1680.0,
                riskLevel: .low,
                sensitivityMultiplier: 1.0
            )
            let description = "Deep-fried samosa"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Standard fried food penalty, less severe than high-risk
            XCTAssertGreaterThan(score, 0.3)
        }

        func test_contextualAdjustment_vegetablesForHighRisk_bonusPoints() {
            // Given: High-risk user eating vegetables
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 55,
                bmi: 32.0,
                bmiCategory: .obese,
                bmr: 1650.0,
                tdee: 1980.0,
                riskLevel: .high,
                sensitivityMultiplier: 1.45
            )
            let description = "Green vegetable salad"

            // When
            let score = self.sut.calculateHealthScore(for: description)

            // Then: Should get bonus for healthy choice
            XCTAssertGreaterThan(score, 0.75)
        }

        // MARK: - Multiple Items Scoring Tests

        func test_calculateHealthScore_multipleItems_averagesCorrectly() {
            // Given: Low-risk user, mixed meal
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 30,
                bmi: 22.0,
                bmiCategory: .normal,
                bmr: 1500.0,
                tdee: 1800.0,
                riskLevel: .low,
                sensitivityMultiplier: 1.0
            )
            let items = ["Salad", "Pizza"]

            // When
            let score = self.sut.calculateHealthScore(for: items)

            // Then: Should average the scores
            // Salad ~0.6, Pizza ~0.4, average = 0.5
            XCTAssertEqual(score, 0.5, accuracy: 0.1)
        }

        func test_calculateHealthScore_emptyList_returnsNeutral() {
            // Given: Empty meal list
            let items: [String] = []

            // When
            let score = self.sut.calculateHealthScore(for: items)

            // Then: Should return neutral score
            XCTAssertEqual(score, 0.5)
        }

        // MARK: - Smiley State Tests with Sensitivity

        func test_calculateNextState_healthyMealForAtRiskUser_largerShrink() {
            // Given: High-risk user, healthy meal
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 55,
                bmi: 32.0,
                bmiCategory: .obese,
                bmr: 1650.0,
                tdee: 1980.0,
                riskLevel: .high,
                sensitivityMultiplier: 1.45
            )
            let currentState = SmileyState(scale: 1.5, mood: .neutral)
            let healthScore = 0.8 // Very healthy meal

            // When
            let nextState = self.sut.calculateNextState(from: currentState, healthScore: healthScore)

            // Then: Should shrink more than normal due to sensitivity
            XCTAssertLessThan(nextState.scale, currentState.scale)
            XCTAssertEqual(nextState.mood, .serene)
        }

        func test_calculateNextState_unhealthyMealForAtRiskUser_largerBloat() {
            // Given: High-risk user, unhealthy meal
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 55,
                bmi: 32.0,
                bmiCategory: .obese,
                bmr: 1650.0,
                tdee: 1980.0,
                riskLevel: .high,
                sensitivityMultiplier: 1.45
            )
            let currentState = SmileyState(scale: 1.0, mood: .neutral)
            let healthScore = 0.2 // Very unhealthy meal

            // When
            let nextState = self.sut.calculateNextState(from: currentState, healthScore: healthScore)

            // Then: Should bloat more than normal due to sensitivity
            XCTAssertGreaterThan(nextState.scale, currentState.scale)
            XCTAssertEqual(nextState.mood, .overwhelmed)
        }

        func test_calculateNextState_healthyUserNeutralMeal_standardBehavior() {
            // Given: Low-risk user, neutral meal
            self.mockHealthProfileService.mockProfile = UserHealthProfile(
                age: 25,
                bmi: 21.0,
                bmiCategory: .normal,
                bmr: 1400.0,
                tdee: 1680.0,
                riskLevel: .low,
                sensitivityMultiplier: 1.0
            )
            let currentState = SmileyState(scale: 1.3, mood: .neutral)
            let healthScore = 0.5 // Neutral meal

            // When
            let nextState = self.sut.calculateNextState(from: currentState, healthScore: healthScore)

            // Then: Should drift toward 1.0
            XCTAssertLessThan(nextState.scale, currentState.scale)
            XCTAssertEqual(nextState.mood, .neutral)
        }
    }

    // MARK: - Mock Health Profile Service

    class MockHealthProfileService: HealthProfileServiceProtocol {
        var mockProfile: UserHealthProfile?

        func calculateBMI(height _: Double, weight _: Double, unitSystem _: UnitSystem) -> Double {
            self.mockProfile?.bmi ?? 0.0
        }

        func getBMICategory(bmi _: Double) -> BMICategory {
            self.mockProfile?.bmiCategory ?? .normal
        }

        func calculateBMR(
            weight _: Double,
            height _: Double,
            age _: Int,
            gender _: Gender,
            unitSystem _: UnitSystem
        ) -> Double {
            self.mockProfile?.bmr ?? 0.0
        }

        func calculateTDEE(bmr _: Double, activityLevel _: Double) -> Double {
            self.mockProfile?.tdee ?? 0.0
        }

        func getSensitivityMultiplier(bmi _: Double, age _: Int) -> Double {
            self.mockProfile?.sensitivityMultiplier ?? 1.0
        }

        func getHealthRiskLevel(bmi _: Double, age _: Int) -> HealthRiskLevel {
            self.mockProfile?.riskLevel ?? .low
        }

        func getUserHealthProfile() -> UserHealthProfile? {
            self.mockProfile
        }
    }
#endif
