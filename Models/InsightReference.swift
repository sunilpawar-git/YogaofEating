import Foundation

/// Categories for insight references.
/// Used to classify what type of data point the reference is about.
enum ReferenceCategory: String, Codable, CaseIterable {
    case food
    case todo
    case sleep
    case feeling

    var displayName: String {
        switch self {
        case .food:
            "Food"
        case .todo:
            "Todo"
        case .sleep:
            "Sleep"
        case .feeling:
            "Feeling"
        }
    }

    var emoji: String {
        switch self {
        case .food:
            "🍽️"
        case .todo:
            "✅"
        case .sleep:
            "😴"
        case .feeling:
            "😊"
        }
    }
}

/// A reference to a specific data point that contributed to an insight.
/// Used to provide context like "12 Jan late evening coffee may have disturbed your sleep."
struct InsightReference: Codable, Identifiable, Equatable {
    /// Unique identifier
    let id: UUID

    /// The date this reference is about
    let date: Date

    /// Human-readable description of the data point
    /// e.g., "Late evening coffee", "Heavy dinner at 10pm", "3 todos completed"
    let description: String

    /// The category of data this reference is about
    let category: ReferenceCategory

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date,
        description: String,
        category: ReferenceCategory
    ) {
        self.id = id
        self.date = date
        self.description = description
        self.category = category
    }

    // MARK: - Computed Properties

    /// Formatted date string like "12 Jan"
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self.date)
    }

    /// Full formatted reference string like "12 Jan: Late evening coffee"
    var formattedReference: String {
        "\(self.formattedDate): \(self.description)"
    }
}

/// A detected pattern from analyzing user data.
/// Contains the type of pattern, description, confidence score, and supporting references.
struct InsightPattern: Codable, Identifiable, Equatable {
    /// Unique identifier
    let id: UUID

    /// The type of insight this pattern represents
    let type: InsightType

    /// Human-readable description of the pattern
    let description: String

    /// Confidence score from 0.0 to 1.0
    let confidence: Double

    /// References to specific data points that support this pattern
    let references: [InsightReference]

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        type: InsightType,
        description: String,
        confidence: Double,
        references: [InsightReference] = []
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.confidence = max(0, min(1, confidence))
        self.references = references
    }

    // MARK: - Computed Properties

    /// Whether this pattern has high confidence (>0.7)
    var isHighConfidence: Bool {
        self.confidence > 0.7
    }

    /// Whether this pattern has medium confidence (0.5-0.7)
    var isMediumConfidence: Bool {
        self.confidence >= 0.5 && self.confidence <= 0.7
    }
}
