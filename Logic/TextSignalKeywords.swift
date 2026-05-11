import Foundation

/// SSOT for keyword sets used by TextSignalExtractor.
/// All keyword additions and removals must happen here — never inline in the extractor.
enum TextSignalKeywords {
    static let grateful: [String] = [
        "grateful", "gratitude", "thankful", "blessed", "appreciate",
        "appreciation", "wonderful", "joy", "joyful", "happy", "content",
        "fortunate", "lucky", "abundance"
    ]

    static let stressed: [String] = [
        "stress", "stressed", "anxious", "anxiety", "worried", "worry",
        "tense", "nervous", "pressure", "deadline", "uneasy", "restless",
        "unsettled", "on edge"
    ]

    static let overwhelmed: [String] = [
        "overwhelmed", "too much", "too many", "can't cope", "cannot cope",
        "drowning", "exhausted", "burnt out", "burned out", "swamped",
        "overloaded", "falling behind"
    ]

    static let clear: [String] = [
        "clear", "clarity", "focused", "productive", "organized", "organised",
        "plan", "planning", "goals", "intention", "purpose", "ready",
        "prepared", "structured", "methodical"
    ]

    static let agentive: [String] = [
        "chose", "decided", "committed", "action", "initiative", "took charge",
        "made progress", "achieved", "completed", "succeeded", "accomplished",
        "delivered", "pushed through", "stepped up"
    ]

    static let selfCompassionate: [String] = [
        "gentle", "kind to myself", "self-care", "self care", "grace",
        "forgive", "forgave", "self-compassion", "compassion", "compassionate",
        "understanding", "patience", "patient", "rest", "nurture"
    ]
}
