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

    /// Composite score that only averages dimensions with real data.
    /// Returns 0.5 when no data is available for any dimension.
    var overall: Double {
        let scores = self.dataCompleteness.map { $0.value(in: self.dimensions) }
        guard !scores.isEmpty else { return 0.5 }
        return scores.reduce(0, +) / Double(scores.count)
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
