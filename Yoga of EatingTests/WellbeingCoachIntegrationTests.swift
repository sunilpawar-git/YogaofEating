import XCTest

@testable import Yoga_of_Eating

/// Integration tests for the full coach pipeline:
/// real meals → DailySynthesisEngine → WellbeingBreakdownSheetContract → WellbeingProgressCalculator.
/// Uses real DailySynthesisEngine (no mocks for synthesis), MainViewModel with skipDataLoading.
@MainActor
final class WellbeingCoachIntegrationTests: XCTestCase {
    var sut: MainViewModel!
    var engine: DailySynthesisEngine!

    override func setUp() {
        super.setUp()
        self.engine = DailySynthesisEngine()
        self.sut = MainViewModel(
            logicService: MockMealLogicService(),
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService(),
            skipDataLoading: true
        )
    }

    override func tearDown() {
        self.sut = nil
        self.engine = nil
        super.tearDown()
    }

    // MARK: - Mood resolution end-to-end

    func test_integration_highScoredMeals_contractMoodIsSerene() {
        self.sut.meals = (0..<3).map { _ in MealBuilder().withScore(0.9).analyzed().build() }
        XCTAssertEqual(self.sut.wellbeingBreakdownContract?.currentMood, .serene)
    }

    func test_integration_lowScoredMeals_contractMoodIsOverwhelmed() {
        self.sut.meals = (0..<3).map { _ in MealBuilder().withScore(0.1).analyzed().build() }
        XCTAssertEqual(self.sut.wellbeingBreakdownContract?.currentMood, .overwhelmed)
    }

    func test_integration_midScoredMeals_contractMoodIsNeutralOrThoughtful() {
        self.sut.meals = (0..<3).map { _ in MealBuilder().withScore(0.5).analyzed().build() }
        let mood = self.sut.wellbeingBreakdownContract?.currentMood
        XCTAssertTrue(
            mood == .neutral || mood == .thoughtful,
            "Mid-scored meals should produce neutral or thoughtful, got: \(String(describing: mood))"
        )
    }

    // MARK: - Overall score range

    func test_integration_overallScoreIsInUnitRange() {
        self.sut.meals = [MealBuilder().withScore(0.6).analyzed().build()]
        guard let contract = self.sut.wellbeingBreakdownContract else {
            return XCTFail("Expected non-nil contract with 1 meal")
        }
        XCTAssertTrue(
            (0.0...1.0).contains(contract.overallScore),
            "overallScore \(contract.overallScore) must be in [0, 1]"
        )
    }

    func test_integration_highMeals_overallScoreAboveSereneThreshold() {
        self.sut.meals = (0..<3).map { _ in MealBuilder().withScore(0.9).analyzed().build() }
        let score = self.sut.wellbeingBreakdownContract?.overallScore ?? 0
        XCTAssertGreaterThan(score, SynthesisThresholds.overallHealthy)
    }

    func test_integration_lowMeals_overallScoreBelowThoughtfulThreshold() {
        self.sut.meals = (0..<3).map { _ in MealBuilder().withScore(0.1).analyzed().build() }
        let score = self.sut.wellbeingBreakdownContract?.overallScore ?? 1
        XCTAssertLessThan(score, SynthesisThresholds.overallThoughtful)
    }

    // MARK: - Contract nil guard

    func test_integration_noMeals_contractIsNil() {
        self.sut.meals = []
        XCTAssertNil(self.sut.wellbeingBreakdownContract)
    }

    func test_integration_pastDate_contractIsNil() {
        self.sut.meals = [MealBuilder().build()]
        self.sut.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertNil(self.sut.wellbeingBreakdownContract)
    }

    // MARK: - Progress text pipeline

    func test_integration_serene_progressTextIsNil() {
        self.sut.meals = (0..<3).map { _ in MealBuilder().withScore(0.9).analyzed().build() }
        guard let contract = self.sut.wellbeingBreakdownContract else {
            return XCTFail("Expected non-nil contract")
        }
        XCTAssertNil(WellbeingProgressCalculator.progressText(
            mood: contract.currentMood,
            overall: contract.overallScore
        ))
    }

    func test_integration_overwhelmed_progressTextIsNonNilAndContainsThoughtful() {
        self.sut.meals = (0..<3).map { _ in MealBuilder().withScore(0.1).analyzed().build() }
        guard let contract = self.sut.wellbeingBreakdownContract else {
            return XCTFail("Expected non-nil contract")
        }
        let text = WellbeingProgressCalculator.progressText(
            mood: contract.currentMood,
            overall: contract.overallScore
        )
        XCTAssertNotNil(text)
        XCTAssertTrue(
            text?.contains(SmileyMood.thoughtful.displayName) == true,
            "Overwhelmed progress text must name Thoughtful as next state"
        )
    }

    func test_integration_weakDimensions_populatedFromLowPhysicalScore() {
        self.sut.meals = (0..<3).map { _ in MealBuilder().withScore(0.1).analyzed().build() }
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertFalse(
            contract?.weakDimensions.isEmpty ?? true,
            "Low-score meals should populate weakDimensions"
        )
        XCTAssertTrue(
            contract?.weakDimensions.contains(.physicalLoad) == true,
            "Physical must be in weak dims when meal scores are very low"
        )
    }

    // MARK: - SynthesisInputBuilder cross-check

    func test_integration_synthesisDirect_highMeals_smileySuggestionSerene() {
        let synthesis = SynthesisInputBuilder().withMeals(3, avgScore: 0.9).synthesize(with: self.engine)
        XCTAssertEqual(synthesis.smileySuggestion.mood, .serene)
    }

    func test_integration_synthesisDirect_lowMeals_smileySuggestionOverwhelmed() {
        let synthesis = SynthesisInputBuilder().withMeals(3, avgScore: 0.1).synthesize(with: self.engine)
        XCTAssertEqual(synthesis.smileySuggestion.mood, .overwhelmed)
    }

    func test_integration_synthesisDirect_overallMatchesContractOverallScore() {
        let meals = (0..<3).map { _ in MealBuilder().withScore(0.7).analyzed().build() }
        self.sut.meals = meals
        let synthesis = SynthesisInputBuilder().withMeals(meals).synthesize(with: self.engine)
        guard let contract = self.sut.wellbeingBreakdownContract else {
            return XCTFail("Contract must not be nil with meals")
        }
        XCTAssertEqual(contract.overallScore, synthesis.overall, accuracy: 0.001)
    }
}
