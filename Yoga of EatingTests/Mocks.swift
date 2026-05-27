import Combine
import Foundation
import HealthKit
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

    // MARK: - Sync spy

    var syncToFirebaseCalled = false
    var syncToFirebaseCallCount = 0
    var syncToFirebaseShouldThrow = false

    func syncToFirebase() async throws {
        self.syncToFirebaseCalled = true
        self.syncToFirebaseCallCount += 1
        if self.syncToFirebaseShouldThrow {
            throw AppError.syncUploadFailed(
                underlying: NSError(domain: "MockSync", code: 1, userInfo: nil)
            )
        }
    }

    // MARK: - Concurrency flags

    var isRestoreInProgress: Bool = false
    var isSyncInProgress: Bool = false

    // MARK: - Restore spy

    var restoreFromFirebaseCalled = false
    var restoreFromFirebaseShouldThrow = false

    func restoreFromFirebase() async throws {
        self.restoreFromFirebaseCalled = true
        if self.restoreFromFirebaseShouldThrow {
            throw AppError.syncAuthRequired
        }
    }

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
    var stubbedHistoricalSummary: HistoricalSummary?

    func incompleteTodosForCarryOver(from _: Date) -> [MindCheckEntry] { self.stubbedCarriedTodos }
    func foodDebtStartingState(relativeTo _: Date) -> SmileyState { self.stubbedFoodDebtState }

    func computeHistoricalSummary(relativeTo _: Date) -> HistoricalSummary {
        self.stubbedHistoricalSummary ?? HistoricalSummary(
            thirtyDayStats: PeriodStats(averageFoodScore: 0.5, daysLogged: 0),
            ninetyDayStats: nil,
            currentStreak: 0,
            bestDimension: nil,
            worstDimension: nil
        )
    }

    // MARK: - Unified insight spy

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

    // MARK: - weeklyDimensionAverages stub

    var stubbedWeeklyDimensionAverages: WellbeingDimensions?

    func weeklyDimensionAverages(relativeTo _: Date) -> WellbeingDimensions? {
        self.stubbedWeeklyDimensionAverages
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

// MARK: - MockNotificationScheduler

/// Test double for `NotificationScheduling`. Records call counts for assertion in unit tests.
final class MockNotificationScheduler: NotificationScheduling {
    var scheduleMorningNudgeCallCount = 0
    var cancelMorningNudgeCallCount = 0
    var scheduleDefaultMealRemindersCallCount = 0
    var cancelMealRemindersCallCount = 0

    func scheduleMorningNudge(at _: Date) { self.scheduleMorningNudgeCallCount += 1 }
    func cancelMorningNudge() { self.cancelMorningNudgeCallCount += 1 }
    func scheduleDefaultMealReminders() { self.scheduleDefaultMealRemindersCallCount += 1 }
    func cancelMealReminders() { self.cancelMealRemindersCallCount += 1 }

    func resetCounts() {
        self.scheduleMorningNudgeCallCount = 0
        self.cancelMorningNudgeCallCount = 0
        self.scheduleDefaultMealRemindersCallCount = 0
        self.cancelMealRemindersCallCount = 0
    }
}

// MARK: - MockHealthKitBodyMetricsProvider

/// Test double for `HealthKitBodyMetricsProviding`. Records call counts and returns stubs.
@MainActor
final class MockHealthKitBodyMetricsProvider: HealthKitBodyMetricsProviding {
    var requestAuthorizationCallCount = 0
    var fetchLatestWeightCallCount = 0
    var fetchLatestHeightCallCount = 0
    var fetchAgeCallCount = 0
    var fetchGenderCallCount = 0

    var shouldThrow = false
    var stubbedWeight: Double?
    var stubbedHeight: Double?
    var stubbedAge: Int?
    var stubbedGender: Int?

    func requestAuthorization() async throws -> Bool {
        self.requestAuthorizationCallCount += 1
        if self.shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return true
    }

    func fetchLatestWeight(unit _: HKUnit) async throws -> Double? {
        self.fetchLatestWeightCallCount += 1
        return self.stubbedWeight
    }

    func fetchLatestHeight(unit _: HKUnit) async throws -> Double? {
        self.fetchLatestHeightCallCount += 1
        return self.stubbedHeight
    }

    func fetchAge() throws -> Int? {
        self.fetchAgeCallCount += 1
        return self.stubbedAge
    }

    func fetchGender() throws -> Int? {
        self.fetchGenderCallCount += 1
        return self.stubbedGender
    }

    func resetCounts() {
        self.requestAuthorizationCallCount = 0
        self.fetchLatestWeightCallCount = 0
        self.fetchLatestHeightCallCount = 0
        self.fetchAgeCallCount = 0
        self.fetchGenderCallCount = 0
    }
}
