import Foundation

/// Protocol for health profile calculations
protocol HealthProfileServiceProtocol {
    /// Calculate Body Mass Index from height and weight
    /// - Parameters:
    ///   - height: Height in cm (metric) or inches (imperial)
    ///   - weight: Weight in kg (metric) or lbs (imperial)
    ///   - unitSystem: Unit system being used
    /// - Returns: BMI value, or 0 if invalid inputs
    func calculateBMI(height: Double, weight: Double, unitSystem: UnitSystem) -> Double

    /// Get BMI category from BMI value
    /// - Parameter bmi: Body Mass Index
    /// - Returns: BMI category (underweight/normal/overweight/obese)
    func getBMICategory(bmi: Double) -> BMICategory

    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor equation
    /// - Parameters:
    ///   - weight: Weight in kg (metric) or lbs (imperial)
    ///   - height: Height in cm (metric) or inches (imperial)
    ///   - age: Age in years
    ///   - gender: User's gender (affects calculation)
    ///   - unitSystem: Unit system being used
    /// - Returns: BMR in calories per day
    func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender, unitSystem: UnitSystem) -> Double

    /// Calculate Total Daily Energy Expenditure
    /// - Parameters:
    ///   - bmr: Basal Metabolic Rate
    ///   - activityLevel: Activity multiplier (default 1.2 for sedentary)
    /// - Returns: TDEE in calories per day
    func calculateTDEE(bmr: Double, activityLevel: Double) -> Double

    /// Get sensitivity multiplier for personalized scoring
    /// Higher BMI and older age result in stricter scoring
    /// - Parameters:
    ///   - bmi: Body Mass Index
    ///   - age: Age in years
    /// - Returns: Multiplier from 0.5 to 1.5 (higher = stricter)
    func getSensitivityMultiplier(bmi: Double, age: Int) -> Double

    /// Get health risk level based on BMI and age
    /// - Parameters:
    ///   - bmi: Body Mass Index
    ///   - age: Age in years
    /// - Returns: Risk level (low/medium/high)
    func getHealthRiskLevel(bmi: Double, age: Int) -> HealthRiskLevel

    /// Generate complete health profile from stored user data
    /// - Returns: UserHealthProfile if valid data exists, nil otherwise
    func getUserHealthProfile() -> UserHealthProfile?
}

/// Service for calculating health metrics and personalized sensitivity
class HealthProfileService: HealthProfileServiceProtocol {
    // MARK: - Constants

    // UserDefaults keys (matching existing SettingsView)
    private enum UserDefaultsKey {
        static let height = "user_height"
        static let weight = "user_weight"
        static let age = "user_age"
        static let gender = "user_gender"
        static let unitSystem = "unit_system"
    }

    // BMI thresholds
    private enum BMIThreshold {
        static let underweight: Double = 18.5
        static let normal: Double = 25.0
        static let overweight: Double = 30.0
    }

    // Sensitivity adjustments
    private enum SensitivityAdjustment {
        static let overweight: Double = 0.15
        static let obese: Double = 0.3
        static let age40to49: Double = 0.1
        static let age50to59: Double = 0.15
        static let age60plus: Double = 0.2
        static let minMultiplier: Double = 0.5
        static let maxMultiplier: Double = 1.5
    }

    // Age thresholds
    private enum AgeThreshold {
        static let forty = 40
        static let fifty = 50
        static let sixty = 60
        static let sixtyfive = 65
    }

    // Activity levels
    private enum ActivityLevel {
        static let sedentary: Double = 1.2
    }

    // Unit conversion
    private enum UnitConversion {
        static let lbsToKg: Double = 0.453592
        static let inchesToCm: Double = 2.54
        static let imperialBMIFactor: Double = 703.0
    }

    // MARK: - Properties

    private let userDefaults: UserDefaults

    // MARK: - Initialization

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
            return (weight / (height * height)) * UnitConversion.imperialBMIFactor
        }
    }

    // MARK: - BMI Category

    func getBMICategory(bmi: Double) -> BMICategory {
        BMICategory.from(bmi: bmi)
    }

    // MARK: - BMR Calculation (Mifflin-St Jeor Equation)

    func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender, unitSystem: UnitSystem) -> Double {
        var weightKg = weight
        var heightCm = height

        // Convert to metric if needed
        if unitSystem == .imperial {
            weightKg = weight * UnitConversion.lbsToKg
            heightCm = height * UnitConversion.inchesToCm
        }

        // Base calculation: 10 * weight(kg) + 6.25 * height(cm) - 5 * age(years)
        let baseMetabolism = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(age))

        // Adjust for gender
        // Male: +5, Female: -161, Unspecified/Other: average (-78)
        switch gender {
        case .male:
            return baseMetabolism + 5.0
        case .female:
            return baseMetabolism - 161.0
        case .unspecified, .other:
            // Use average of male and female adjustments
            return baseMetabolism - 78.0
        }
    }

    // MARK: - TDEE Calculation

    func calculateTDEE(bmr: Double, activityLevel: Double = ActivityLevel.sedentary) -> Double {
        // Default to sedentary (1.2) activity multiplier
        // Future enhancement: Make this user-configurable
        bmr * activityLevel
    }

    // MARK: - Sensitivity Multiplier

    func getSensitivityMultiplier(bmi: Double, age: Int) -> Double {
        var sensitivity = 1.0

        // BMI-based adjustments
        if bmi >= BMIThreshold.overweight { // >= 30 (obese)
            sensitivity += SensitivityAdjustment.obese
        } else if bmi >= BMIThreshold.normal { // >= 25 (overweight)
            sensitivity += SensitivityAdjustment.overweight
        }

        // Age-based adjustments
        if age >= AgeThreshold.sixty {
            sensitivity += SensitivityAdjustment.age60plus
        } else if age >= AgeThreshold.fifty {
            sensitivity += SensitivityAdjustment.age50to59
        } else if age >= AgeThreshold.forty {
            sensitivity += SensitivityAdjustment.age40to49
        }

        // Clamp to reasonable range
        return min(max(sensitivity, SensitivityAdjustment.minMultiplier), SensitivityAdjustment.maxMultiplier)
    }

    // MARK: - Health Risk Level

    func getHealthRiskLevel(bmi: Double, age: Int) -> HealthRiskLevel {
        let bmiCategory = self.getBMICategory(bmi: bmi)

        // High risk: Obese OR (overweight + older)
        if bmiCategory == .obese || (bmiCategory == .overweight && age >= AgeThreshold.fifty) {
            return .high
        }

        // Medium risk: Overweight OR (normal + very old)
        if bmiCategory == .overweight || (bmiCategory == .normal && age >= AgeThreshold.sixtyfive) {
            return .medium
        }

        // Low risk: Normal or underweight
        return .low
    }

    // MARK: - User Profile Generation

    func getUserHealthProfile() -> UserHealthProfile? {
        // Read user data from UserDefaults
        guard let heightString = userDefaults.string(forKey: UserDefaultsKey.height),
              let weightString = userDefaults.string(forKey: UserDefaultsKey.weight),
              let ageString = userDefaults.string(forKey: UserDefaultsKey.age),
              let height = Double(heightString),
              let weight = Double(weightString),
              let age = Int(ageString),
              height > 0, weight > 0, age > 0
        else {
            return nil
        }

        let genderRaw = self.userDefaults.integer(forKey: UserDefaultsKey.gender)
        let unitSystemRaw = self.userDefaults.integer(forKey: UserDefaultsKey.unitSystem)

        let gender = Gender(rawValue: genderRaw) ?? .unspecified
        let unitSystem = UnitSystem(rawValue: unitSystemRaw) ?? .metric

        // Calculate all metrics
        let bmi = self.calculateBMI(height: height, weight: weight, unitSystem: unitSystem)
        let bmiCategory = self.getBMICategory(bmi: bmi)
        let bmr = self.calculateBMR(weight: weight, height: height, age: age, gender: gender, unitSystem: unitSystem)
        let tdee = self.calculateTDEE(bmr: bmr)
        let riskLevel = self.getHealthRiskLevel(bmi: bmi, age: age)
        let sensitivity = self.getSensitivityMultiplier(bmi: bmi, age: age)

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
