import Foundation
import SwiftUI

/// Physical activity level for TDEE calculation (Mifflin-St Jeor activity multipliers).
/// Values are ordered from least to most active; rawValue enables UserDefaults persistence.
enum ActivityLevel: Int, Codable, CaseIterable {
    case sedentary = 0
    case lightlyActive = 1
    case moderatelyActive = 2
    case veryActive = 3

    /// Harris-Benedict / Mifflin-St Jeor activity multiplier for this level.
    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .lightlyActive: 1.375
        case .moderatelyActive: 1.55
        case .veryActive: 1.725
        }
    }

    /// Localized display name sourced from `Strings.Settings` (SSOT — never hardcode in views).
    var displayName: String {
        switch self {
        case .sedentary: Strings.Settings.activityLevelSedentary
        case .lightlyActive: Strings.Settings.activityLevelLightlyActive
        case .moderatelyActive: Strings.Settings.activityLevelModeratelyActive
        case .veryActive: Strings.Settings.activityLevelVeryActive
        }
    }
}

/// BMI (Body Mass Index) categories based on WHO standards
enum BMICategory: String, Codable, CaseIterable {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"

    /// Determine BMI category from BMI value
    /// - Parameter bmi: Body Mass Index value
    /// - Returns: Appropriate BMI category
    static func from(bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5:
            .underweight
        case 18.5..<25.0:
            .normal
        case 25.0..<30.0:
            .overweight
        default:
            .obese
        }
    }
}

/// Health risk level based on BMI and age
enum HealthRiskLevel: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

/// User's gender for BMR calculations
enum Gender: Int, Codable, CaseIterable {
    case unspecified = 0
    case male = 1
    case female = 2
    case other = 3
}

/// Unit system for measurements
enum UnitSystem: Int, Codable, CaseIterable {
    case metric = 0 // kg, cm
    case imperial = 1 // lbs, inches
}

/// User's dietary goal for personalized coaching.
enum DietaryGoal: String, Codable, CaseIterable {
    case weightLoss
    case maintenance
    case muscleGain
    case heartHealth
    case generalWellness

    var displayName: String {
        switch self {
        case .weightLoss: Strings.Settings.DietaryGoal.weightLoss
        case .maintenance: Strings.Settings.DietaryGoal.maintenance
        case .muscleGain: Strings.Settings.DietaryGoal.muscleGain
        case .heartHealth: Strings.Settings.DietaryGoal.heartHealth
        case .generalWellness: Strings.Settings.DietaryGoal.generalWellness
        }
    }
}

/// Complete user health profile with calculated metrics
struct UserHealthProfile: Equatable {
    /// User's age in years
    let age: Int

    /// Body Mass Index (BMI)
    let bmi: Double

    /// BMI category (underweight/normal/overweight/obese)
    let bmiCategory: BMICategory

    /// Basal Metabolic Rate (BMR) - calories burned at rest
    let bmr: Double

    /// Total Daily Energy Expenditure (TDEE) - estimated daily calorie needs
    let tdee: Double

    /// Health risk level based on BMI and age
    let riskLevel: HealthRiskLevel

    /// Sensitivity multiplier for personalized scoring (0.5 - 1.5)
    /// Higher values mean stricter scoring for unhealthy foods
    let sensitivityMultiplier: Double

    /// User's self-reported physical activity level; drives the TDEE multiplier
    let activityLevel: ActivityLevel

    /// User's dietary goal for personalized briefing coaching (nil if not set)
    let dietaryGoal: DietaryGoal?

    init(
        age: Int,
        bmi: Double,
        bmiCategory: BMICategory,
        bmr: Double,
        tdee: Double,
        riskLevel: HealthRiskLevel,
        sensitivityMultiplier: Double,
        activityLevel: ActivityLevel,
        dietaryGoal: DietaryGoal? = nil
    ) {
        self.age = age
        self.bmi = bmi
        self.bmiCategory = bmiCategory
        self.bmr = bmr
        self.tdee = tdee
        self.riskLevel = riskLevel
        self.sensitivityMultiplier = sensitivityMultiplier
        self.activityLevel = activityLevel
        self.dietaryGoal = dietaryGoal
    }
}

// MARK: - Codable (manual implementation for backward-compatible decoding)

extension UserHealthProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case age, bmi, bmiCategory, bmr, tdee, riskLevel, sensitivityMultiplier, activityLevel, dietaryGoal
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.age = try c.decode(Int.self, forKey: .age)
        self.bmi = try c.decode(Double.self, forKey: .bmi)
        self.bmiCategory = try c.decode(BMICategory.self, forKey: .bmiCategory)
        self.bmr = try c.decode(Double.self, forKey: .bmr)
        self.tdee = try c.decode(Double.self, forKey: .tdee)
        self.riskLevel = try c.decode(HealthRiskLevel.self, forKey: .riskLevel)
        self.sensitivityMultiplier = try c.decode(Double.self, forKey: .sensitivityMultiplier)
        // Existing persisted profiles pre-date this field — default to .sedentary
        self.activityLevel = try c.decodeIfPresent(ActivityLevel.self, forKey: .activityLevel) ?? .sedentary
        // Existing persisted profiles pre-date this field — default to nil
        self.dietaryGoal = try c.decodeIfPresent(DietaryGoal.self, forKey: .dietaryGoal)
    }
}

// MARK: - Meal Feedback Color Extensions

extension Color {
    /// Positive feedback color for healthy meal choices (green)
    static let mealFeedbackPositive = Color.green

    /// Warning feedback color for unhealthy meal choices (orange)
    static let mealFeedbackWarning = Color.orange
}

// MARK: - Meal Card Visual Feedback Helper

/// Calculates visual feedback properties for meal cards based on health scores
struct MealCardFeedback {
    // MARK: - Constants (use ScoringThresholds as SSOT — see Logic/MealLogicService.swift)

    private enum BorderWidth {
        /// Standard thin border for all meals (uniform, minimal UI)
        static let standard: CGFloat = 1.0
    }

    private enum TintOpacity {
        /// Green tint opacity for healthy meals
        static let positive: Double = 0.1

        /// Orange tint opacity for unhealthy meals
        static let warning: Double = 0.08

        /// No tint for neutral meals
        static let none: Double = 0.0
    }

    // MARK: - Properties

    let score: Double
    let mealTypeColor: Color

    // MARK: - Computed Properties

    /// Border color - uses subtle meal type color for minimal, uniform appearance
    /// - Returns: Meal type color with reduced opacity for all scores
    var borderColor: Color {
        self.mealTypeColor.opacity(0.3)
    }

    /// Border width - always thin for minimal, uniform appearance
    /// - Returns: Standard thin border from theme
    var borderWidth: CGFloat {
        AppTheme.MealCard.borderWidth
    }

    /// Tint opacity for background overlay
    /// - Returns: Opacity value for subtle color tint based on score
    var tintOpacity: Double {
        if self.score > ScoringThresholds.healthy {
            TintOpacity.positive
        } else if self.score < ScoringThresholds.unhealthy {
            TintOpacity.warning
        } else {
            TintOpacity.none
        }
    }

    /// Tint color for background overlay
    /// - Returns: Color to use for tinting the card background
    var tintColor: Color {
        if self.score > ScoringThresholds.healthy {
            .mealFeedbackPositive
        } else if self.score < ScoringThresholds.unhealthy {
            .mealFeedbackWarning
        } else {
            .clear
        }
    }
}
