import Foundation

/// Shared scoring thresholds — single source of truth used by MealLogicService,
/// AILogicService, SensoryService, and PatternAnalyzer so feedback tone and smiley always agree.
enum ScoringThresholds {
    /// Scores above this are considered "healthy"
    static let healthy: Double = 0.65
    /// Scores below this are considered "unhealthy"
    static let unhealthy: Double = 0.35
    /// Two consecutive days with averageHealthScore below this trigger the food-debt
    /// smiley starting state and a CorrelationCard in the morning briefing.
    /// Basis: Esposito et al. (2002) — inflammatory markers after 2 poor-eating days.
    static let foodDebtBadDay: Double = 0.45
    /// "Great week" threshold — weekly summary phrases above this score
    static let high: Double = 0.7
    /// Neutral/default fallback score when no data is available
    static let neutral: Double = 0.5
    /// Minimum consecutive days with score >= high to earn a "healthy eating streak" win
    static let minimumConsistentDays: Int = 5
}

/// Service responsible for the "Yoga of Eating" logic.
/// Adapts the Smiley's state based on meal choices.
protocol MealLogicProvider {
    func calculateHealthScore(for description: String) -> Double
    func calculateHealthScore(for items: [String]) -> Double
    func calculateNextState(from currentState: SmileyState, healthScore: Double) -> SmileyState
}

/// Protocol for services that provide AI-powered meal analysis
protocol AIAnalysisProvider: MealLogicProvider {
    /// Analyzes meal quality and returns score, mood, sound, and optional basic insight
    func analyzeMealQuality(description: String) async throws -> (
        score: Double,
        mood: SmileyMood,
        sound: String,
        insight: String?
    )
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

    private enum SmileyScaleConstants {
        /// Amount the scale shrinks per healthy meal
        static let shrinkAmount: Double = 0.1
        /// Amount the scale grows per unhealthy meal
        static let bloatAmount: Double = 0.2
        /// Neutral drift toward scale = 1.0 per meal
        static let neutralDrift: Double = 0.05
        /// Minimum smiley scale (shrink floor)
        static let scaleFloor: Double = 0.5
        /// Maximum smiley scale (bloat ceiling)
        static let scaleCeiling: Double = 2.5
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
    /// Note: Personalized feedback is always enabled by design.
    func calculateHealthScore(for description: String) -> Double {
        // 1. Calculate base score using keyword heuristic
        let baseScore = self.keywordBasedScore(for: description)

        // 2. Get user health profile (personalization is always on)
        guard let profile = healthProfileService.getUserHealthProfile() else {
            return baseScore // No personalization if profile unavailable
        }

        // 3. Apply sensitivity multiplier
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
        guard !items.isEmpty else { return ScoringConstants.neutralBase }

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
        // Healthy  (score > ScoringThresholds.healthy)   → Shrink (to floor)
        // Unhealthy (score < ScoringThresholds.unhealthy) → Bloat  (to ceiling)
        if healthScore > ScoringThresholds.healthy {
            let shrinkAmount = SmileyScaleConstants.shrinkAmount * sensitivity
            nextState.scale = max(SmileyScaleConstants.scaleFloor, currentState.scale - shrinkAmount)
            nextState.mood = .serene
        } else if healthScore < ScoringThresholds.unhealthy {
            let bloatAmount = SmileyScaleConstants.bloatAmount * sensitivity
            nextState.scale = min(SmileyScaleConstants.scaleCeiling, currentState.scale + bloatAmount)
            nextState.mood = .overwhelmed
        } else {
            // Neutral/Average — scale drifts toward 1.0
            nextState.mood = .neutral
            if nextState.scale > 1.0 {
                nextState.scale -= SmileyScaleConstants.neutralDrift
            } else if nextState.scale < 1.0 {
                nextState.scale += SmileyScaleConstants.neutralDrift
            }
        }

        return nextState
    }
}
