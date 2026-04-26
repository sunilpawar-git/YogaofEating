import Foundation
import SwiftUI

// MARK: - AI Analysis Extension

extension MainViewModel {
    /// Minimum character count required before triggering AI analysis.
    /// Prevents excessive API calls while user is still typing short content.
    static let minimumContentLength: Int = 5

    /// Normalizes meal content for comparison to avoid redundant AI analysis.
    /// Trims whitespace and normalizes internal spacing.
    static func normalizeContent(_ items: [String]) -> String {
        items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
            .lowercased()
    }

    /// Checks if two item arrays represent meaningfully different content.
    /// Returns true if content is different enough to warrant re-analysis.
    static func contentMeaningfullyChanged(old: [String], new: [String]) -> Bool {
        let oldNormalized = self.normalizeContent(old)
        let newNormalized = self.normalizeContent(new)
        return oldNormalized != newNormalized
    }

    /// Performs deep AI analysis for a meal and updates smiley state accordingly.
    func performDeepAnalysis(for mealId: UUID, items: [String]) async {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }

        // Skip if already analyzed - prevents duplicate API calls
        guard !meals[index].isAIAnalyzed else {
            return
        }

        guard !analysisInProgress.contains(mealId) else {
            return
        }

        let description = items.joined(separator: ", ")

        guard description.count >= Self.minimumContentLength else {
            return
        }

        // Mark this meal as being analyzed
        analysisInProgress.insert(mealId)
        defer { analysisInProgress.remove(mealId) }

        // Only proceed if we are using a service that supports AI analysis
        guard let aiService = logicService as? AIAnalysisProvider else {
            // If strictly local service, just update smiley state with current score
            let currentScore = meals[index].healthScore
            updateSmileyState(with: currentScore)
            return
        }

        do {
            #if DEBUG
                print("🤖 AI Analysis started")
            #endif
            let result = try await aiService.analyzeMealQuality(
                description: description,
                intention: todaysIntention
            )
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
                #if DEBUG
                    print("📊 Updated meal healthScore to: \(result.score)")
                #endif
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
            #if DEBUG
                print("❌ AI Analysis failed: \(error.localizedDescription)")
            #endif
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

        updateSmileyState(with: meals.averageHealthScore)
        saveData()
    }
}
