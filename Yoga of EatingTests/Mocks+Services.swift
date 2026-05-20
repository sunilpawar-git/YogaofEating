import Foundation
@testable import Yoga_of_Eating

// MARK: - MockPersistenceService

@MainActor
class MockPersistenceService: PersistenceServiceProtocol {
    var savedData: PersistenceService.AppData?
    var saveCalled = false
    var deleteAllCalled = false

    /// Stub the return value of `load()`. nil by default (simulates fresh install / missing file).
    var stubbedLoadData: PersistenceService.AppData?

    func load() -> PersistenceService.AppData? {
        self.stubbedLoadData
    }

    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date, historicalData: HistoricalData) {
        self.saveCalled = true
        self.savedData = PersistenceService.AppData(
            meals: meals,
            smileyState: smileyState,
            lastResetDate: lastResetDate,
            historicalData: historicalData
        )
    }

    func deleteAll() {
        self.deleteAllCalled = true
        self.savedData = nil
    }
}

// MARK: - MockMealLogicService

@MainActor
class MockMealLogicService: MealLogicProvider {
    var mockScore: Double = 0.5
    var nextState = SmileyState.neutral

    func calculateHealthScore(for _: String) -> Double { self.mockScore }

    func calculateHealthScore(for items: [String]) -> Double {
        guard !items.isEmpty else { return 0.5 }
        return self.mockScore
    }

    func calculateNextState(from _: SmileyState, healthScore _: Double) -> SmileyState {
        self.nextState
    }
}

// MARK: - MockHealthProfileService

class MockHealthProfileService: HealthProfileServiceProtocol {
    var mockProfile: UserHealthProfile?

    func calculateBMI(height _: Double, weight _: Double, unitSystem _: UnitSystem) -> Double {
        self.mockProfile?.bmi ?? 0.0
    }

    func getBMICategory(bmi _: Double) -> BMICategory {
        self.mockProfile?.bmiCategory ?? .normal
    }

    func calculateBMR(
        weight _: Double, height _: Double, age _: Int, gender _: Gender, unitSystem _: UnitSystem
    ) -> Double {
        self.mockProfile?.bmr ?? 0.0
    }

    func calculateTDEE(bmr _: Double, activityLevel _: Double) -> Double {
        self.mockProfile?.tdee ?? 0.0
    }

    func getSensitivityMultiplier(bmi _: Double, age _: Int) -> Double {
        self.mockProfile?.sensitivityMultiplier ?? 1.0
    }

    func getHealthRiskLevel(bmi _: Double, age _: Int) -> HealthRiskLevel {
        self.mockProfile?.riskLevel ?? .low
    }

    func getUserHealthProfile() -> UserHealthProfile? { self.mockProfile }
}

// MARK: - MockActivityDataProvider

final class MockActivityDataProvider: ActivityDataProvider {
    var stubbedActiveCalories: Double?
    var stubbedBasalCalories: Double?
    var fetchCallCount: Int = 0

    func fetchActiveCaloriesBurned(for _: Date) async -> Double? {
        self.fetchCallCount += 1
        return self.stubbedActiveCalories
    }

    func fetchBasalCaloriesBurned(for _: Date) async -> Double? {
        self.fetchCallCount += 1
        return self.stubbedBasalCalories
    }
}

// MARK: - MockInsightLifecycleService

@MainActor
final class MockInsightLifecycleService: InsightLifecycling {
    var stubbedResult: DailyInsight?
    var generateEnrichedInsightCalled = false
    var generateBriefingCalled = false

    func generateEnrichedInsight(
        for _: Date,
        synthesis _: DailySynthesis,
        recentSnapshots _: [DailySmileySnapshot],
        healthKitSleepData _: [Date: SleepData]
    ) async -> DailyInsight? {
        self.generateEnrichedInsightCalled = true
        return self.stubbedResult
    }

    func generateBriefing(
        for _: Date,
        healthKitSleepData _: [Date: SleepData]
    ) async -> DailyInsight? {
        self.generateBriefingCalled = true
        return self.stubbedResult
    }
}

// MARK: - MockDailySynthesisEngine

final class MockDailySynthesisEngine: DailySynthesizing {
    var stubbedSynthesis: DailySynthesis = .init(
        dimensions: .neutral,
        dataCompleteness: [],
        textSignals: [.neutral],
        smileySuggestion: .neutral,
        dominantDimension: .physicalLoad,
        causalNarrative: "Mock narrative"
    )
    var synthesizeCalled = false

    func synthesize(
        meals _: [Meal],
        highlightData _: HighlightData?,
        reflectData _: ReflectData?,
        appleSleepData _: SleepData?,
        yesterday _: DailySmileySnapshot?
    ) -> DailySynthesis {
        self.synthesizeCalled = true
        return self.stubbedSynthesis
    }
}

// MARK: - MockTextSignalExtractor

final class MockTextSignalExtractor: TextSignalExtracting {
    var stubbedSignals: [TextSignal] = [.neutral]
    var stubbedClarityScore: Double = 0.5
    var stubbedSentimentScore: Double = 0.5
    var lastExtractedText: String?
    var lastContext: TextContext?

    func extractSignals(from text: String, context: TextContext) -> [TextSignal] {
        self.lastExtractedText = text
        self.lastContext = context
        return self.stubbedSignals
    }

    func clarityScore(from morningThoughts: String) -> Double {
        self.lastExtractedText = morningThoughts
        return self.stubbedClarityScore
    }

    func sentimentScore(from journalText: String) -> Double {
        self.lastExtractedText = journalText
        return self.stubbedSentimentScore
    }
}
