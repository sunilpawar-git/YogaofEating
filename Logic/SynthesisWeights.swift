import Foundation

/// SSOT for the weighting of each data stream in the daily synthesis calculation.
/// Weights define how much each dimension contributes to the overall wellbeing score
/// when that dimension has actual data. Absent data streams are excluded, not zeroed.
enum SynthesisWeights {
    /// Meals are the primary signal — highest weight.
    static let physicalLoad: Double = 0.50

    /// Sleep quality and HealthKit data — second strongest signal.
    static let cognitiveClarity: Double = 0.25

    /// Feeling emoji and journal sentiment — meaningful when present.
    static let emotionalTone: Double = 0.15

    /// Todo completion rate — behavioural signal; lowest weight.
    static let behavioralMomentum: Double = 0.10
}

/// SSOT for the exercise bonus tiers applied to physicalLoad.
/// Bonus is additive on top of the food-based base score and capped at exerciseBonusMax.
enum ExerciseBonusTiers {
    static let tier1Threshold: Double = 150 // kcal floor for any bonus
    static let tier2Threshold: Double = 300
    static let tier3Threshold: Double = 500 // full bonus floor
    static let tier1Bonus: Double = 0.05
    static let tier2Bonus: Double = 0.10
    static let max: Double = 0.15
}

/// Smiley scale targets for each mood band. Scale is animated toward these targets.
enum SynthesisScaleTargets {
    static let serene: Double = 0.85 // shrinks slightly toward calm
    static let neutral: Double = 1.0 // sits at rest
    static let thoughtful: Double = 1.05 // barely perceptible upward nudge
    static let overwhelmed: Double = 1.3 // noticeable bloat, less than legacy 2.5
}
