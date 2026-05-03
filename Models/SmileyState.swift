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
    /// Slightly elevated starting state when the user has eaten poorly for 2+ consecutive days.
    /// Resets to normal as the user logs meals today. Scale 1.1 = mildly bloated.
    nonisolated static let concerned = SmileyState(scale: 1.1, mood: .concerned)
}

// Case names ARE the rawValues used in Codable and in the custom init?(rawValue:) below.
// If you add a case here, add it to the extension below too.
enum SmileyMood: String, Codable {
    case serene // 🙂
    case neutral // 😐
    case concerned // 😟 — food-debt starting state; not a meal-quality state
    case overwhelmed // 😮
}

// MARK: - Case-insensitive rawValue init (used by AILogicService when parsing Firebase responses)

// Kept here alongside the enum so new cases can't be added to one without the other being visible.
extension SmileyMood {
    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "serene": self = .serene
        case "neutral": self = .neutral
        case "concerned": self = .concerned
        case "overwhelmed": self = .overwhelmed
        default: return nil
        }
    }
}
