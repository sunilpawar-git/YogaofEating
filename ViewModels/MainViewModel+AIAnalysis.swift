import Foundation
import SwiftUI

// MARK: - AI Analysis Extension

extension MainViewModel {
    /// Performs deep AI analysis for a meal and updates smiley state accordingly.
    func performDeepAnalysis(for mealId: UUID, items: [String]) async {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        // Skip if already analyzed - prevents duplicate API calls
        guard !meals[index].isAIAnalyzed else {
            print("⏭️ Skipping analysis - meal already analyzed")
            return
        }

        // Prevent concurrent duplicate requests for the same meal
        // This addresses the "GTMSessionFetcher was already running" warning
        guard !analysisInProgress.contains(mealId) else {
            print("⏭️ Skipping analysis - request already in progress for this meal")
            return
        }

        // Mark this meal as being analyzed
        analysisInProgress.insert(mealId)
        defer { analysisInProgress.remove(mealId) }

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

            // Update the specific meal's health score, AI analyzed flag, and basic insight
            // NOTE: We create a new array copy to ensure @Published triggers SwiftUI view updates.
            // Direct in-place mutation (meals[index].property = value) may not reliably trigger
            // observation in SwiftUI, causing the UI to display stale values.
            if let verifyIndex = meals.firstIndex(where: { $0.id == mealId }) {
                var updatedMeals = meals
                updatedMeals[verifyIndex].healthScore = result.score
                updatedMeals[verifyIndex].isAIAnalyzed = true
                updatedMeals[verifyIndex].aiInsight = result.insight
                meals = updatedMeals
                saveData()
                print("📊 Updated meal healthScore to: \(result.score), isAIAnalyzed: true")
                if let insight = result.insight {
                    print("💡 Basic insight: \(insight.prefix(50))...")
                }
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
