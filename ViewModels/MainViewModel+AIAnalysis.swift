import Foundation
import OSLog
import SwiftUI

private let aiLogger = Logger(subsystem: "com.yogaofeating", category: "AIAnalysis")

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

        guard !meals[index].isAIAnalyzed else { return }

        let description = items.joined(separator: ", ")

        guard description.count >= Self.minimumContentLength else { return }

        // Validate description before sending to Firebase
        switch InputValidator.validateMealDescription(description) {
        case let .failure(error):
            await MainActor.run {
                self.lastValidationError = error
                self.showValidationErrorAlert = true
            }
            return
        case let .success(sanitized):
            // Use sanitized description for analysis
            let validatedDescription = sanitized
            let wasInserted = analysisInProgress.insert(mealId).inserted
            guard wasInserted else { return }
            defer { analysisInProgress.remove(mealId) }

            // Only proceed if we are using a service that supports AI analysis
            guard let aiService = logicService as? AIAnalysisProvider else {
                let currentScore = meals[index].healthScore
                updateSmileyState(with: currentScore)
                return
            }

            do {
                aiLogger.debug("AI analysis started for meal (item count: \(items.count, privacy: .public))")
                let result = try await aiService.analyzeMealQuality(description: validatedDescription)
                aiLogger
                    .debug(
                        "AI analysis complete — score: \(result.score, privacy: .public), mood: \(result.mood.rawValue, privacy: .public)"
                    )

                // Update the specific meal's health score, AI analyzed flag, and basic insight.
                // Array copy ensures @Published triggers SwiftUI observation reliably.
                if let verifyIndex = meals.firstIndex(where: { $0.id == mealId }) {
                    var updatedMeals = meals
                    updatedMeals[verifyIndex].healthScore = result.score
                    updatedMeals[verifyIndex].isAIAnalyzed = true
                    updatedMeals[verifyIndex].aiInsight = result.insight
                    meals = updatedMeals
                    saveData()
                }

                // Update overall Smiley state based on new CUMULATIVE health (no haptics — background completion)
                await self.reanalyzeAllMealsForSmileyState(withFeedback: false)

            } catch {
                aiLogger.error("AI analysis failed: \(error.localizedDescription, privacy: .public)")
                // Fallback: Ensure smiley state is consistent with local score (no haptics)
                await self.reanalyzeAllMealsForSmileyState(withFeedback: false)
            }
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
