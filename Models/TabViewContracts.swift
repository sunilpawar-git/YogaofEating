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

/// Minimal data contract for ReflectView.
/// Contains ONLY the data the Reflect tab needs — no meals, no sleep data.
struct ReflectViewContract: Equatable {
    let journalText: String?
    let feeling: ReflectionFeeling?
    let morningTodos: [MindCheckEntry]
    let isToday: Bool
}
