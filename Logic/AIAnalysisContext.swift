import Foundation

/// Write-back contract passed to `AIAnalysisCoordinator` so it can update
/// `MainViewModel`'s `@Published` properties without holding a direct reference.
///
/// All closure types are `@MainActor` — the coordinator always invokes them
/// on the main actor to preserve `@Published` reactivity and thread safety.
///
/// `currentMealsSnapshot` is a value-type copy captured at the moment the context
/// is created. The coordinator uses it only for the `guard meal exists` check;
/// it never writes back to this array.
struct AIAnalysisContext {
    let logicService: any AIAnalysisProvider

    /// A snapshot of the current meals array at the time the analysis is requested.
    /// Read-only inside the coordinator — mutations go through the write-back closures.
    let currentMealsSnapshot: [Meal]

    /// Called on `@MainActor` after the AI service returns a score.
    /// - Parameters:
    ///   - mealId: The meal that was analysed.
    ///   - score: The health score returned by the AI service.
    ///   - insight: Optional text insight returned by the AI service.
    let onMealScoreUpdated: @MainActor (UUID, Double, String?) -> Void

    /// Called on `@MainActor` after `reanalyzeAll` resolves the new smiley state.
    let onSmileyStateChanged: @MainActor (SmileyState) -> Void

    /// Optional live check — called on `@MainActor` just before the network request.
    /// Returns `false` if analysis should be skipped (e.g. the meal was already AI-analyzed
    /// by a concurrent path since the context was created). Defaults to always proceed.
    let shouldProceed: @MainActor (UUID) -> Bool

    init(
        logicService: any AIAnalysisProvider,
        currentMealsSnapshot: [Meal],
        onMealScoreUpdated: @escaping @MainActor (UUID, Double, String?) -> Void,
        onSmileyStateChanged: @escaping @MainActor (SmileyState) -> Void,
        shouldProceed: (@MainActor (UUID) -> Bool)? = nil
    ) {
        self.logicService = logicService
        self.currentMealsSnapshot = currentMealsSnapshot
        self.onMealScoreUpdated = onMealScoreUpdated
        self.onSmileyStateChanged = onSmileyStateChanged
        self.shouldProceed = shouldProceed ?? { _ in true }
    }
}
