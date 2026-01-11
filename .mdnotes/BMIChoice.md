 Personalized Meal Feedback Implementation Plan

 Overview

 Add personalized, mindful visual feedback to meal cards based on user's BMI and age. Users with higher health risk (higher BMI + older age) receive more sensitive feedback about food choices through subtle visual indicators - without
 showing calorie counts or being overwhelming.

 User Requirements

 - Real-time feedback with two-phase approach (instant local + refined AI)
 - Visual indicators on meal cards (border color/tint strength)
 - BMI + age-based sensitivity - calculate ideal calorie needs internally, don't display numbers
 - Balanced approach - celebrate good choices, gently discourage poor ones
 - Mindful, not overwhelming - subtle nudges, no calorie counting UI

 Current Architecture Insights

 - Personal data stored in @AppStorage (age, height, weight, gender) but NOT used in calculations
 - Health scoring: 0.0-1.0 scale (unhealthy to healthy)
 - Two-phase feedback: local keyword heuristic → AI analysis via Gemini
 - Meal cards in JournalBlockView.swift with glassmorphic design
 - Smiley state updates based on health scores
 - MealLogicService.swift handles health calculations

 ---
 Development Principles

 Test-Driven Development (TDD)

 Each phase follows strict TDD:
 1. Write tests first - Define expected behavior before implementation
 2. Implement minimum code - Make tests pass with simplest solution
 3. Refactor - Clean up code while keeping tests green
 4. Build verification - Ensure Xcode build succeeds with zero warnings
 5. Tech debt cleanup - Remove any shortcuts or temporary code
 6. All tests pass - 100% pass rate before moving to next phase

 Phase Boundaries

 - Each phase is independently buildable and testable
 - No phase depends on incomplete work from future phases
 - Can deploy/demo after any phase completion

 ---
 Implementation Phases

 Phase 1: Foundation - Health Profile Models & Service

 Goal: Create health calculation infrastructure with full test coverage

 Step 1.1: Write Tests (TDD)

 Create: Yoga of EatingTests/HealthProfileServiceTests.swift

 Test cases to write:
 class HealthProfileServiceTests: XCTestCase {
     // BMI Calculation Tests
     func testCalculateBMI_MetricUnits_ReturnsCorrectValue()
     func testCalculateBMI_ImperialUnits_ReturnsCorrectValue()
     func testCalculateBMI_ZeroHeight_ReturnsZero()
     func testCalculateBMI_InvalidValues_HandlesGracefully()

     // BMI Category Tests
     func testGetBMICategory_Underweight_ReturnsCorrectCategory()
     func testGetBMICategory_Normal_ReturnsCorrectCategory()
     func testGetBMICategory_Overweight_ReturnsCorrectCategory()
     func testGetBMICategory_Obese_ReturnsCorrectCategory()

     // BMR Calculation Tests (Mifflin-St Jeor equation)
     func testCalculateBMR_MaleMetric_ReturnsCorrectValue()
     func testCalculateBMR_FemaleMetric_ReturnsCorrectValue()
     func testCalculateBMR_UnspecifiedGender_UsesDefaultFormula()

     // TDEE Calculation Tests
     func testCalculateTDEE_SedentaryActivity_ReturnsCorrectValue()

     // Sensitivity Multiplier Tests
     func testGetSensitivityMultiplier_HealthyYoung_ReturnsBaseValue()
     func testGetSensitivityMultiplier_OverweightMiddleAge_ReturnsIncreasedValue()
     func testGetSensitivityMultiplier_ObeseOlder_ReturnsMaxSensitivity()
     func testGetSensitivityMultiplier_ClampedToRange()

     // Risk Level Tests
     func testGetHealthRiskLevel_HealthyProfile_ReturnsLow()
     func testGetHealthRiskLevel_ModerateProfile_ReturnsMedium()
     func testGetHealthRiskLevel_AtRiskProfile_ReturnsHigh()
 }

 Expected: Tests fail (red) - models and service don't exist yet

 Step 1.2: Create Data Models

 Create: Models/HealthProfile.swift

 import Foundation

 enum BMICategory: String, Codable {
     case underweight = "Underweight"
     case normal = "Normal"
     case overweight = "Overweight"
     case obese = "Obese"

     static func from(bmi: Double) -> BMICategory {
         switch bmi {
         case ..<18.5: return .underweight
         case 18.5..<25: return .normal
         case 25..<30: return .overweight
         default: return .obese
         }
     }
 }

 enum HealthRiskLevel: String, Codable {
     case low = "Low"
     case medium = "Medium"
     case high = "High"
 }

 enum Gender: Int, Codable {
     case unspecified = 0
     case male = 1
     case female = 2
     case other = 3
 }

 enum UnitSystem: Int, Codable {
     case metric = 0
     case imperial = 1
 }

 struct UserHealthProfile: Codable {
     let age: Int
     let bmi: Double
     let bmiCategory: BMICategory
     let bmr: Double
     let tdee: Double
     let riskLevel: HealthRiskLevel
     let sensitivityMultiplier: Double
 }

 Step 1.3: Implement Service (Minimum to Pass Tests)

 Create: Services/HealthProfileService.swift

 import Foundation

 protocol HealthProfileServiceProtocol {
     func calculateBMI(height: Double, weight: Double, unitSystem: UnitSystem) -> Double
     func getBMICategory(bmi: Double) -> BMICategory
     func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender, unitSystem: UnitSystem) -> Double
     func calculateTDEE(bmr: Double, activityLevel: Double) -> Double
     func getSensitivityMultiplier(bmi: Double, age: Int) -> Double
     func getHealthRiskLevel(bmi: Double, age: Int) -> HealthRiskLevel
     func getUserHealthProfile() -> UserHealthProfile?
 }

 class HealthProfileService: HealthProfileServiceProtocol {
     // UserDefaults keys (matching existing SettingsView)
     private let heightKey = "user_height"
     private let weightKey = "user_weight"
     private let ageKey = "user_age"
     private let genderKey = "user_gender"
     private let unitSystemKey = "unit_system"

     private let userDefaults: UserDefaults

     init(userDefaults: UserDefaults = .standard) {
         self.userDefaults = userDefaults
     }

     // MARK: - BMI Calculation

     func calculateBMI(height: Double, weight: Double, unitSystem: UnitSystem) -> Double {
         guard height > 0, weight > 0 else { return 0 }

         switch unitSystem {
         case .metric:
             // BMI = weight (kg) / (height (m))^2
             let heightInMeters = height / 100.0
             return weight / (heightInMeters * heightInMeters)

         case .imperial:
             // BMI = (weight (lbs) / (height (inches))^2) * 703
             return (weight / (height * height)) * 703
         }
     }

     // MARK: - BMI Category

     func getBMICategory(bmi: Double) -> BMICategory {
         return BMICategory.from(bmi: bmi)
     }

     // MARK: - BMR Calculation (Mifflin-St Jeor Equation)

     func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender, unitSystem: UnitSystem) -> Double {
         var weightKg = weight
         var heightCm = height

         // Convert to metric if needed
         if unitSystem == .imperial {
             weightKg = weight * 0.453592  // lbs to kg
             heightCm = height * 2.54      // inches to cm
         }

         // Base calculation: 10 * weight + 6.25 * height - 5 * age
         let baseMetabolism = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age))

         // Adjust for gender
         switch gender {
         case .male:
             return baseMetabolism + 5
         case .female:
             return baseMetabolism - 161
         case .unspecified, .other:
             // Use average of male/female
             return baseMetabolism - 78
         }
     }

     // MARK: - TDEE Calculation

     func calculateTDEE(bmr: Double, activityLevel: Double = 1.2) -> Double {
         // Default to sedentary (1.2) activity multiplier
         // Future: Could make this configurable
         return bmr * activityLevel
     }

     // MARK: - Sensitivity Multiplier

     func getSensitivityMultiplier(bmi: Double, age: Int) -> Double {
         var sensitivity: Double = 1.0

         // BMI adjustments
         if bmi >= 30 {
             sensitivity += 0.3  // Obese
         } else if bmi >= 25 {
             sensitivity += 0.15  // Overweight
         }

         // Age adjustments
         if age >= 60 {
             sensitivity += 0.2
         } else if age >= 50 {
             sensitivity += 0.15
         } else if age >= 40 {
             sensitivity += 0.1
         }

         // Clamp to reasonable range
         return min(max(sensitivity, 0.5), 1.5)
     }

     // MARK: - Health Risk Level

     func getHealthRiskLevel(bmi: Double, age: Int) -> HealthRiskLevel {
         let bmiCategory = getBMICategory(bmi: bmi)

         // High risk: Obese OR (overweight + older)
         if bmiCategory == .obese || (bmiCategory == .overweight && age >= 50) {
             return .high
         }

         // Medium risk: Overweight OR (normal + very old)
         if bmiCategory == .overweight || (bmiCategory == .normal && age >= 65) {
             return .medium
         }

         // Low risk: Normal or underweight
         return .low
     }

     // MARK: - User Profile Generation

     func getUserHealthProfile() -> UserHealthProfile? {
         // Read from UserDefaults
         guard let heightString = userDefaults.string(forKey: heightKey),
               let weightString = userDefaults.string(forKey: weightKey),
               let ageString = userDefaults.string(forKey: ageKey),
               let height = Double(heightString),
               let weight = Double(weightString),
               let age = Int(ageString),
               height > 0, weight > 0, age > 0 else {
             return nil
         }

         let genderRaw = userDefaults.integer(forKey: genderKey)
         let unitSystemRaw = userDefaults.integer(forKey: unitSystemKey)

         let gender = Gender(rawValue: genderRaw) ?? .unspecified
         let unitSystem = UnitSystem(rawValue: unitSystemRaw) ?? .metric

         // Calculate metrics
         let bmi = calculateBMI(height: height, weight: weight, unitSystem: unitSystem)
         let bmiCategory = getBMICategory(bmi: bmi)
         let bmr = calculateBMR(weight: weight, height: height, age: age, gender: gender, unitSystem: unitSystem)
         let tdee = calculateTDEE(bmr: bmr)
         let riskLevel = getHealthRiskLevel(bmi: bmi, age: age)
         let sensitivity = getSensitivityMultiplier(bmi: bmi, age: age)

         return UserHealthProfile(
             age: age,
             bmi: bmi,
             bmiCategory: bmiCategory,
             bmr: bmr,
             tdee: tdee,
             riskLevel: riskLevel,
             sensitivityMultiplier: sensitivity
         )
     }
 }

 Step 1.4: Refactor & Verify

 - Run tests → All should pass (green)
 - Run Xcode build → Must succeed with zero warnings
 - Code review for clarity and efficiency
 - Add inline documentation for formulas

 Step 1.5: Tech Debt Cleanup

 - Ensure all magic numbers have constants
 - Add TODO comments for future activity level customization
 - Verify protocol conformance is complete
 - Check for force unwraps or unsafe operations
 - Ensure error handling is graceful

 Step 1.6: Phase Completion Checklist

 - All 20+ tests pass
 - Xcode build succeeds (Cmd+B)
 - Zero compiler warnings
 - Code coverage > 90% for new files
 - No force unwraps or unsafe code
 - Documentation complete

 Deliverable: Fully tested health profile service ready for integration

 ---
 Phase 2: Integration - Inject Health Profile into Meal Logic

 Goal: Integrate HealthProfileService into existing MealLogicService with personalized scoring

 Step 2.1: Write Tests (TDD)

 Create: Yoga of EatingTests/PersonalizedMealScoringTests.swift

 Test cases:
 class PersonalizedMealScoringTests: XCTestCase {
     var healthProfileService: MockHealthProfileService!
     var mealLogicService: MealLogicService!

     // Baseline scoring (no personalization)
     func testCalculateHealthScore_HealthyMeal_ReturnsHighScore()
     func testCalculateHealthScore_UnhealthyMeal_ReturnsLowScore()

     // Personalized scoring
     func testCalculateHealthScore_UnhealthyMealForAtRiskUser_ReturnsLowerScore()
     func testCalculateHealthScore_HealthyMealForAtRiskUser_ReturnsHigherScore()
     func testCalculateHealthScore_MissingUserProfile_UsesDefaultScoring()

     // Sensitivity multiplier application
     func testApplySensitivity_LowRiskUser_MinimalAdjustment()
     func testApplySensitivity_HighRiskUser_SignificantAdjustment()

     // Contextual adjustments
     func testContextualAdjustment_HeavyBreakfast_BetterForHighBMI()
     func testContextualAdjustment_LateNightSnack_WorseForHighBMI()
     func testContextualAdjustment_FriedFood_SignificantlyWorseForObese()
 }

 Step 2.2: Modify MealLogicService

 Modify: Logic/MealLogicService.swift

 Changes:
 1. Add HealthProfileService dependency injection
 2. Enhance calculateHealthScore() to use sensitivity multiplier
 3. Add contextual scoring adjustments

 // Add to MealLogicService
 class MealLogicService: MealLogicProvider {
     private let healthProfileService: HealthProfileServiceProtocol

     init(healthProfileService: HealthProfileServiceProtocol = HealthProfileService()) {
         self.healthProfileService = healthProfileService
     }

     func calculateHealthScore(for description: String, mealType: MealType? = nil) -> Double {
         // 1. Base keyword scoring (existing)
         let baseScore = keywordBasedScore(description)

         // 2. Get user profile
         guard let profile = healthProfileService.getUserHealthProfile() else {
             return baseScore // No personalization if profile unavailable
         }

         // 3. Apply sensitivity multiplier
         let adjustedScore = applySensitivityMultiplier(
             to: baseScore,
             multiplier: profile.sensitivityMultiplier
         )

         // 4. Apply contextual adjustments
         let finalScore = applyContextualAdjustments(
             score: adjustedScore,
             description: description,
             mealType: mealType,
             riskLevel: profile.riskLevel
         )

         return finalScore.clamped(to: 0.0...1.0)
     }

     private func applySensitivityMultiplier(to score: Double, multiplier: Double) -> Double {
         // For unhealthy scores (<0.5), apply penalty
         // For healthy scores (>0.5), apply bonus
         let deviation = score - 0.5
         let adjustedDeviation = deviation / multiplier
         return 0.5 + adjustedDeviation
     }

     private func applyContextualAdjustments(
         score: Double,
         description: String,
         mealType: MealType?,
         riskLevel: HealthRiskLevel
     ) -> Double {
         var adjustedScore = score
         let lowerDescription = description.lowercased()

         // Context 1: Late-night eating
         if mealType == .snacks, Calendar.current.component(.hour, from: Date()) >= 21 {
             if riskLevel == .high {
                 adjustedScore -= 0.1  // Penalty for at-risk users
             }
         }

         // Context 2: Fried foods for at-risk users
         let friedKeywords = ["fried", "deep-fried", "samosa", "pakora", "vada"]
         if friedKeywords.contains(where: lowerDescription.contains) {
             if riskLevel == .high {
                 adjustedScore -= 0.15
             } else if riskLevel == .medium {
                 adjustedScore -= 0.08
             }
         }

         // Context 3: Boost vegetables/fruits for at-risk users
         let healthyKeywords = ["salad", "vegetable", "fruit", "green"]
         if healthyKeywords.contains(where: lowerDescription.contains) {
             if riskLevel == .high {
                 adjustedScore += 0.1
             } else if riskLevel == .medium {
                 adjustedScore += 0.05
             }
         }

         return adjustedScore
     }
 }

 Step 2.3: Update MainViewModel Dependency

 Modify: ViewModels/MainViewModel.swift

 Inject HealthProfileService into MealLogicService:
 @MainActor
 class MainViewModel: ObservableObject {
     let healthProfileService: HealthProfileServiceProtocol
     let logicService: MealLogicProvider

     init(
         healthProfileService: HealthProfileServiceProtocol = HealthProfileService(),
         logicService: MealLogicProvider? = nil,
         persistenceService: PersistenceServiceProtocol = PersistenceService(),
         historicalService: HistoricalDataServiceProtocol = HistoricalDataService()
     ) {
         self.healthProfileService = healthProfileService
         self.logicService = logicService ?? MealLogicService(healthProfileService: healthProfileService)
         // ... rest of init
     }
 }

 Step 2.4: Refactor & Verify

 - Run tests → All should pass
 - Run Xcode build → Must succeed
 - Verify existing functionality not broken (regression testing)

 Step 2.5: Tech Debt Cleanup

 - Extract magic numbers to constants (e.g., 0.1, 0.15 adjustments)
 - Add documentation for scoring formulas
 - Ensure mock services for testing
 - Remove any hardcoded values

 Step 2.6: Phase Completion Checklist

 - All tests pass (new + existing)
 - Xcode build succeeds
 - Zero warnings
 - Existing meal scoring still works
 - Personalized scoring only applies when profile available

 Deliverable: MealLogicService now personalizes scoring based on user health profile

 ---
 Phase 3: Visual Feedback - Meal Card Border Indicators

 Goal: Add visual feedback to meal cards based on personalized health scores

 Step 3.1: Write Tests (TDD)

 Create: Yoga of EatingTests/MealCardVisualFeedbackTests.swift

 UI tests:
 class MealCardVisualFeedbackTests: XCTestCase {
     // Border color tests
     func testBorderColor_HighScore_ReturnsGreen()
     func testBorderColor_LowScore_ReturnsOrange()
     func testBorderColor_MediumScore_ReturnsMealTypeColor()

     // Border width tests
     func testBorderWidth_HighScore_ReturnsThick()
     func testBorderWidth_NonHighScore_ReturnsStandard()

     // Tint opacity tests
     func testTintOpacity_HighScore_ReturnsGreenTint()
     func testTintOpacity_LowScore_ReturnsOrangeTint()
     func testTintOpacity_MediumScore_ReturnsNoTint()

     // Animation tests
     func testScoreUpdate_TriggersAnimation()
 }

 Step 3.2: Create Helpers

 Create: Extensions/Color+MealFeedback.swift

 import SwiftUI

 extension Color {
     static let mealFeedbackPositive = Color.green
     static let mealFeedbackWarning = Color.orange
 }

 struct MealCardFeedback {
     let score: Double
     let mealTypeColor: Color

     var borderColor: Color {
         if score > 0.65 {
             return .mealFeedbackPositive
         } else if score < 0.35 {
             return .mealFeedbackWarning
         } else {
             return mealTypeColor
         }
     }

     var borderWidth: CGFloat {
         score > 0.65 ? 3.0 : 1.0
     }

     var tintOpacity: Double {
         if score > 0.65 {
             return 0.1  // Green tint
         } else if score < 0.35 {
             return 0.08  // Orange tint
         }
         return 0.0
     }
 }

 Step 3.3: Modify JournalBlockView

 Modify: Views/JournalBlockView.swift

 Add visual feedback:
 struct JournalBlockView: View {
     @ObservedObject var viewModel: JournalBlockViewModel
     let meal: Meal

     private var feedback: MealCardFeedback {
         MealCardFeedback(
             score: meal.healthScore,
             mealTypeColor: mealTypeColor(for: meal.mealType)
         )
     }

     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             // ... existing content
         }
         .padding()
         .frame(maxWidth: 380)
         .background(.ultraThinMaterial)
         .overlay(
             RoundedRectangle(cornerRadius: 20)
                 .fill(feedback.borderColor.opacity(feedback.tintOpacity))
         )
         .overlay(
             RoundedRectangle(cornerRadius: 20)
                 .strokeBorder(feedback.borderColor, lineWidth: feedback.borderWidth)
         )
         .clipShape(RoundedRectangle(cornerRadius: 20))
         .animation(.easeInOut(duration: 0.5), value: meal.healthScore)
         // ... existing modifiers
     }
 }

 Step 3.4: Refactor & Verify

 - Run UI tests
 - Manual testing in simulator/device
 - Test score updates trigger smooth animations
 - Verify glassmorphic design preserved

 Step 3.5: Tech Debt Cleanup

 - Extract threshold values (0.65, 0.35) to constants
 - Ensure accessibility labels updated
 - Test in light/dark mode
 - Test on different screen sizes

 Step 3.6: Phase Completion Checklist

 - All tests pass
 - Visual feedback works correctly
 - Animations smooth (no jank)
 - Build succeeds
 - No visual regressions

 Deliverable: Meal cards visually indicate health score quality with borders and tints

 ---
 Phase 4: Enhanced Smiley Sensitivity

 Goal: Make smiley react more strongly for at-risk users

 Step 4.1: Write Tests

 Extend: Yoga of EatingTests/SmileyStateTests.swift (if exists) or create new

 // Sensitivity tests
 func testUpdateSmiley_HealthyUser_StandardReaction()
 func testUpdateSmiley_AtRiskUser_StrongerReaction()
 func testUpdateSmiley_PoorMealForAtRiskUser_LargerBloat()
 func testUpdateSmiley_GoodMealForAtRiskUser_LargerShrink()

 Step 4.2: Modify Smiley Update Logic

 Modify: Logic/MealLogicService.swift

 Enhance smiley state calculation:
 func updateSmileyState(basedOn meals: [Meal]) -> SmileyState {
     // Get current user profile
     let profile = healthProfileService.getUserHealthProfile()
     let sensitivity = profile?.sensitivityMultiplier ?? 1.0

     // Calculate base smiley changes (existing logic)
     var newState = calculateBaseSmileyState(from: meals)

     // Apply sensitivity to scale changes
     let scaleDeviation = newState.scale - 1.0
     let adjustedScaleDeviation = scaleDeviation * sensitivity
     newState.scale = 1.0 + adjustedScaleDeviation
     newState.scale = newState.scale.clamped(to: 0.1...10.0)

     return newState
 }

 Step 4.3: Refactor & Verify

 - Run tests
 - Build succeeds
 - Smiley still animates smoothly

 Step 4.4: Tech Debt Cleanup

 - Document sensitivity formula
 - Ensure no breaking changes to existing smiley logic

 Step 4.5: Phase Completion Checklist

 - All tests pass
 - Smiley sensitivity works
 - Build succeeds

 Deliverable: Smiley provides stronger feedback for at-risk users

 ---
 Phase 5: Enhanced Haptic Feedback

 Goal: Vary haptic intensity based on user risk and meal score

 Step 5.1: Write Tests

 Create: Yoga of EatingTests/HapticFeedbackTests.swift

 func testHapticIntensity_GoodMeal_SoftHaptic()
 func testHapticIntensity_PoorMealLowRisk_LightHaptic()
 func testHapticIntensity_PoorMealHighRisk_MediumHaptic()
 func testHapticDisabled_NoHaptic()

 Step 5.2: Modify or Create SensoryService

 Modify/Create: Logic/SensoryService.swift

 class SensoryService {
     static let shared = SensoryService()

     @AppStorage("haptics_enabled") private var areHapticsEnabled: Bool = true

     func playMealFeedbackHaptic(for score: Double, riskLevel: HealthRiskLevel) {
         guard areHapticsEnabled else { return }

         let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle

         if score > 0.65 {
             impactStyle = .soft
         } else if score < 0.35 && riskLevel == .high {
             impactStyle = .medium
         } else {
             impactStyle = .light
         }

         let generator = UIImpactFeedbackGenerator(style: impactStyle)
         generator.prepare()
         generator.impactOccurred()
     }
 }

 Step 5.3: Integrate into Meal Updates

 Modify: ViewModels/MainViewModel.swift

 func updateMeal(_ meal: Meal, mealType: MealType, items: [String]) {
     // ... existing update logic

     // Trigger haptic feedback
     let profile = healthProfileService.getUserHealthProfile()
     SensoryService.shared.playMealFeedbackHaptic(
         for: updatedMeal.healthScore,
         riskLevel: profile?.riskLevel ?? .low
     )
 }

 Step 5.4-5.6: Refactor, Cleanup, Verify

 - Run tests
 - Manual testing for haptics
 - Build succeeds

 Deliverable: Haptic feedback intensity varies by user profile

 ---
 Phase 6: AI Prompt Enhancement (Optional - Server-Side)

 Goal: Send user health profile to Gemini for context-aware analysis

 Step 6.1: Write Tests

 Create: Yoga of EatingTests/AIServicePersonalizationTests.swift

 func testBuildRequest_IncludesUserProfile()
 func testBuildRequest_NoProfile_ExcludesProfile()
 func testAIAnalysis_PersonalizedResponse()

 Step 6.2: Modify AILogicService

 Modify: Logic/AILogicService.swift

 Update request structure:
 struct MealAnalysisRequest: Codable {
     let mealDescription: String
     let mealType: String
     let userProfile: UserHealthProfile?
 }

 func analyzeMeal(_ description: String, mealType: MealType) async -> MealAnalysisResult {
     let profile = healthProfileService.getUserHealthProfile()

     let request = MealAnalysisRequest(
         mealDescription: description,
         mealType: mealType.rawValue,
         userProfile: profile
     )

     // Send to Firebase Cloud Function
     // ...
 }

 Step 6.3: Server-Side Update (Firebase Cloud Function)

 Note: Update Gemini prompt to consider user profile:

 System prompt enhancement:
 "When userProfile is provided, analyze the meal considering:
 - User's BMI category: {bmiCategory}
 - Age: {age}
 - Estimated daily energy needs: {tdee} calories
 - Risk level: {riskLevel}

 Be more strict for high-risk users when scoring unhealthy foods.
 Celebrate healthy choices more for high-risk users."

 Step 6.4-6.6: Refactor, Cleanup, Verify

 - Test with/without profile
 - Ensure backward compatibility
 - Build succeeds

 Deliverable: AI analysis considers user health context

 ---
 Phase 7: Settings & Privacy Controls

 Goal: Add user controls for personalized feedback and optional health insights

 Step 7.1: Write Tests

 Create: Yoga of EatingTests/SettingsHealthInsightsTests.swift

 func testPersonalizedFeedbackToggle_DefaultEnabled()
 func testShowHealthInsights_DefaultDisabled()
 func testHealthInsightsDisplay_WhenEnabled()
 func testHealthMetrics_Calculations()

 Step 7.2: Modify SettingsView

 Modify: Views/SettingsView.swift

 Add toggles and optional health insights:
 @AppStorage("personalized_feedback_enabled") private var isPersonalizedFeedbackEnabled: Bool = true
 @AppStorage("show_health_insights") private var showHealthInsights: Bool = false

 var body: some View {
     Form {
         // ... existing sections

         Section("Personalization") {
             Toggle("Personalized Feedback", isOn: $isPersonalizedFeedbackEnabled)
                 .tint(.blue)

             Text("Get meal suggestions based on your health profile")
                 .font(.caption)
                 .foregroundStyle(.secondary)
         }

         if showHealthInsights, let profile = healthProfileService.getUserHealthProfile() {
             Section("Health Insights") {
                 LabeledContent("BMI", value: String(format: "%.1f", profile.bmi))
                 LabeledContent("Category", value: profile.bmiCategory.rawValue)
                 LabeledContent("Daily Energy", value: "\(Int(profile.tdee)) cal")
                 LabeledContent("Risk Level", value: profile.riskLevel.rawValue)
             }
         }

         Section("Privacy") {
             Toggle("Show Health Insights", isOn: $showHealthInsights)

             Text("All health calculations are done on your device. Data never leaves your phone except for encrypted cloud sync.")
                 .font(.caption)
                 .foregroundStyle(.secondary)
         }
     }
 }

 Step 7.3: Update Services to Respect Toggle

 Modify: MealLogicService and others

 func calculateHealthScore(...) -> Double {
     @AppStorage("personalized_feedback_enabled") var isEnabled = true

     if !isEnabled {
         return baseScore  // Skip personalization
     }

     // ... personalized scoring
 }

 Step 7.4-7.6: Refactor, Cleanup, Verify

 - Test toggles work
 - Health insights display correctly
 - Privacy controls functional
 - Build succeeds

 Deliverable: User controls for personalized feedback and privacy

 ---
 Final Integration Testing

 After all phases complete:

 1. Full regression testing
   - All existing features work
   - All new features work
   - No performance degradation
 2. User acceptance testing
   - Create test profiles (low/medium/high risk)
   - Test meal entries across all profiles
   - Verify visual feedback, haptics, smiley behavior
 3. Build verification
   - Clean build succeeds
   - Zero warnings
   - All tests pass
 4. Code coverage check
   - Target >90% coverage for new code
   - Critical paths fully tested

 ---
 Success Criteria

 ✅ Phase 1: Health profile service calculating BMI, TDEE, sensitivity
 ✅ Phase 2: Meal scoring personalized based on user profile
 ✅ Phase 3: Visual feedback (borders/tints) on meal cards
 ✅ Phase 4: Smiley sensitivity enhanced for at-risk users
 ✅ Phase 5: Haptic feedback intensity varies by profile
 ✅ Phase 6: AI considers user health context (optional)
 ✅ Phase 7: User controls and privacy settings

 All tests pass, build succeeds, zero tech debt remaining.