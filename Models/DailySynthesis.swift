import Foundation

/// The result of running `DailySynthesisEngine.synthesize(...)`.
/// Contains the full four-dimension model plus the derived smiley suggestion.
struct DailySynthesis: Equatable {
    let dimensions: WellbeingDimensions
    /// Which dimensions had actual data (not neutral 0.5 stubs).
    let dataCompleteness: Set<WellbeingDimension>
    let textSignals: [TextSignal]
    let smileySuggestion: SmileyState
    let dominantDimension: WellbeingDimension
    let causalNarrative: String

    /// Weighted composite score — applies `SynthesisWeights` to only the dimensions with
    /// real data. Matches the calculation used by `DailySynthesisEngine` to determine
    /// `smileySuggestion.mood`, so mood and score are always semantically consistent.
    /// Returns 0.5 when no data is available for any dimension.
    var overall: Double {
        var total = 0.0
        var weight = 0.0
        for dimension in self.dataCompleteness {
            let score = dimension.value(in: self.dimensions)
            switch dimension {
            case .physicalLoad: total += score * SynthesisWeights.physicalLoad
                weight += SynthesisWeights.physicalLoad
            case .emotionalTone: total += score * SynthesisWeights.emotionalTone
                weight += SynthesisWeights.emotionalTone
            case .cognitiveClarity: total += score * SynthesisWeights.cognitiveClarity
                weight += SynthesisWeights.cognitiveClarity
            case .behavioralMomentum: total += score * SynthesisWeights.behavioralMomentum
                weight += SynthesisWeights.behavioralMomentum
            }
        }
        return weight > 0 ? total / weight : 0.5
    }

    /// Returns the raw score for a dimension, or nil if that dimension has no real data.
    func score(for dimension: WellbeingDimension) -> Double? {
        guard self.dataCompleteness.contains(dimension) else { return nil }
        return dimension.value(in: self.dimensions)
    }

    /// Returns the display score for a dimension — real score if known, 0.5 fallback if not.
    func displayScore(for dimension: WellbeingDimension) -> Double {
        self.score(for: dimension) ?? 0.5
    }
}
