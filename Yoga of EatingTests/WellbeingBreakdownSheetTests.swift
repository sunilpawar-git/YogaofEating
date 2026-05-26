import XCTest

@testable import Yoga_of_Eating

@MainActor
final class WellbeingBreakdownSheetTests: XCTestCase {
    var sut: MainViewModel!
    var mockHistorical: MockHistoricalDataService!
    var mockPersistence: MockPersistenceService!
    var mockLogic: MockMealLogicService!

    override func setUp() {
        super.setUp()
        self.mockHistorical = MockHistoricalDataService()
        self.mockPersistence = MockPersistenceService()
        self.mockLogic = MockMealLogicService()
        self.sut = MainViewModel(
            logicService: self.mockLogic,
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            skipDataLoading: true
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockHistorical = nil
        self.mockPersistence = nil
        self.mockLogic = nil
        super.tearDown()
    }

    // MARK: - Contract Availability

    func test_wellbeingBreakdownContract_isNilWhenNoMeals_viewingToday() {
        // No meals + viewing today — contract is nil (requires at least one meal)
        XCTAssertNil(self.sut.wellbeingBreakdownContract)
    }

    func test_wellbeingBreakdownContract_isNotNilWithMealsToday() {
        self.sut.meals = [MealBuilder().build()]
        XCTAssertNotNil(self.sut.wellbeingBreakdownContract)
    }

    func test_wellbeingBreakdownContract_isNilWhenNotViewingToday() {
        self.sut.meals = [MealBuilder().build()]
        // Navigate to yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        self.sut.selectedDate = yesterday
        XCTAssertNil(self.sut.wellbeingBreakdownContract)
    }

    // MARK: - Contract Contents

    func test_wellbeingBreakdownContract_containsDimensions() {
        self.sut.meals = [MealBuilder().build()]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertNotNil(contract?.dimensions)
    }

    func test_wellbeingBreakdownContract_containsDominantDimension() {
        self.sut.meals = [MealBuilder().build()]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertNotNil(contract?.dominantDimension)
    }

    func test_wellbeingBreakdownContract_containsCausalNarrative() {
        self.sut.meals = [MealBuilder().build()]
        guard let contract = self.sut.wellbeingBreakdownContract else {
            return XCTFail("Expected non-nil contract")
        }
        XCTAssertFalse(contract.causalNarrative.isEmpty)
    }

    func test_wellbeingBreakdownContract_weakDimensionsAtMostTwo() {
        self.sut.meals = [MealBuilder().build()]
        guard let contract = self.sut.wellbeingBreakdownContract else {
            return XCTFail("Expected non-nil contract")
        }
        XCTAssertLessThanOrEqual(contract.weakDimensions.count, 2)
    }

    func test_wellbeingBreakdownContract_weakDimensionsAllBelowNeutralThreshold() {
        self.sut.meals = [MealBuilder().build()]
        guard let contract = self.sut.wellbeingBreakdownContract else { return }
        for dim in contract.weakDimensions {
            let value = dim.value(in: contract.dimensions)
            XCTAssertLessThan(
                value,
                SynthesisThresholds.weakDimension,
                "\(dim.displayName) (\(value)) should be below weak-dimension threshold"
            )
        }
    }

    // MARK: - Current Mood & Overall Score (Phase 1)

    func test_contract_includesCurrentMood() {
        self.sut.meals = [MealBuilder().build()]
        XCTAssertNotNil(self.sut.wellbeingBreakdownContract?.currentMood)
    }

    func test_contract_includesOverallScore() {
        self.sut.meals = [MealBuilder().build()]
        let score = self.sut.wellbeingBreakdownContract?.overallScore
        XCTAssertNotNil(score)
        if let score {
            XCTAssertTrue((0.0...1.0).contains(score), "overallScore \(score) must be in [0,1]")
        }
    }

    func test_contract_sereneState_overallScoreAbove065() {
        self.sut.meals = [
            MealBuilder().withScore(0.9).analyzed().build(),
            MealBuilder().withScore(0.9).analyzed().build(),
            MealBuilder().withScore(0.9).analyzed().build()
        ]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertEqual(contract?.currentMood, .serene)
        XCTAssertGreaterThan(contract?.overallScore ?? 0, SynthesisThresholds.overallHealthy)
    }

    func test_contract_overwhelmedState_overallScoreBelow035() {
        self.sut.meals = [
            MealBuilder().withScore(0.1).analyzed().build(),
            MealBuilder().withScore(0.1).analyzed().build(),
            MealBuilder().withScore(0.1).analyzed().build()
        ]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertEqual(contract?.currentMood, .overwhelmed)
        XCTAssertLessThan(contract?.overallScore ?? 1, SynthesisThresholds.overallThoughtful)
    }

    // MARK: - SmileyMood Display Properties (Phase 1)

    func test_smileyMood_allCases_haveNonEmptyDisplayName() {
        for mood in SmileyMood.allCases {
            XCTAssertFalse(mood.displayName.isEmpty, "\(mood) displayName must not be empty")
        }
    }

    func test_smileyMood_allCases_haveNonEmptyTagline() {
        for mood in SmileyMood.allCases {
            XCTAssertFalse(mood.tagline.isEmpty, "\(mood) tagline must not be empty")
        }
    }

    func test_smileyMood_allCases_haveNonEmptyEmoji() {
        for mood in SmileyMood.allCases {
            XCTAssertFalse(mood.emoji.isEmpty, "\(mood) emoji must not be empty")
        }
    }

    func test_smileyMood_serene_emoji_isCorrect() {
        XCTAssertEqual(SmileyMood.serene.emoji, "🙂")
    }

    func test_smileyMood_neutral_emoji_isCorrect() {
        XCTAssertEqual(SmileyMood.neutral.emoji, "😐")
    }

    func test_smileyMood_overwhelmed_emoji_isCorrect() {
        XCTAssertEqual(SmileyMood.overwhelmed.emoji, "😮")
    }

    // MARK: - Data Isolation (Structural)

    func test_wellbeingBreakdownSheetContract_equatable() {
        let a = WellbeingBreakdownSheetContract(
            dimensions: .neutral,
            dominantDimension: .physicalLoad,
            causalNarrative: "test",
            weakDimensions: [.emotionalTone],
            mealCount: 2,
            currentMood: .neutral,
            overallScore: 0.5
        )
        let b = WellbeingBreakdownSheetContract(
            dimensions: .neutral,
            dominantDimension: .physicalLoad,
            causalNarrative: "test",
            weakDimensions: [.emotionalTone],
            mealCount: 2,
            currentMood: .neutral,
            overallScore: 0.5
        )
        XCTAssertEqual(a, b)
    }

    // MARK: - Breakdown Sheet Toggle (fallback path — no fresh insight)

    func test_handleSmileyLongPress_noInsightToday_withMeals_fallsBackToBreakdownSheet() {
        // No fresh today insight → breakdown sheet is the fallback (not primary path)
        self.sut.currentInsight = nil
        self.sut.meals = [MealBuilder().build()]
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showBreakdownSheet)
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    func test_handleSmileyLongPress_noInsightToday_noMeals_fallsBackToBreakdownSheet() {
        // No fresh today insight, no meals, viewing today → breakdown sheet fallback still opens
        self.sut.currentInsight = nil
        self.sut.handleSmileyLongPress()
        XCTAssertTrue(self.sut.showBreakdownSheet)
        XCTAssertFalse(self.sut.showInsightSheet)
    }

    // MARK: - Weak Dimensions (Phase 3)

    func test_worthNurturing_stringIsUsed_notOldNeedsAttention() {
        XCTAssertFalse(
            Strings.WellbeingBreakdown.worthNurturing.isEmpty,
            "worthNurturing must be a non-empty string"
        )
        // The warm label must not say "Needs attention" — that's the old cold tone
        XCTAssertFalse(
            Strings.WellbeingBreakdown.worthNurturing.lowercased().contains("needs attention"),
            "Coach label must not use the old 'Needs attention' phrasing"
        )
    }

    func test_contract_weakDimensions_nonEmptyWhenDimensionsLow() {
        // Set meals with very low scores — physical will be low
        self.sut.meals = [
            MealBuilder().withScore(0.1).analyzed().build(),
            MealBuilder().withScore(0.1).analyzed().build()
        ]
        let contract = self.sut.wellbeingBreakdownContract
        XCTAssertFalse(
            contract?.weakDimensions.isEmpty ?? true,
            "Low-scored meals should produce at least one weak dimension"
        )
    }

    // MARK: - Warmer Causal Narratives (Phase 3)

    func test_narrative_physical_low_hasWarmBodyLanguage() {
        XCTAssertTrue(
            Strings.Synthesis.CausalNarrative.physical_low_fmt.contains("your body"),
            "Physical-low narrative must use warm 'your body' language"
        )
    }

    func test_narrative_physical_high_hasWarmLiftingLanguage() {
        XCTAssertTrue(
            Strings.Synthesis.CausalNarrative.physical_high_fmt.contains("lifting"),
            "Physical-high narrative must use warm 'lifting' language"
        )
    }

    func test_narrative_emotional_low_hasGraceLanguage() {
        XCTAssertTrue(
            Strings.Synthesis.CausalNarrative.emotional_low.contains("grace"),
            "Emotional-low narrative must offer grace/compassion"
        )
    }

    func test_narrative_emotional_high_hasBrighteningLanguage() {
        XCTAssertTrue(
            Strings.Synthesis.CausalNarrative.emotional_high.contains("brightening"),
            "Emotional-high narrative must feel celebratory"
        )
    }

    func test_narrative_cognitive_low_hasGentleLanguage() {
        XCTAssertTrue(
            Strings.Synthesis.CausalNarrative.cognitive_low.contains("gentle"),
            "Cognitive-low narrative must offer gentleness"
        )
    }

    func test_narrative_behavioral_low_hasEncouragingLanguage() {
        XCTAssertTrue(
            Strings.Synthesis.CausalNarrative.behavioral_low.contains("okay"),
            "Behavioral-low narrative must be encouraging, not punishing"
        )
    }
}
