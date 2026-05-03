import Foundation

/// Data captured in the Reflect (evening) tab: free-form journal text
/// and overall feeling emoji. To-do review reads from HighlightData.todos.
struct ReflectData: Codable, Equatable {
    /// Free-form evening reflection journal text
    var journalText: String?

    /// How the user felt overall at end of day
    var feeling: ReflectionFeeling?

    /// When this data was last modified (for auto-save tracking)
    var lastModified: Date

    init(
        journalText: String? = nil,
        feeling: ReflectionFeeling? = nil,
        lastModified: Date = Date()
    ) {
        self.journalText = journalText
        self.feeling = feeling
        self.lastModified = lastModified
    }

    /// Whether any meaningful content has been entered
    var hasContent: Bool {
        !(self.journalText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || self.feeling != nil
    }

    /// Whether the feeling has been logged
    var hasFeelingLogged: Bool {
        self.feeling != nil
    }
}
