import Foundation

/// Centralises all String(format:) calls for correlation card observations.
/// SSOT: no other file in Logic/PatternAnalysis* should call String(format:) directly.
enum BriefingCardFormatter {
    static func intentionFollowthrough(rate: Double, gapDayCount: Int) -> String {
        let pct = Int((rate * 100).rounded())
        return String(format: Strings.Insight.Cards.intentionFollowthroughFmt, pct, gapDayCount)
    }

    static func sleepRecoveryCarryover(consecutivePairCount: Int) -> String {
        String(format: Strings.Insight.Cards.sleepRecoveryCarryoverFmt, consecutivePairCount)
    }

    static func carryOverLoad(lowDayCount: Int) -> String {
        String(format: Strings.Insight.Cards.carryOverLoadFmt, lowDayCount)
    }
}
