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

    /// Builds an `AIAnalysisContext` for the given meal, wiring write-back closures
    /// that update this ViewModel's `@Published` properties on `@MainActor`.
    /// Called immediately before delegating to `aiCoordinator`.
    func makeAnalysisContext(mealId _: UUID) -> AIAnalysisContext {
        guard let aiService = self.logicService as? AIAnalysisProvider else {
            // Fallback context with a no-op service — coordinator guards will bail early
            return AIAnalysisContext(
                logicService: FallbackAnalysisProvider(),
                currentMealsSnapshot: self.meals,
                onMealScoreUpdated: { [weak self] _, score, _ in
                    self?.updateSmileyState(with: score)
                },
                onSmileyStateChanged: { [weak self] state in
                    self?.smileyState = state
                    self?.saveData()
                }
            )
        }

        return AIAnalysisContext(
            logicService: aiService,
            currentMealsSnapshot: self.meals,
            onMealScoreUpdated: { [weak self] id, score, insight in
                guard let self else { return }
                if let idx = self.meals.firstIndex(where: { $0.id == id }) {
                    var updated = self.meals
                    updated[idx].healthScore = score
                    updated[idx].isAIAnalyzed = true
                    updated[idx].aiInsight = insight
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                        self.meals = updated
                    }
                    self.saveData()
                }
                // After score update, reanalyze all meals for smiley state
                let freshCtx = AIAnalysisContext(
                    logicService: aiService,
                    currentMealsSnapshot: self.meals,
                    onMealScoreUpdated: { _, _, _ in },
                    onSmileyStateChanged: { [weak self] state in
                        self?.smileyState = state
                        self?.saveData()
                    }
                )
                self.aiCoordinator.reanalyzeAll(context: freshCtx)
            },
            onSmileyStateChanged: { [weak self] state in
                self?.smileyState = state
                self?.saveData()
            },
            shouldProceed: { [weak self] id in
                guard let self else { return false }
                // Skip analysis if the meal has already been AI-analyzed by a concurrent path
                return !(self.meals.first(where: { $0.id == id })?.isAIAnalyzed ?? true)
            }
        )
    }

    /// Performs deep AI analysis for a meal.
    /// This is an awaitable method (used by integration tests and triggerAIAnalysisForMeal).
    /// Fire-and-forget call sites use `aiCoordinator.analyzeIfNeeded` directly.
    func performDeepAnalysis(for mealId: UUID, items: [String]) async {
        guard let index = meals.firstIndex(where: { $0.id == mealId }) else { return }
        guard !meals[index].isAIAnalyzed else { return }

        let description = items.joined(separator: ", ")
        guard description.count >= Self.minimumContentLength else { return }

        // Validate and sanitize description before sending to Firebase
        let sanitized: String
        switch InputValidator.validateMealDescription(description) {
        case let .failure(error):
            self.lastValidationError = error
            self.showValidationErrorAlert = true
            return
        case let .success(s):
            sanitized = s
        }

        // Guard: only proceed if we are using an AI-capable service
        guard let aiService = logicService as? AIAnalysisProvider else {
            let currentScore = meals[index].healthScore
            updateSmileyState(with: currentScore)
            return
        }

        // Guard: prevent concurrent duplicate requests
        let wasInserted = self.aiCoordinator.markInProgress(mealId: mealId)
        guard wasInserted else { return }
        defer { self.aiCoordinator.clearInProgress(mealId: mealId) }

        do {
            aiLogger.debug("AI analysis started (item count: \(items.count, privacy: .public))")
            try Task.checkCancellation()

            let result = try await aiService.analyzeMealQuality(description: sanitized)
            aiLogger.debug(
                "AI analysis complete — score: \(result.score, privacy: .public), mood: \(result.mood.rawValue, privacy: .public)"
            )

            if let verifyIndex = meals.firstIndex(where: { $0.id == mealId }) {
                var updatedMeals = meals
                updatedMeals[verifyIndex].healthScore = result.score
                updatedMeals[verifyIndex].isAIAnalyzed = true
                updatedMeals[verifyIndex].aiInsight = result.insight
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    meals = updatedMeals
                }
                saveData()
            }

            await self.reanalyzeAllMealsForSmileyState(withFeedback: false)

        } catch {
            aiLogger.error("AI analysis failed: \(error.localizedDescription, privacy: .public)")
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

        let analyzedMeals = meals.filter(\.isAIAnalyzed)
        guard !analyzedMeals.isEmpty else {
            withAnimation(.spring()) {
                smileyState = .neutral
            }
            return
        }

        let totalScore = analyzedMeals.map(\.healthScore).reduce(0.0, +)
        let avgScore = totalScore / Double(analyzedMeals.count)

        updateSmileyState(with: avgScore, withFeedback: withFeedback)
        saveData()
    }
}

// MARK: - FallbackAnalysisProvider

/// Placeholder used when `logicService` is not an `AIAnalysisProvider`.
/// The coordinator's guard clause will bail before calling `analyzeMealQuality`,
/// so this is never actually invoked in production.
private struct FallbackAnalysisProvider: AIAnalysisProvider {
    func calculateHealthScore(for _: String) -> Double { ScoringThresholds.neutral }
    func calculateHealthScore(for _: [String]) -> Double { ScoringThresholds.neutral }
    func calculateNextState(from state: SmileyState, healthScore _: Double) -> SmileyState { state }
    func analyzeMealQuality(description _: String) async throws
        -> (score: Double, mood: SmileyMood, sound: String, insight: String?)
    {
        (ScoringThresholds.neutral, .neutral, "", nil)
    }
}
