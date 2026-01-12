import Foundation
import SwiftUI

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

/// Complete user health profile with calculated metrics
struct UserHealthProfile: Codable, Equatable {
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
    // MARK: - Constants

    private enum Threshold {
        /// Score above this is considered healthy (positive feedback)
        static let healthy: Double = 0.65

        /// Score below this is considered unhealthy (warning feedback)
        static let unhealthy: Double = 0.35
    }

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
        if self.score > Threshold.healthy {
            TintOpacity.positive
        } else if self.score < Threshold.unhealthy {
            TintOpacity.warning
        } else {
            TintOpacity.none
        }
    }

    /// Tint color for background overlay
    /// - Returns: Color to use for tinting the card background
    var tintColor: Color {
        if self.score > Threshold.healthy {
            .mealFeedbackPositive
        } else if self.score < Threshold.unhealthy {
            .mealFeedbackWarning
        } else {
            .clear
        }
    }
}
