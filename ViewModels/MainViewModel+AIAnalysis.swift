import Foundation
import SwiftUI

// MARK: - AI Analysis Extension

extension MainViewModel {
    /// Performs deep AI analysis for a meal and updates smiley state accordingly.
    func performDeepAnalysis(for mealId: UUID, items: [String]) async {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }
        let description = items.joined(separator: ", ")

        // Only proceed if we are using a service that supports AI analysis
        guard let aiService = logicService as? AIAnalysisProvider else {
            // If strictly local service, just update smiley state with current score
            let currentScore = meals[index].healthScore
            updateSmileyState(with: currentScore)
            return
        }

        do {
            print("🤖 AI Analysis started for meal: \(description)")
            let result = try await aiService.analyzeMealQuality(description: description)
            print(
                "✅ AI Analysis successful - Score: \(result.score), "
                    + "Mood: \(result.mood.rawValue), Sound: \(result.sound)"
            )

            // Update the specific meal's health score with AI result
            if let verifyIndex = meals.firstIndex(where: { $0.id == mealId }) {
                meals[verifyIndex].healthScore = result.score
                saveData()
                print("📊 Updated meal healthScore to: \(result.score)")
            }

            // Update overall Smiley state based on new CUMULATIVE health
            await self.reanalyzeAllMealsForSmileyState()
            print(
                "😊 Smiley state updated - Current mood: \(smileyState.mood.rawValue), "
                    + "Scale: \(smileyState.scale)"
            )

            // Sound feedback removed - was distracting during typing
            // Users can still enable sounds in Settings if desired, but sounds won't play automatically

        } catch {
            print("❌ AI Analysis failed: \(error.localizedDescription)")
            print("   Error details: \(error)")
            // Fallback: Ensure smiley state is consistent with local score
            await self.reanalyzeAllMealsForSmileyState()
        }
    }

    /// Reanalyzes all meals to update the smiley state.
    func reanalyzeAllMealsForSmileyState() async {
        guard !meals.isEmpty else {
            withAnimation(.spring()) {
                smileyState = .neutral
            }
            return
        }

        // Calculate average health score from all meals
        let totalScore = meals.map(\.healthScore).reduce(0.0, +)
        let avgScore = totalScore / Double(meals.count)

        updateSmileyState(with: avgScore)
        saveData()
    }
}
