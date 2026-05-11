import Foundation

/// Minimal data contract for HighlightView.
/// Contains ONLY the data the Highlight tab needs — no meals, no smiley state.
struct HighlightViewContract: Equatable {
    let sleepQuality: SleepQuality?
    let sleepNotes: String?
    let todos: [MindCheckEntry]
    let morningThoughts: String?
    let healthKitSleepData: SleepData?
    let isToday: Bool

    static func == (lhs: HighlightViewContract, rhs: HighlightViewContract) -> Bool {
        lhs.sleepQuality == rhs.sleepQuality
            && lhs.sleepNotes == rhs.sleepNotes
            && lhs.todos == rhs.todos
            && lhs.morningThoughts == rhs.morningThoughts
            && lhs.healthKitSleepData == rhs.healthKitSleepData
            && lhs.isToday == rhs.isToday
    }
}

/// Minimal data contract for the WellbeingBreakdownSheet.
/// Contains only the synthesis output — no meals, no raw journal text.
struct WellbeingBreakdownSheetContract: Equatable {
    let dimensions: WellbeingDimensions
    let dominantDimension: WellbeingDimension
    let causalNarrative: String
    /// Up to 2 weakest dimensions (score < SynthesisThresholds.overallNeutral), sorted ascending.
    let weakDimensions: [WellbeingDimension]
}

/// Minimal data contract for ReflectView.
/// Contains ONLY the data the Reflect tab needs — no meals, no sleep data.
struct ReflectViewContract: Equatable {
    let journalText: String?
    let feeling: ReflectionFeeling?
    let morningTodos: [MindCheckEntry]
    let isToday: Bool
    /// Structured emotional signals extracted from the journal text. Added in Synthesis Layer phase.
    let detectedSignals: [TextSignal]
}
