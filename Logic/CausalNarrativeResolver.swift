import Foundation

/// Pure value type that maps a dominant wellbeing dimension and its score to a direction-aware narrative string.
/// For the physical dimension, also injects meal count and avg score from NarrativeContext.
/// Extracted from DailySynthesisEngine to keep narrative logic independently testable.
enum CausalNarrativeResolver {
    /// Returns a direction-aware narrative string for the given dimension and score.
    /// - Parameters:
    ///   - dimension: The dominant wellbeing dimension driving the narrative.
    ///   - score: The score of that dimension (0–1). > 0.5 → high, < 0.5 → low, == 0.5 → neutral.
    ///   - context: Meal aggregate data for the physical dimension narrative.
    static func resolve(dimension: WellbeingDimension, score: Double, context: NarrativeContext) -> String {
        if score > 0.5 {
            self.highVariant(for: dimension, context: context)
        } else if score < 0.5 {
            self.lowVariant(for: dimension, context: context)
        } else {
            self.neutralVariant(for: dimension, context: context)
        }
    }

    // context is only consumed by .physicalLoad; other dimension branches ignore it.
    // The parameter is kept uniform so resolve() has a single call path through these helpers.
    private static func highVariant(for dimension: WellbeingDimension, context: NarrativeContext) -> String {
        switch dimension {
        case .physicalLoad:
            String(
                format: Strings.Synthesis.CausalNarrative.physical_high_fmt,
                context.mealCount,
                Int((context.avgMealScore * 100).rounded())
            )
        case .emotionalTone: Strings.Synthesis.CausalNarrative.emotional_high
        case .cognitiveClarity: Strings.Synthesis.CausalNarrative.cognitive_high
        case .behavioralMomentum: Strings.Synthesis.CausalNarrative.behavioral_high
        }
    }

    private static func lowVariant(for dimension: WellbeingDimension, context: NarrativeContext) -> String {
        switch dimension {
        case .physicalLoad:
            String(
                format: Strings.Synthesis.CausalNarrative.physical_low_fmt,
                context.mealCount,
                Int((context.avgMealScore * 100).rounded())
            )
        case .emotionalTone: Strings.Synthesis.CausalNarrative.emotional_low
        case .cognitiveClarity: Strings.Synthesis.CausalNarrative.cognitive_low
        case .behavioralMomentum: Strings.Synthesis.CausalNarrative.behavioral_low
        }
    }

    private static func neutralVariant(for dimension: WellbeingDimension, context: NarrativeContext) -> String {
        switch dimension {
        case .physicalLoad:
            String(
                format: Strings.Synthesis.CausalNarrative.physical_neutral_fmt,
                context.mealCount,
                Int((context.avgMealScore * 100).rounded())
            )
        case .emotionalTone: Strings.Synthesis.CausalNarrative.emotional_neutral
        case .cognitiveClarity: Strings.Synthesis.CausalNarrative.cognitive_neutral
        case .behavioralMomentum: Strings.Synthesis.CausalNarrative.behavioral_neutral
        }
    }
}
