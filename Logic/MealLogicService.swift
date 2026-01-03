import Foundation

/// Service responsible for the "Yoga of Eating" logic.
/// Adapts the Smiley's state based on meal choices.
protocol MealLogicProvider {
    func calculateHealthScore(for description: String) -> Double
    func calculateHealthScore(for items: [String]) -> Double
    func calculateNextState(from currentState: SmileyState, healthScore: Double) -> SmileyState
}

/// Protocol for services that provide AI-powered meal analysis
protocol AIAnalysisProvider: MealLogicProvider {
    func analyzeMealQuality(description: String) async throws -> (score: Double, mood: SmileyMood, sound: String)
}

class MealLogicService: MealLogicProvider {
    // MARK: - Properties

    private let healthProfileService: HealthProfileServiceProtocol

    // MARK: - Constants

    private enum ScoringConstants {
        static let neutralBase: Double = 0.5
        static let keywordBonus: Double = 0.1
        static let keywordPenalty: Double = 0.1

        // Contextual adjustment values
        static let friedFoodPenaltyHigh: Double = 0.15
        static let friedFoodPenaltyMedium: Double = 0.08
        static let vegetablesBonusHigh: Double = 0.1
        static let vegetablesBonusMedium: Double = 0.05
    }

    private let healthyKeywords = ["salad", "fruit", "avocado", "smoothie", "vegetable", "water", "organic", "green"]
    private let unhealthyKeywords = ["burger", "pizza", "fries", "coke", "soda", "sugar", "fried", "cheese"]
    private let friedFoodKeywords = ["fried", "deep-fried", "samosa", "pakora", "vada"]

    // MARK: - Initialization

    init(healthProfileService: HealthProfileServiceProtocol = HealthProfileService()) {
        self.healthProfileService = healthProfileService
    }

    // MARK: - Health Score Calculation

    /// Calculates a health score (0.0 - 1.0) based on string description.
    /// Uses keyword heuristic with personalized adjustments based on user's health profile.
    func calculateHealthScore(for description: String) -> Double {
        // 1. Calculate base score using keyword heuristic
        let baseScore = self.keywordBasedScore(for: description)

        // 2. Check if personalized feedback is enabled
        let isPersonalizedEnabled = UserDefaults.standard
            .object(forKey: "personalized_feedback_enabled") as? Bool ?? true
        guard isPersonalizedEnabled else {
            return baseScore // Skip personalization if disabled
        }

        // 3. Get user health profile
        guard let profile = healthProfileService.getUserHealthProfile() else {
            return baseScore // No personalization if profile unavailable
        }

        // 4. Apply sensitivity multiplier
        let adjustedScore = self.applySensitivityMultiplier(to: baseScore, multiplier: profile.sensitivityMultiplier)

        // 5. Apply contextual adjustments
        let finalScore = self.applyContextualAdjustments(
            score: adjustedScore,
            description: description,
            riskLevel: profile.riskLevel
        )

        return max(0.0, min(1.0, finalScore))
    }

    // MARK: - Private Helper Methods

    /// Base keyword-based scoring (original logic)
    private func keywordBasedScore(for description: String) -> Double {
        let input = description.lowercased()
        var score = ScoringConstants.neutralBase

        for word in self.healthyKeywords where input.contains(word) {
            score += ScoringConstants.keywordBonus
        }

        for word in self.unhealthyKeywords where input.contains(word) {
            score -= ScoringConstants.keywordPenalty
        }

        return score
    }

    /// Apply sensitivity multiplier to score
    /// Higher multiplier makes unhealthy foods worse and healthy foods better
    private func applySensitivityMultiplier(to score: Double, multiplier: Double) -> Double {
        // For unhealthy scores (<0.5), apply penalty
        // For healthy scores (>0.5), apply bonus
        let deviation = score - ScoringConstants.neutralBase
        let adjustedDeviation = deviation * multiplier
        return ScoringConstants.neutralBase + adjustedDeviation
    }

    /// Apply contextual adjustments based on food type and user risk level
    private func applyContextualAdjustments(
        score: Double,
        description: String,
        riskLevel: HealthRiskLevel
    ) -> Double {
        var adjustedScore = score
        let lowerDescription = description.lowercased()

        // Context: Fried foods for at-risk users
        let containsFriedFood = self.friedFoodKeywords.contains { lowerDescription.contains($0) }
        if containsFriedFood {
            switch riskLevel {
            case .high:
                adjustedScore -= ScoringConstants.friedFoodPenaltyHigh
            case .medium:
                adjustedScore -= ScoringConstants.friedFoodPenaltyMedium
            case .low:
                break // No additional penalty
            }
        }

        // Context: Boost vegetables/fruits for at-risk users
        let containsVegetables = self.healthyKeywords.contains { lowerDescription.contains($0) }
        if containsVegetables {
            switch riskLevel {
            case .high:
                adjustedScore += ScoringConstants.vegetablesBonusHigh
            case .medium:
                adjustedScore += ScoringConstants.vegetablesBonusMedium
            case .low:
                break // No additional bonus
            }
        }

        return adjustedScore
    }

    /// Calculates aggregate health score for multiple items.
    /// Returns average score across all items.
    func calculateHealthScore(for items: [String]) -> Double {
        guard !items.isEmpty else { return 0.5 }

        let scores = items.map { self.calculateHealthScore(for: $0) }
        let totalScore = scores.reduce(0.0, +)
        return totalScore / Double(scores.count)
    }

    /// Determines the next scale and mood for the Smiley.
    /// Enhanced with sensitivity multiplier for personalized reactions.
    func calculateNextState(from currentState: SmileyState, healthScore: Double) -> SmileyState {
        var nextState = currentState

        // Get sensitivity multiplier (1.0 if no profile available)
        let profile = self.healthProfileService.getUserHealthProfile()
        let sensitivity = profile?.sensitivityMultiplier ?? 1.0

        // Bloat/Shrink logic with sensitivity
        // Healthy (score > 0.6) -> Shrink (to a limit)
        // Unhealthy (score < 0.4) -> Bloat (to a limit)
        if healthScore > 0.6 {
            // Apply sensitivity to shrink amount
            let shrinkAmount = 0.1 * sensitivity
            nextState.scale = max(0.5, currentState.scale - shrinkAmount)
            nextState.mood = .serene
        } else if healthScore < 0.4 {
            // Apply sensitivity to bloat amount
            let bloatAmount = 0.2 * sensitivity
            nextState.scale = min(2.5, currentState.scale + bloatAmount)
            nextState.mood = .overwhelmed
        } else {
            // Neutral/Average
            nextState.mood = .neutral
            // Scale stays relatively same but drifts toward 1.0
            if nextState.scale > 1.0 {
                nextState.scale -= 0.05
            } else if nextState.scale < 1.0 {
                nextState.scale += 0.05
            }
        }

        return nextState
    }
}
