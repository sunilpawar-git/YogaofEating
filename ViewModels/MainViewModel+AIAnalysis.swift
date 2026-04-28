import Foundation
import OSLog
import SwiftUI

private let aiLogger = Logger(subsystem: "com.yogaofeating", category: "AIAnalysis")

// MARK: - AI Analysis Extension

extension MainViewModel {
    /// Performs deep AI analysis for a meal and updates smiley state accordingly.
    func performDeepAnalysis(for mealId: UUID, items: [String]) async {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }
        let description = items.joined(separator: ", ")

        // Only proceed if we are using a service that supports AI analysis
        guard let aiService = logicService as? AIAnalysisProvider else {
            let currentScore = meals[index].healthScore
            updateSmileyState(with: currentScore)
            return
        }

        do {
            aiLogger.debug("AI analysis started for meal (item count: \(items.count, privacy: .public))")
            let result = try await aiService.analyzeMealQuality(description: description)
            aiLogger
                .debug(
                    "AI analysis complete — score: \(result.score, privacy: .public), mood: \(result.mood.rawValue, privacy: .public)"
                )

            // Update the specific meal's health score and AI analyzed flag
            if let verifyIndex = meals.firstIndex(where: { $0.id == mealId }) {
                meals[verifyIndex].healthScore = result.score
                meals[verifyIndex].isAIAnalyzed = true
                saveData()
            }

            // Update overall Smiley state based on new CUMULATIVE health (no haptics — background completion)
            await self.reanalyzeAllMealsForSmileyState(withFeedback: false)
            print(
                "😊 Smiley state updated - Current mood: \(smileyState.mood.rawValue), "
                    + "Scale: \(smileyState.scale)"
            )

            // Sound feedback removed - was distracting during typing
            // Users can still enable sounds in Settings if desired, but sounds won't play automatically

        } catch {
            // Fallback: Ensure smiley state is consistent with local score (no haptics)
            await self.reanalyzeAllMealsForSmileyState(withFeedback: false)
        }
    }

    /// Reanalyzes all meals to update the smiley state.
    /// - Parameter withFeedback: Pass false when called from async AI completion to avoid
    ///   surprising the user with haptics while they are in a different context.
    func reanalyzeAllMealsForSmileyState(withFeedback: Bool = false) async {
        guard !meals.isEmpty else {
            withAnimation(.spring()) {
                smileyState = .neutral
            }
            return
        }

        let totalScore = meals.map(\.healthScore).reduce(0.0, +)
        let avgScore = totalScore / Double(meals.count)

        updateSmileyState(with: avgScore, withFeedback: withFeedback)
        saveData()
    }
}
