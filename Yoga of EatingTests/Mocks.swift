import Combine
import Foundation
@testable import Yoga_of_Eating

// MARK: - MockSynthesisScheduler

@MainActor
final class MockSynthesisScheduler: SynthesisScheduling {
    /// Records every trigger passed to `schedule(_:)` in call order.
    var scheduledTriggers: [SynthesisTrigger] = []

    func schedule(_ trigger: SynthesisTrigger) {
        self.scheduledTriggers.append(trigger)
    }

    func reset() {
        self.scheduledTriggers.removeAll()
    }
}

// MARK: - MockHistoricalDataService

@MainActor
class MockHistoricalDataService: HistoricalDataServiceProtocol {
    @Published var historicalData = HistoricalData()
    var archivedMeals: [Meal]?
    var archivedState: SmileyState?
    var archivedDate: Date?
    var clearAllDataCalled = false
    var updateReflectionCalled = false
    var lastUpdatedReflection: DailyReflection?
    var lastReflectionDate: Date?

    func setMainViewModel(_: any MainViewModelProtocol) {}

    var willChangePublisher: AnyPublisher<Void, Never> {
        self.objectWillChange.map { _ in () }.eraseToAnyPublisher()
    }

    func archiveCurrentDay(meals: [Meal], state: SmileyState, date: Date) {
        self.archivedMeals = meals
        self.archivedState = state
        self.archivedDate = date
    }

    func getSnapshot(for date: Date) -> DailySmileySnapshot? {
        self.historicalData.snapshot(for: date)
    }

    func getYearSnapshots(year: Int) -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        return self.historicalData.snapshots(in: start...end)
    }

    func saveHistoricalData() {}
    func syncToFirebase() async throws {}

    func clearAllData() {
        self.clearAllDataCalled = true
        self.historicalData = HistoricalData()
    }

    func updateReflection(for date: Date, reflection: DailyReflection) {
        self.updateReflectionCalled = true
        self.lastUpdatedReflection = reflection
        self.lastReflectionDate = date

        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withReflection(reflection))
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5, reflection: reflection
            ))
        }
    }

    func updateMorningMindCheck(for date: Date, entries: [MindCheckEntry]) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withMindChecks(morningMindCheck: entries))
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5, morningMindCheck: entries
            ))
        }
    }

    func updateEveningMindCheck(for date: Date, entries: [MindCheckEntry]) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withMindChecks(eveningMindCheck: entries))
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5, eveningMindCheck: entries
            ))
        }
    }

    func updateHighlightData(for date: Date, data: HighlightData) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withHighlightData(data))
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5, highlightData: data
            ))
        }
    }

    func updateReflectData(for date: Date, data: ReflectData) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withReflectData(data))
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5, reflectData: data
            ))
        }
    }

    var stubbedCarriedTodos: [MindCheckEntry] = []
    var stubbedFoodDebtState: SmileyState = .neutral

    func incompleteTodosForCarryOver(from _: Date) -> [MindCheckEntry] { self.stubbedCarriedTodos }
    func foodDebtStartingState(relativeTo _: Date) -> SmileyState { self.stubbedFoodDebtState }

    // MARK: - Briefing spy

    var updateBriefingCalled = false
    var lastUpdatedBriefing: DailyBriefing?

    func updateBriefing(for date: Date, briefing: DailyBriefing) {
        self.updateBriefingCalled = true
        self.lastUpdatedBriefing = briefing
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withBriefing(briefing))
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5, briefing: briefing
            ))
        }
    }

    // MARK: - Insight spy

    var updateInsightCalled = false
    var lastUpdatedInsight: DailyInsight?
    var lastInsightDate: Date?

    func updateInsight(for date: Date, insight: DailyInsight) {
        self.updateInsightCalled = true
        self.lastUpdatedInsight = insight
        self.lastInsightDate = date
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withInsight(insight))
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5, insight: insight
            ))
        }
    }

    // MARK: - EnrichedInsight spy

    var updateEnrichedInsightCalled = false
    var lastEnrichedInsight: EnrichedDailyInsight?

    func updateEnrichedInsight(for date: Date, insight: EnrichedDailyInsight) {
        self.updateEnrichedInsightCalled = true
        self.lastEnrichedInsight = insight
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withEnrichedInsight(insight))
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5,
                enrichedInsight: insight
            ))
        }
    }

    // MARK: - WellbeingDimensions spy

    var updateWellbeingDimensionsCalled = false
    var lastWellbeingDimensions: WellbeingDimensions?
    var lastWellbeingTextSignals: [TextSignal]?

    func updateWellbeingDimensions(for date: Date, dimensions: WellbeingDimensions, textSignals: [TextSignal]) {
        self.updateWellbeingDimensionsCalled = true
        self.lastWellbeingDimensions = dimensions
        self.lastWellbeingTextSignals = textSignals
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(
                snapshot: existing.withWellbeingDimensions(dimensions).withTextSignals(textSignals)
            )
        } else {
            self.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
                id: UUID(), date: normalizedDate, smileyState: .neutral,
                meals: [], mealCount: 0, averageHealthScore: 0.5,
                wellbeingDimensions: dimensions, textSignals: textSignals
            ))
        }
    }
}
