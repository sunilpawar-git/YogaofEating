import Foundation
@testable import Yoga_of_Eating

// MARK: - SynthesisInputBuilder

/// Fluent builder for `DailySynthesisEngine.synthesize(...)` inputs.
/// Eliminates boilerplate in characterization and unit tests for the synthesis pipeline.
final class SynthesisInputBuilder {
    private(set) var meals: [Meal] = []
    private(set) var highlightData: HighlightData?
    private(set) var reflectData: ReflectData?
    private(set) var appleSleepData: SleepData?
    private(set) var yesterday: DailySmileySnapshot?
    private(set) var activeCaloriesBurned: Double?

    @discardableResult
    func withMeals(_ count: Int, avgScore: Double) -> Self {
        self.meals = (0..<count).map { _ in MealBuilder().withScore(avgScore).analyzed().build() }
        return self
    }

    @discardableResult
    func withMeals(_ meals: [Meal]) -> Self {
        self.meals = meals
        return self
    }

    @discardableResult
    func withSleepQuality(_ quality: SleepQuality) -> Self {
        var data = self.highlightData ?? HighlightData()
        data.sleepQuality = quality
        self.highlightData = data
        return self
    }

    @discardableResult
    func withTodos(_ todos: [MindCheckEntry]) -> Self {
        var data = self.highlightData ?? HighlightData()
        data.todos = todos
        self.highlightData = data
        return self
    }

    @discardableResult
    func withHighlightData(_ data: HighlightData) -> Self {
        self.highlightData = data
        return self
    }

    @discardableResult
    func withFeeling(_ feeling: ReflectionFeeling) -> Self {
        var data = self.reflectData ?? ReflectData()
        data.feeling = feeling
        self.reflectData = data
        return self
    }

    @discardableResult
    func withReflectData(_ data: ReflectData) -> Self {
        self.reflectData = data
        return self
    }

    @discardableResult
    func withAppleSleepData(_ data: SleepData) -> Self {
        self.appleSleepData = data
        return self
    }

    @discardableResult
    func withYesterday(_ snapshot: DailySmileySnapshot) -> Self {
        self.yesterday = snapshot
        return self
    }

    @discardableResult
    func withActiveCalories(_ kcal: Double) -> Self {
        self.activeCaloriesBurned = kcal
        return self
    }

    /// Convenience: run the engine directly from this builder's configured inputs.
    func synthesize(with engine: DailySynthesisEngine) -> DailySynthesis {
        engine.synthesize(
            meals: self.meals,
            highlightData: self.highlightData,
            reflectData: self.reflectData,
            appleSleepData: self.appleSleepData,
            yesterday: self.yesterday,
            activeCaloriesBurned: self.activeCaloriesBurned
        )
    }
}

// MARK: - SnapshotWeekBuilder

/// Fluent builder that produces a week of `DailySmileySnapshot` fixtures.
/// Used by pattern-analysis tests (characterization and integration) to avoid
/// hand-crafting multi-day snapshot arrays.
final class SnapshotWeekBuilder {
    private var dayCount = 7
    private var avgScore: Double = 0.5
    private var sleepQuality: SleepQuality?
    private var todosPerDay: [MindCheckEntry] = []
    private var feeling: ReflectionFeeling?
    private var morningThoughts: String?
    private var journalEntry: String?

    @discardableResult
    func withDayCount(_ count: Int) -> Self {
        self.dayCount = count
        return self
    }

    @discardableResult
    func withDefaultScore(_ score: Double) -> Self {
        self.avgScore = score
        return self
    }

    @discardableResult
    func withSleepQuality(_ quality: SleepQuality) -> Self {
        self.sleepQuality = quality
        return self
    }

    @discardableResult
    func withTodosPerDay(_ todos: [MindCheckEntry]) -> Self {
        self.todosPerDay = todos
        return self
    }

    @discardableResult
    func withFeeling(_ feeling: ReflectionFeeling) -> Self {
        self.feeling = feeling
        return self
    }

    @discardableResult
    func withMorningThoughts(_ text: String) -> Self {
        self.morningThoughts = text
        return self
    }

    @discardableResult
    func withJournalEntry(_ text: String) -> Self {
        self.journalEntry = text
        return self
    }

    func build() -> [DailySmileySnapshot] {
        (0..<self.dayCount).map { daysAgo in
            let meal = MealBuilder().withScore(self.avgScore).analyzed().build()
            var builder = DailySmileySnapshotBuilder()
                .daysAgo(daysAgo)
                .withMeals([meal])

            let hasSleep = self.sleepQuality != nil
            let hasTodos = !self.todosPerDay.isEmpty
            let hasMorningThoughts = self.morningThoughts != nil
            if hasSleep || hasTodos || hasMorningThoughts {
                var highlight = HighlightData(
                    sleepQuality: self.sleepQuality,
                    todos: self.todosPerDay
                )
                highlight.morningThoughts = self.morningThoughts
                builder = builder.withHighlightData(highlight)
            }

            let hasFeeling = self.feeling != nil
            let hasJournal = self.journalEntry != nil
            if hasFeeling || hasJournal {
                var reflect = ReflectData(feeling: self.feeling)
                reflect.journalText = self.journalEntry
                builder = builder.withReflectData(reflect)
            }

            return builder.build()
        }
    }
}
