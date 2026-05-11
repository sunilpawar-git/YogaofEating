import Foundation

/// The result of running `DailySynthesisEngine.synthesize(...)`.
/// Contains the full four-dimension model plus the derived smiley suggestion.
struct DailySynthesis: Equatable {
    let dimensions: WellbeingDimensions
    let textSignals: [TextSignal]
    let smileySuggestion: SmileyState
    let dominantDimension: WellbeingDimension
    let causalNarrative: String

    static func == (lhs: DailySynthesis, rhs: DailySynthesis) -> Bool {
        lhs.dimensions == rhs.dimensions
            && lhs.textSignals == rhs.textSignals
            && lhs.smileySuggestion.mood == rhs.smileySuggestion.mood
            && lhs.smileySuggestion.scale == rhs.smileySuggestion.scale
            && lhs.dominantDimension == rhs.dominantDimension
            && lhs.causalNarrative == rhs.causalNarrative
    }
}
