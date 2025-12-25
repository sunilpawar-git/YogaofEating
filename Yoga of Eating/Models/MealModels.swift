import Foundation

/// Represents a single meal entry in the "Yoga of Eating".
struct Meal: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    var description: String
    var healthScore: Double // 0.0 (unhealthy) to 1.0 (very healthy)
    
    init(id: UUID = UUID(), timestamp: Date = Date(), description: String = "", healthScore: Double = 0.5) {
        self.id = id
        self.timestamp = timestamp
        self.description = description
        self.healthScore = healthScore
    }
}

/// Represents the visual and physiological state of the Smiley friend.
struct SmileyState: Codable {
    /// The scale factor of the smiley (bloat/shrink). 1.0 is neutral.
    var scale: Double
    
    /// The emotional mood of the smiley (e.g., serene, overwhelmed).
    var mood: SmileyMood
    
    static let neutral = SmileyState(scale: 1.0, mood: .serene)
}

enum SmileyMood: String, Codable {
    case serene    // 🙂
    case neutral   // 😐
    case overwhelmed // 😮
}
