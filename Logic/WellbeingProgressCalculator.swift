import Foundation

/// Pure progress-text calculator for the WellbeingBreakdownSheet progress pill.
/// No SwiftUI dependency — fully unit-testable.
/// SRP: computes motivational progress text from a mood + overall score only.
enum WellbeingProgressCalculator {
    /// Returns a human-readable string describing how many points the user is from
    /// the next smiley state, or nil if the user is already at the top (serene).
    ///
    /// Uses `SynthesisThresholds` exclusively — no magic number literals.
    /// Integer percentage arithmetic avoids IEEE 754 floating-point rounding issues.
    static func progressText(mood: SmileyMood, overall: Double) -> String? {
        switch mood {
        case .serene:
            return nil

        case .neutral:
            let pts = Self.pointsTo(SynthesisThresholds.overallHealthy, from: overall)
            return String(
                format: Strings.WellbeingBreakdown.progressFmt,
                pts, SmileyMood.serene.emoji, SmileyMood.serene.displayName
            )

        case .thoughtful:
            let pts = Self.pointsTo(SynthesisThresholds.overallNeutral, from: overall)
            return String(
                format: Strings.WellbeingBreakdown.progressFmt,
                pts, SmileyMood.neutral.emoji, SmileyMood.neutral.displayName
            )

        case .overwhelmed, .concerned:
            let pts = Self.pointsTo(SynthesisThresholds.overallThoughtful, from: overall)
            return String(
                format: Strings.WellbeingBreakdown.progressFmt,
                pts, SmileyMood.thoughtful.emoji, SmileyMood.thoughtful.displayName
            )
        }
    }

    // MARK: - Private

    /// Converts threshold and current scores to integer percentages before subtracting,
    /// avoiding IEEE 754 floating-point accumulation errors (e.g. 0.65 - 0.60 ≠ exactly 0.05).
    private static func pointsTo(_ threshold: Double, from overall: Double) -> Int {
        let thresholdPct = Int((threshold * 100).rounded())
        let overallPct = Int((overall * 100).rounded())
        // min 1 shown even at exact threshold — avoids "0 pts away" which reads as done before the mood flips
        return max(1, thresholdPct - overallPct)
    }
}
