import Foundation

/// Represents the context in which a mind check is performed.
/// Morning checks happen before/during the first part of the day,
/// evening checks happen as the day winds down.
enum MindCheckContext: String, Codable, CaseIterable {
    case morning
    case evening
}

/// Categories for mind check entries.
/// Morning categories focus on intentions and gratitude.
/// Evening categories focus on reflection and release.
enum MindCheckCategory: String, Codable, CaseIterable {
    // Morning categories
    case todo
    case gratitude
    case thinking

    // Evening categories
    case accomplished
    case gratefulFor
    case letGo

    /// The emoji representation for UI display
    var emoji: String {
        switch self {
        case .todo:
            "📝"
        case .gratitude:
            "🙏"
        case .thinking:
            "💭"
        case .accomplished:
            "✅"
        case .gratefulFor:
            "🙏"
        case .letGo:
            "🍃"
        }
    }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .todo:
            "To-Do"
        case .gratitude:
            "Grateful for"
        case .thinking:
            "Thinking about"
        case .accomplished:
            "Accomplished"
        case .gratefulFor:
            "Grateful for"
        case .letGo:
            "Let go of"
        }
    }

    /// The context this category belongs to
    var context: MindCheckContext {
        switch self {
        case .todo, .gratitude, .thinking:
            .morning
        case .accomplished, .gratefulFor, .letGo:
            .evening
        }
    }

    /// Returns categories available for a specific context
    /// - Parameter context: The mind check context (morning or evening)
    /// - Returns: Array of categories available for that context
    static func categories(for context: MindCheckContext) -> [MindCheckCategory] {
        switch context {
        case .morning:
            [.todo, .gratitude, .thinking]
        case .evening:
            [.accomplished, .gratefulFor, .letGo]
        }
    }

    /// Static list of morning categories
    static let morningCategories: [MindCheckCategory] = [.todo, .gratitude, .thinking]

    /// Static list of evening categories
    static let eveningCategories: [MindCheckCategory] = [.accomplished, .gratefulFor, .letGo]
}

/// Represents a single mind check entry - a thought, intention, or reflection
/// captured during a morning or evening check-in.
struct MindCheckEntry: Codable, Identifiable, Equatable {
    /// Unique identifier for this entry
    let id: UUID

    /// The category of this entry (todo, gratitude, etc.)
    let category: MindCheckCategory

    /// The text content of the entry (max ~50 chars recommended)
    let text: String

    /// When this entry was created
    let timestamp: Date

    /// The context in which this entry was created
    let context: MindCheckContext

    /// Whether this todo was accomplished (only applicable for .todo category)
    /// nil = not yet reviewed, true = done, false = not done
    var isAccomplished: Bool?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, category, text, timestamp, context, isAccomplished
    }

    // MARK: - Initialization

    /// Creates a new mind check entry with all properties.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - category: The category of this entry
    ///   - text: The text content
    ///   - timestamp: When created (defaults to now)
    ///   - context: Morning or evening context
    ///   - isAccomplished: Whether this todo was accomplished (optional)
    init(
        id: UUID = UUID(),
        category: MindCheckCategory,
        text: String,
        timestamp: Date = Date(),
        context: MindCheckContext,
        isAccomplished: Bool? = nil
    ) {
        self.id = id
        self.category = category
        self.text = text
        self.timestamp = timestamp
        self.context = context
        self.isAccomplished = isAccomplished
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.category = try container.decode(MindCheckCategory.self, forKey: .category)
        self.text = try container.decode(String.self, forKey: .text)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.context = try container.decode(MindCheckContext.self, forKey: .context)
        self.isAccomplished = try container.decodeIfPresent(Bool.self, forKey: .isAccomplished)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.category, forKey: .category)
        try container.encode(self.text, forKey: .text)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encode(self.context, forKey: .context)
        try container.encodeIfPresent(self.isAccomplished, forKey: .isAccomplished)
    }

    // MARK: - Helpers

    /// Returns a copy of this entry with the accomplished status updated
    func withAccomplished(_ accomplished: Bool) -> MindCheckEntry {
        var copy = self
        copy.isAccomplished = accomplished
        return copy
    }
}
