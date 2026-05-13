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
