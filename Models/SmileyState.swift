import Foundation

/// Represents the visual and physiological state of the Smiley friend.
struct SmileyState: Codable {
    /// The scale factor of the smiley (bloat/shrink). 1.0 is neutral.
    /// Always guaranteed to be a valid, positive, finite value between 0.1 and 10.0
    var scale: Double {
        didSet {
            // Guard against invalid values
            if !self.scale.isFinite || self.scale <= 0 {
                self.scale = 1.0
            } else {
                self.scale = min(max(self.scale, 0.1), 10.0)
            }
        }
    }

    /// The emotional mood of the smiley (e.g., serene, overwhelmed).
    var mood: SmileyMood

    /// Creates a new SmileyState with validation
    init(scale: Double, mood: SmileyMood) {
        // Validate and clamp scale on initialization
        if scale.isFinite, scale > 0 {
            self.scale = min(max(scale, 0.1), 10.0)
        } else {
            self.scale = 1.0
        }
        self.mood = mood
    }

    nonisolated static let neutral = SmileyState(scale: 1.0, mood: .neutral)
}

enum SmileyMood: String, Codable {
    case serene // 🙂
    case neutral // 😐
    case overwhelmed // 😮
}
