import Foundation

/// Meal type categorization for better organization
enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snacks
    case drinks

    /// Returns suggested meal type based on current time
    static func suggestedMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())

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
    let timestamp: Date
    var mealType: MealType
    var items: [String]
    var healthScore: Double // 0.0 (unhealthy) to 1.0 (very healthy)

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

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mealType: MealType? = nil,
        items: [String] = [],
        healthScore: Double = 0.5
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = mealType ?? MealType.suggestedMealType()
        self.items = items
        self.healthScore = healthScore
    }

    /// Legacy initializer for backward compatibility
    init(id: UUID = UUID(), timestamp: Date = Date(), description: String = "", healthScore: Double = 0.5) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = MealType.suggestedMealType()
        self.items = description.isEmpty ? [] : [description]
        self.healthScore = healthScore
    }
}
