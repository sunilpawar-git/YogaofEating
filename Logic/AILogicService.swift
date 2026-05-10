import FirebaseCore
import FirebaseFunctions
import Foundation
import OSLog

private let aiServiceLogger = Logger(subsystem: "com.yogaofeating", category: "AILogicService")

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

        if healthScore > ScoringThresholds.healthy {
            nextState.scale = max(0.5, currentState.scale - 0.1)
            nextState.mood = .serene
        } else if healthScore < ScoringThresholds.unhealthy {
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

    /// Calls the 'analyzeMeal' Firebase Cloud Function.
    func analyzeMealQuality(description: String) async throws -> MealAnalysisResult {
        guard let functions = self.functions else {
            aiServiceLogger.warning("Firebase Functions not available — returning defaults")
            return MealAnalysisResult(score: 0.5, mood: .neutral, sound: "tink", insight: nil, estimatedCalories: nil)
        }

        aiServiceLogger.debug("Calling Firebase Cloud Function 'analyzeMeal'")

        let result = try await functions.httpsCallable("analyzeMeal").call(["description": description])

        guard let data = result.data as? [String: Any] else {
            aiServiceLogger.error("Invalid response format from Cloud Function")
            throw AppError.analysisUnavailable
        }

        let score = data["healthScore"] as? Double ?? 0.5
        let moodString = data["mood"] as? String ?? "neutral"
        let sound = data["sound"] as? String ?? "tink"
        let insight = data["insight"] as? String
        let estimatedCalories = data["estimatedCalories"] as? Int

        let mood = SmileyMood(rawValue: moodString) ?? .neutral

        aiServiceLogger
            .debug("Parsed response — score: \(score, privacy: .public), mood: \(moodString, privacy: .public)")

        return MealAnalysisResult(
            score: score,
            mood: mood,
            sound: sound,
            insight: insight,
            estimatedCalories: estimatedCalories
        )
    }
}

// SmileyMood.init?(rawValue:) case-insensitive extension lives in Models/SmileyState.swift.

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
            aiServiceLogger.warning("Firebase Functions not available — returning fallback insight")
            return DetailedMealInsight(
                summary: "This meal contributes to your daily nutrition.",
                nutritionHighlights: [],
                tip: "Keep tracking to see patterns!",
                category: "moderate"
            )
        }

        aiServiceLogger.debug("Calling Firebase Cloud Function 'getMealInsight'")

        let requestData: [String: Any] = [
            "mealItems": meal.items,
            "mealType": meal.mealType.rawValue,
            "healthScore": meal.healthScore
        ]

        let result = try await functions.httpsCallable("getMealInsight").call(requestData)

        guard let data = result.data as? [String: Any] else {
            throw AppError.analysisUnavailable
        }

        let summary = data["summary"] as? String ?? "A balanced meal choice."
        let nutritionHighlights = data["nutritionHighlights"] as? [String] ?? []
        let tip = data["tip"] as? String
        let category = data["category"] as? String ?? "moderate"

        aiServiceLogger.debug("Received detailed insight — category: \(category, privacy: .public)")

        return DetailedMealInsight(
            summary: summary,
            nutritionHighlights: nutritionHighlights,
            tip: tip,
            category: category
        )
    }
}
