import Foundation

/// A historical record of a nudge suggestion shown to the user.
/// Stored in AppData to inform future briefing personalization.
struct NudgeHistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let suggestion: String
    var wasFollowedThrough: Bool?

    init(id: UUID = UUID(), date: Date, suggestion: String, wasFollowedThrough: Bool? = nil) {
        self.id = id
        self.date = date
        self.suggestion = suggestion
        self.wasFollowedThrough = wasFollowedThrough
    }
}
