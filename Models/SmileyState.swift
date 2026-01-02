import Foundation

/// Represents the visual and physiological state of the Smiley friend.
struct SmileyState: Codable {
    /// The scale factor of the smiley (bloat/shrink). 1.0 is neutral.
    var scale: Double

    /// The emotional mood of the smiley (e.g., serene, overwhelmed).
    var mood: SmileyMood

    nonisolated static let neutral = SmileyState(scale: 1.0, mood: .neutral)
}

enum SmileyMood: String, Codable {
    case serene // 🙂
    case neutral // 😐
    case overwhelmed // 😮
}
