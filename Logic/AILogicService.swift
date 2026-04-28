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
    func analyzeMealQuality(description: String) async throws -> (score: Double, mood: SmileyMood, sound: String) {
        guard let functions = self.functions else {
            aiServiceLogger.warning("Firebase Functions not available — returning defaults")
            return (0.5, .neutral, "tink")
        }

        aiServiceLogger.debug("Calling Firebase Cloud Function 'analyzeMeal'")

        let result = try await functions.httpsCallable("analyzeMeal").call(["description": description])

        guard let data = result.data as? [String: Any] else {
            aiServiceLogger.error("Invalid response format from Cloud Function")
            throw NSError(
                domain: "AILogicService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
            )
        }

        let score = data["healthScore"] as? Double ?? 0.5
        let moodString = data["mood"] as? String ?? "neutral"
        let sound = data["sound"] as? String ?? "tink"

        let mood = SmileyMood(rawValue: moodString) ?? .neutral

        aiServiceLogger
            .debug("Parsed response — score: \(score, privacy: .public), mood: \(moodString, privacy: .public)")

        return (score, mood, sound)
    }
}

extension SmileyMood {
    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "serene":
            self = .serene
        case "neutral":
            self = .neutral
        case "overwhelmed":
            self = .overwhelmed
        default:
            return nil
        }
    }
}
