import FirebaseCore
import FirebaseFunctions
import Foundation

/// Service to interact with the server-side AI logic via Firebase Cloud Functions.
class AILogicService: AIAnalysisProvider {
    private var functions: Functions?

    /// Initialize with optional Firebase Functions instance for dependency injection
    init(functions: Functions? = nil) {
        // Only initialize Firebase Functions if Firebase is configured
        if let providedFunctions = functions {
            self.functions = providedFunctions
        } else if FirebaseApp.app() != nil {
            self.functions = Functions.functions()
        } else {
            self.functions = nil
        }
    }

    // MARK: - MealLogicProvider Implementation (Synchronous Fallback)

    func calculateHealthScore(for _: String) -> Double {
        // Fallback or placeholder for immediate feedback
        // In a real app, this might use a local heuristic while waiting for AI
        0.5
    }

    func calculateHealthScore(for _: [String]) -> Double {
        // Fallback for multiple items
        0.5
    }

    func calculateNextState(from currentState: SmileyState, healthScore: Double) -> SmileyState {
        // Reuse the logic from MealLogicService model for state transitions locally
        // or we can implement the same logic here.
        // For consistency, let's use a helper or duplicate the simple logic.
        var nextState = currentState

        if healthScore > 0.6 {
            nextState.scale = max(0.5, currentState.scale - 0.1)
            nextState.mood = .serene
        } else if healthScore < 0.4 {
            nextState.scale = min(2.5, currentState.scale + 0.2)
            nextState.mood = .overwhelmed
        } else {
            nextState.mood = .neutral
            if nextState.scale > 1.0 {
                nextState.scale -= 0.05
            } else if nextState.scale < 1.0 {
                nextState.scale += 0.05
            }
        }
        return nextState
    }

    // MARK: - Async Cloud Function Call

    // swiftlint:disable:next large_tuple
    func analyzeMealQuality(description: String, intention: String? = nil) async throws -> (
        score: Double,
        mood: SmileyMood,
        sound: String,
        insight: String?
    ) {
        guard let functions = self.functions else {
            return (0.5, .neutral, "tink", nil)
        }

        #if DEBUG
            print("📡 Calling Firebase Cloud Function 'analyzeMeal'")
        #endif

        var requestData: [String: Any] = ["description": description]
        if let intention, !intention.isEmpty {
            requestData["intention"] = intention
        }

        let result = try await functions.httpsCallable("analyzeMeal").call(requestData)

        guard let data = result.data as? [String: Any] else {
            throw NSError(
                domain: "AILogicService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
            )
        }

        let score = data["healthScore"] as? Double ?? 0.5
        let moodString = data["mood"] as? String ?? "neutral"
        let sound = data["sound"] as? String ?? "tink"
        let insight = data["insight"] as? String

        let mood = SmileyMood.fromServer(moodString) ?? .neutral

        #if DEBUG
            print("📋 Parsed response - healthScore: \(score), mood: \(moodString), sound: \(sound)")
        #endif

        return (score, mood, sound, insight)
    }
}

extension SmileyMood {
    /// Parses a server-returned mood string (case-insensitive).
    static func fromServer(_ value: String) -> SmileyMood? {
        switch value.lowercased() {
        case "serene": .serene
        case "neutral": .neutral
        case "overwhelmed": .overwhelmed
        default: nil
        }
    }
}

// MARK: - Detailed Meal Insight

/// Detailed insight response from getMealInsight cloud function
struct DetailedMealInsight: Codable, Equatable {
    let summary: String
    let nutritionHighlights: [String]
    let tip: String?
    let category: String

    /// Category as ScoreCategory enum
    var scoreCategory: ScoreCategory {
        switch self.category.lowercased() {
        case "excellent":
            .excellent
        case "good":
            .good
        case "needs_improvement", "poor":
            .poor
        default:
            .moderate
        }
    }
}

/// Protocol for services that provide detailed meal insights
protocol MealInsightProvider {
    func getDetailedInsight(for meal: Meal) async throws -> DetailedMealInsight
}

extension AILogicService: MealInsightProvider {
    /// Fetches detailed insight for a specific meal (on-demand)
    func getDetailedInsight(for meal: Meal) async throws -> DetailedMealInsight {
        guard let functions = self.functions else {
            return DetailedMealInsight(
                summary: "This meal contributes to your daily nutrition.",
                nutritionHighlights: [],
                tip: "Keep tracking to see patterns!",
                category: "moderate"
            )
        }

        #if DEBUG
            print("📡 Calling Firebase Cloud Function 'getMealInsight'")
        #endif

        let requestData: [String: Any] = [
            "mealItems": meal.items,
            "mealType": meal.mealType.rawValue,
            "healthScore": meal.healthScore
        ]

        let result = try await functions.httpsCallable("getMealInsight").call(requestData)

        guard let data = result.data as? [String: Any] else {
            throw NSError(
                domain: "AILogicService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
            )
        }

        let summary = data["summary"] as? String ?? "A balanced meal choice."
        let nutritionHighlights = data["nutritionHighlights"] as? [String] ?? []
        let tip = data["tip"] as? String
        let category = data["category"] as? String ?? "moderate"

        #if DEBUG
            print("📋 Received detailed insight - category: \(category)")
        #endif

        return DetailedMealInsight(
            summary: summary,
            nutritionHighlights: nutritionHighlights,
            tip: tip,
            category: category
        )
    }
}
