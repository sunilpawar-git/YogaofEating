import Foundation

// MARK: - MealUpdateActions

/// Groups all meal-related update callbacks to reduce callback proliferation.
/// Use this struct to pass meal actions through the view hierarchy cleanly.
struct MealUpdateActions {
    /// Called when the user submits a meal (green checkmark tap) — triggers save + AI analysis.
    let onUpdate: (UUID, MealType, [String]) -> Void

    /// Called when meal timestamp is updated
    let onUpdateTimestamp: (UUID, Date) -> Void

    /// Called when meal is deleted
    let onDelete: (UUID) -> Void

    /// Called when a historical meal is copied to today
    let onCopy: ((Meal) -> Void)?

    /// Default empty actions for previews and optional usage
    static let empty = MealUpdateActions(
        onUpdate: { _, _, _ in },
        onUpdateTimestamp: { _, _ in },
        onDelete: { _ in },
        onCopy: nil
    )

    init(
        onUpdate: @escaping (UUID, MealType, [String]) -> Void,
        onUpdateTimestamp: @escaping (UUID, Date) -> Void = { _, _ in },
        onDelete: @escaping (UUID) -> Void,
        onCopy: ((Meal) -> Void)? = nil
    ) {
        self.onUpdate = onUpdate
        self.onUpdateTimestamp = onUpdateTimestamp
        self.onDelete = onDelete
        self.onCopy = onCopy
    }
}

// MARK: - MealType

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
    /// AI-estimated calorie count for this meal. nil until AI analysis completes.
    var estimatedCalories: Int?
    /// Macro breakdown from AI analysis. nil for legacy meals analyzed before the macro feature.
    var protein: Int?
    var carbs: Int?
    var fat: Int?

    /// True only when all three macro fields carry a value (even zero — e.g. black coffee).
    /// A meal may be `isAIAnalyzed` yet still return `false` here — macros are only present
    /// for meals analyzed after the macro feature was deployed.
    var hasCompleteMacros: Bool { self.protein != nil && self.carbs != nil && self.fat != nil }

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
        healthScore: Double = 0.0,
        isAIAnalyzed: Bool = false,
        aiInsight: String? = nil,
        estimatedCalories: Int? = nil,
        protein: Int? = nil,
        carbs: Int? = nil,
        fat: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = mealType ?? MealType.suggestedMealType()
        self.items = items
        self.healthScore = healthScore
        self.isAIAnalyzed = isAIAnalyzed
        self.aiInsight = aiInsight
        self.estimatedCalories = estimatedCalories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    /// Legacy initializer for backward compatibility
    init(id: UUID = UUID(), timestamp: Date = Date(), description: String = "", healthScore: Double = 0.0) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = MealType.suggestedMealType()
        self.items = description.isEmpty ? [] : [description]
        self.healthScore = healthScore
        self.isAIAnalyzed = false
        self.aiInsight = nil
        self.estimatedCalories = nil
    }
}
