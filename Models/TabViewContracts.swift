import Foundation

/// Minimal data contract for HighlightView.
/// Contains ONLY the data the Highlight tab needs — no meals, no smiley state.
/// `date` is the normalized start-of-day for the selected date.
/// HighlightView uses this field to detect date navigation and re-initialize
/// local text state — without reacting to same-day data mutations.
struct HighlightViewContract: Equatable {
    let sleepQuality: SleepQuality?
    let sleepNotes: String?
    let todos: [MindCheckEntry]
    let morningThoughts: String?
    let healthKitSleepData: SleepData?
    let isToday: Bool
    /// Normalized start-of-day for the selected date. Used by HighlightView to
    /// detect date navigation without reacting to same-day background updates.
    let date: Date

    static func == (lhs: HighlightViewContract, rhs: HighlightViewContract) -> Bool {
        lhs.date == rhs.date
            && lhs.sleepQuality == rhs.sleepQuality
            && lhs.sleepNotes == rhs.sleepNotes
            && lhs.todos == rhs.todos
            && lhs.morningThoughts == rhs.morningThoughts
            && lhs.healthKitSleepData == rhs.healthKitSleepData
            && lhs.isToday == rhs.isToday
    }
}

/// Minimal data contract for the WellbeingBreakdownSheet.
/// Contains only the synthesis output — no meals, no raw journal text.
struct WellbeingBreakdownSheetContract: Equatable, Hashable {
    let dimensions: WellbeingDimensions
    let dominantDimension: WellbeingDimension
    let causalNarrative: String
    /// Up to 2 weakest dimensions (score < SynthesisThresholds.weakDimension), sorted ascending.
    let weakDimensions: [WellbeingDimension]
    /// Number of meals logged today — used for the Physical dimension subtitle.
    let mealCount: Int
    /// The current smiley mood — drives the coach header in WellbeingBreakdownSheet.
    let currentMood: SmileyMood
    /// Weighted composite score from synthesis, range [0, 1] — drives the progress pill.
    let overallScore: Double
}

/// Minimal data contract for ReflectView.
/// Contains ONLY the data the Reflect tab needs — no meals, no sleep data.
/// `date` is the normalized start-of-day for the selected date.
/// ReflectView uses this field to detect date navigation and re-initialize
/// local text state — without reacting to same-day data mutations.
struct ReflectViewContract: Equatable {
    let journalText: String?
    let feeling: ReflectionFeeling?
    let morningTodos: [MindCheckEntry]
    let isToday: Bool
    /// Structured emotional signals extracted from the journal text. Added in Synthesis Layer phase.
    let detectedSignals: [TextSignal]
    /// Normalized start-of-day for the selected date. Used by ReflectView to
    /// detect date navigation without reacting to same-day background updates.
    let date: Date
}
