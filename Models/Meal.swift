import Foundation

/// Meal type categorization for better organization
enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snacks
    case drinks

    /// Returns suggested meal type based on the provided date
    static func suggestedMealType(for date: Date = Date()) -> MealType {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 6..<11:
            return .breakfast
        case 11..<15:
            return .lunch
        case 17..<22:
            return .dinner
        default:
            return .snacks
        }
    }

    /// Display name for UI
    var displayName: String {
        rawValue.capitalized
    }
}

/// Represents a single meal entry in the "Yoga of Eating".
struct Meal: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: Date
    var mealType: MealType
    var items: [String]
    var healthScore: Double // 0.0 (unhealthy) to 1.0 (very healthy)
    var isAIAnalyzed: Bool // True after AI (Gemini) has analyzed the meal
    var aiInsight: String? // AI-generated insight/reasoning for the health score

    /// Backward compatibility: computed property that joins items
    var description: String {
        get {
            self.items.isEmpty ? "" : self.items.joined(separator: ", ")
        }
        set {
            // When setting description, convert to items array
            self.items = newValue.isEmpty ? [] : [newValue]
        }
    }

    /// Whether the meal has a non-empty AI insight
    var hasAIInsight: Bool {
        guard let insight = aiInsight else { return false }
        return !insight.isEmpty
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mealType: MealType? = nil,
        items: [String] = [],
        healthScore: Double = 0.5,
        isAIAnalyzed: Bool = false,
        aiInsight: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = mealType ?? MealType.suggestedMealType()
        self.items = items
        self.healthScore = healthScore
        self.isAIAnalyzed = isAIAnalyzed
        self.aiInsight = aiInsight
    }

    /// Legacy initializer for backward compatibility
    init(id: UUID = UUID(), timestamp: Date = Date(), description: String = "", healthScore: Double = 0.5) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = MealType.suggestedMealType()
        self.items = description.isEmpty ? [] : [description]
        self.healthScore = healthScore
        self.isAIAnalyzed = false
        self.aiInsight = nil
    }
}
