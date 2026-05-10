import Foundation
import OSLog

private let coordinatorLogger = Logger(subsystem: "com.yogaofeating", category: "AIAnalysisCoordinator")

// MARK: - Protocol

/// Abstraction over the AI analysis coordination layer.
/// MainViewModel holds an `AIAnalysisCoordinating` reference so the coordinator
/// can be replaced with a test double without touching MainViewModel.
@MainActor
protocol AIAnalysisCoordinating {
    /// Queues an AI analysis for a meal, cancelling any in-flight task for the same meal.
    func analyzeIfNeeded(mealId: UUID, items: [String], in context: AIAnalysisContext)

    /// Reanalyzes all meals in the context snapshot to determine the new smiley state.
    func reanalyzeAll(context: AIAnalysisContext)

    /// Cancels any in-flight analysis for the given meal.
    func cancelAnalysis(for mealId: UUID)

    /// Returns the current in-flight task for a meal (for testing and cancellation checks).
    func task(for mealId: UUID) -> Task<Void, Never>?

    /// Marks a meal as in-progress for analysis. Returns true if the meal was not already in-progress.
    /// Used by `performDeepAnalysis` (the awaitable path) to guard concurrent calls.
    @discardableResult
    func markInProgress(mealId: UUID) -> Bool

    /// Clears the in-progress marker for a meal (called in `defer` of `performDeepAnalysis`).
    func clearInProgress(mealId: UUID)
}

// MARK: - Implementation

/// Coordinates AI meal analysis tasks in isolation from MainViewModel.
///
/// **Design:** The coordinator never holds a reference to MainViewModel.
/// All mutations flow back through `AIAnalysisContext` write-back closures,
/// keeping `@Published` reactivity intact and preventing retain cycles.
///
/// **Task management:**
/// - `aiTasks` tracks one in-flight task per meal ID.
/// - Starting a new analysis for a meal ID always cancels the prior task first.
/// - `analysisInProgress` is a guard against concurrent duplicate requests
///   (e.g. the same task spawning two concurrent Firebase calls).
@MainActor
final class AIAnalysisCoordinator: AIAnalysisCoordinating {
    // MARK: - Properties

    /// Tracks in-flight AI analysis tasks per meal. Cancels the prior task when a
    /// new request arrives for the same meal (rapid-edit debounce).
    private var aiTasks: [UUID: Task<Void, Never>] = [:]

    /// Prevents concurrent duplicate analysis calls for the same meal within a single task.
    private var analysisInProgress: Set<UUID> = []

    // minimumContentLength sourced from ScoringThresholds.minimumMealDescriptionLength (SSOT)

    // MARK: - AIAnalysisCoordinating

    func analyzeIfNeeded(mealId: UUID, items: [String], in context: AIAnalysisContext) {
        // Cancel any prior in-flight task for this meal
        self.aiTasks[mealId]?.cancel()

        self.aiTasks[mealId] = Task {
            await self.runAnalysis(mealId: mealId, items: items, context: context)
            self.aiTasks[mealId] = nil
        }
    }

    func reanalyzeAll(context: AIAnalysisContext) {
        let meals = context.currentMealsSnapshot
        guard !meals.isEmpty else {
            context.onSmileyStateChanged(.neutral)
            return
        }

        let analyzedMeals = meals.filter(\.isAIAnalyzed)
        guard !analyzedMeals.isEmpty else {
            context.onSmileyStateChanged(.neutral)
            return
        }

        let total = analyzedMeals.map(\.healthScore).reduce(0.0, +)
        let avg = total / Double(analyzedMeals.count)
        let newState = self.smileyState(forAverageScore: avg)
        context.onSmileyStateChanged(newState)
    }

    func cancelAnalysis(for mealId: UUID) {
        self.aiTasks[mealId]?.cancel()
        self.aiTasks[mealId] = nil
        self.analysisInProgress.remove(mealId)
    }

    func task(for mealId: UUID) -> Task<Void, Never>? {
        self.aiTasks[mealId]
    }

    @discardableResult
    func markInProgress(mealId: UUID) -> Bool {
        self.analysisInProgress.insert(mealId).inserted
    }

    func clearInProgress(mealId: UUID) {
        self.analysisInProgress.remove(mealId)
    }

    // MARK: - Private

    private func runAnalysis(mealId: UUID, items: [String], context: AIAnalysisContext) async {
        // Guard: meal must exist in the snapshot
        guard context.currentMealsSnapshot.contains(where: { $0.id == mealId }) else { return }

        // Guard: meal must not already be AI-analyzed
        guard let meal = context.currentMealsSnapshot.first(where: { $0.id == mealId }),
              !meal.isAIAnalyzed else { return }

        let description = items.joined(separator: ", ")

        // Guard: description must meet minimum length
        guard description.count >= ScoringThresholds.minimumMealDescriptionLength else { return }

        // Guard: validate input before sending to Firebase
        switch InputValidator.validateMealDescription(description) {
        case .failure:
            return
        case let .success(sanitized):
            // Guard: prevent concurrent duplicate requests
            let wasInserted = self.analysisInProgress.insert(mealId).inserted
            guard wasInserted else { return }
            defer { self.analysisInProgress.remove(mealId) }

            do {
                coordinatorLogger
                    .debug("AI analysis started (item count: \(items.count, privacy: .public))")
                // Check cancellation before the network call to prevent duplicate Firebase requests
                try Task.checkCancellation()

                // Live guard: confirm analysis is still needed (e.g. not already analyzed
                // by a concurrent awaitable call since the context was created)
                guard await MainActor.run(body: { context.shouldProceed(mealId) }) else { return }

                let result = try await context.logicService.analyzeMealQuality(description: sanitized)
                #if DEBUG
                    coordinatorLogger
                        .debug(
                            "AI analysis complete — score: \(result.score, privacy: .public), mood: \(result.mood.rawValue, privacy: .public)"
                        )
                #else
                    coordinatorLogger.debug("AI analysis complete for meal \(mealId, privacy: .public)")
                #endif

                // Deliver result on MainActor via write-back closure
                await MainActor.run {
                    context.onMealScoreUpdated(mealId, result.score, result.insight, result.estimatedCalories)
                }

                // After the score is updated, reanalyze all meals for the smiley state.
                // Build a fresh context snapshot by re-reading the updated meals.
                // The coordinator doesn't have the updated array; MainViewModel calls
                // reanalyzeAll with a fresh context after receiving onMealScoreUpdated.

            } catch {
                coordinatorLogger
                    .error("AI analysis failed: \(error.localizedDescription, privacy: .public)")
                // Failure is non-critical — MainViewModel handles smiley fallback via context.
            }
        }
    }

    // MARK: - Smiley state derivation

    private func smileyState(forAverageScore avg: Double) -> SmileyState {
        var state = SmileyState.neutral
        if avg > ScoringThresholds.healthy {
            state.mood = .serene
            state.scale = max(0.5, state.scale - 0.1)
        } else if avg < ScoringThresholds.unhealthy {
            state.mood = .overwhelmed
            state.scale = min(2.5, state.scale + 0.2)
        }
        return state
    }
}
