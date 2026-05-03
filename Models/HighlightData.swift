import Foundation

/// Data captured in the Highlight (morning) tab: sleep quality, sleep notes,
/// structured to-do items, and free-form morning thoughts.
struct HighlightData: Codable, Equatable {
    /// User-selected sleep quality emoji
    var sleepQuality: SleepQuality?

    /// Free-form notes about sleep
    var sleepNotes: String?

    /// Structured morning to-do items (reuses MindCheckEntry for backward compatibility)
    var todos: [MindCheckEntry]

    /// Free-form Apple Notes-style morning thoughts
    var morningThoughts: String?

    /// When this data was last modified (for auto-save tracking)
    var lastModified: Date

    init(
        sleepQuality: SleepQuality? = nil,
        sleepNotes: String? = nil,
        todos: [MindCheckEntry] = [],
        morningThoughts: String? = nil,
        lastModified: Date = Date()
    ) {
        self.sleepQuality = sleepQuality
        self.sleepNotes = sleepNotes
        self.todos = todos
        self.morningThoughts = morningThoughts
        self.lastModified = lastModified
    }

    /// Whether any meaningful content has been entered
    var hasContent: Bool {
        self.sleepQuality != nil
            || !(self.sleepNotes ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !self.todos.isEmpty
            || !(self.morningThoughts ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether sleep has been logged (quality selected)
    var hasSleepLogged: Bool {
        self.sleepQuality != nil
    }
}
