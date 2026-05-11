// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for DailyBriefing, CorrelationCard, ActionableNudge, and CorrelationCategory models.
    /// TDD Phase: RED — these tests are written before the production models exist.
    @MainActor
    final class DailyBriefingTests: XCTestCase {
        // MARK: - Properties

        var testDate: Date!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.testDate = Date()
        }

        override func tearDown() {
            self.testDate = nil
            super.tearDown()
        }

        // MARK: - CorrelationCategory Tests

        func test_correlationCategory_hasExpectedCases() {
            let allCases = CorrelationCategory.allCases
            XCTAssertEqual(allCases.count, 10) // 5 original + 5 synthesis-aware (Phase 4)
            XCTAssertTrue(allCases.contains(.foodToSleep))
            XCTAssertTrue(allCases.contains(.foodToMood))
            XCTAssertTrue(allCases.contains(.focusToFeeling))
            XCTAssertTrue(allCases.contains(.timingPattern))
            XCTAssertTrue(allCases.contains(.foodDebt))
        }

        func test_correlationCategory_rawValues_areStable() {
            XCTAssertEqual(CorrelationCategory.foodToSleep.rawValue, "foodToSleep")
            XCTAssertEqual(CorrelationCategory.foodToMood.rawValue, "foodToMood")
            XCTAssertEqual(CorrelationCategory.focusToFeeling.rawValue, "focusToFeeling")
            XCTAssertEqual(CorrelationCategory.timingPattern.rawValue, "timingPattern")
        }

        func test_correlationCategory_icon_returnsValidSFSymbol() {
            for category in CorrelationCategory.allCases {
                XCTAssertFalse(category.icon.isEmpty, "Icon should not be empty for \(category)")
            }
        }

        func test_correlationCategory_displayName_returnsHumanReadable() {
            XCTAssertEqual(CorrelationCategory.foodToSleep.displayName, "Food & Sleep")
            XCTAssertEqual(CorrelationCategory.foodToMood.displayName, "Food & Mood")
            XCTAssertEqual(CorrelationCategory.focusToFeeling.displayName, "Focus & Feeling")
            XCTAssertEqual(CorrelationCategory.timingPattern.displayName, "Timing Pattern")
        }

        func test_correlationCategory_codable_roundTrips() throws {
            for category in CorrelationCategory.allCases {
                let data = try JSONEncoder().encode(category)
                let decoded = try JSONDecoder().decode(CorrelationCategory.self, from: data)
                XCTAssertEqual(decoded, category)
            }
        }

        // MARK: - CorrelationCard Tests

        func test_correlationCard_init_setsAllProperties() {
            let id = UUID()
            let ref = InsightReference(date: self.testDate, description: "Late dinner", category: .food)

            let card = CorrelationCard(
                id: id,
                category: .foodToSleep,
                observation: "High-protein lunch -> 30% better afternoon focus",
                confidence: 0.85,
                dataPoints: [ref]
            )

            XCTAssertEqual(card.id, id)
            XCTAssertEqual(card.category, .foodToSleep)
            XCTAssertEqual(card.observation, "High-protein lunch -> 30% better afternoon focus")
            XCTAssertEqual(card.confidence, 0.85)
            XCTAssertEqual(card.dataPoints.count, 1)
        }

        func test_correlationCard_confidence_isClamped() {
            let over = CorrelationCard(
                category: .foodToMood,
                observation: "Test",
                confidence: 1.5,
                dataPoints: []
            )
            XCTAssertEqual(over.confidence, 1.0, "Confidence above 1.0 should be clamped")

            let under = CorrelationCard(
                category: .foodToMood,
                observation: "Test",
                confidence: -0.5,
                dataPoints: []
            )
            XCTAssertEqual(under.confidence, 0.0, "Confidence below 0.0 should be clamped")
        }

        func test_correlationCard_isHighConfidence() {
            let high = CorrelationCard(
                category: .foodToSleep,
                observation: "Test",
                confidence: 0.8,
                dataPoints: []
            )
            XCTAssertTrue(high.isHighConfidence)

            let low = CorrelationCard(
                category: .foodToSleep,
                observation: "Test",
                confidence: 0.5,
                dataPoints: []
            )
            XCTAssertFalse(low.isHighConfidence)
        }

        func test_correlationCard_codable_roundTrips() throws {
            let card = CorrelationCard(
                category: .timingPattern,
                observation: "Eating earlier correlates with better sleep",
                confidence: 0.72,
                dataPoints: [
                    InsightReference(date: self.testDate, description: "Early dinner", category: .food)
                ]
            )

            let data = try JSONEncoder().encode(card)
            let decoded = try JSONDecoder().decode(CorrelationCard.self, from: data)

            XCTAssertEqual(decoded.id, card.id)
            XCTAssertEqual(decoded.category, card.category)
            XCTAssertEqual(decoded.observation, card.observation)
            XCTAssertEqual(decoded.confidence, card.confidence, accuracy: 0.001)
            XCTAssertEqual(decoded.dataPoints.count, 1)
        }

        func test_correlationCard_equatable() {
            let id = UUID()
            let card1 = CorrelationCard(
                id: id,
                category: .foodToMood,
                observation: "Test",
                confidence: 0.8,
                dataPoints: []
            )
            let card2 = CorrelationCard(
                id: id,
                category: .foodToMood,
                observation: "Test",
                confidence: 0.8,
                dataPoints: []
            )
            XCTAssertEqual(card1, card2)
        }

        // MARK: - ActionableNudge Tests

        func test_actionableNudge_init_setsAllProperties() {
            let nudge = ActionableNudge(
                suggestion: "Try repeating Tuesday's lunch today",
                reasoning: "It correlated with your best afternoon this week",
                relatedMeal: "Grilled chicken salad"
            )

            XCTAssertEqual(nudge.suggestion, "Try repeating Tuesday's lunch today")
            XCTAssertEqual(nudge.reasoning, "It correlated with your best afternoon this week")
            XCTAssertEqual(nudge.relatedMeal, "Grilled chicken salad")
        }

        func test_actionableNudge_relatedMeal_isOptional() {
            let nudge = ActionableNudge(
                suggestion: "Finish dinner earlier",
                reasoning: "Late meals affect your sleep"
            )
            XCTAssertNil(nudge.relatedMeal)
        }

        func test_actionableNudge_codable_roundTrips() throws {
            let nudge = ActionableNudge(
                suggestion: "Eat more protein at lunch",
                reasoning: "Protein lunches improve your afternoon focus",
                relatedMeal: "Chicken wrap"
            )

            let data = try JSONEncoder().encode(nudge)
            let decoded = try JSONDecoder().decode(ActionableNudge.self, from: data)

            XCTAssertEqual(decoded.suggestion, nudge.suggestion)
            XCTAssertEqual(decoded.reasoning, nudge.reasoning)
            XCTAssertEqual(decoded.relatedMeal, nudge.relatedMeal)
        }

        func test_actionableNudge_codable_withNilRelatedMeal() throws {
            let nudge = ActionableNudge(
                suggestion: "Rest well tonight",
                reasoning: "You've had a busy week"
            )

            let data = try JSONEncoder().encode(nudge)
            let decoded = try JSONDecoder().decode(ActionableNudge.self, from: data)

            XCTAssertNil(decoded.relatedMeal)
        }

        func test_actionableNudge_equatable() {
            let nudge1 = ActionableNudge(
                suggestion: "Test",
                reasoning: "Reason",
                relatedMeal: "Salad"
            )
            let nudge2 = ActionableNudge(
                suggestion: "Test",
                reasoning: "Reason",
                relatedMeal: "Salad"
            )
            XCTAssertEqual(nudge1, nudge2)
        }

        // MARK: - WeeklyTrendSnippet Tests

        func test_weeklyTrendSnippet_init_setsProperties() {
            let snippet = WeeklyTrendSnippet(
                averageFoodScore: 0.72,
                averageSleepQuality: 0.65,
                daysLogged: 5,
                trendDirection: .improving
            )

            XCTAssertEqual(snippet.averageFoodScore, 0.72)
            XCTAssertEqual(snippet.averageSleepQuality, 0.65)
            XCTAssertEqual(snippet.daysLogged, 5)
            XCTAssertEqual(snippet.trendDirection, .improving)
        }

        func test_weeklyTrendSnippet_trendDirection_hasCases() {
            let cases = TrendDirection.allCases
            XCTAssertEqual(cases.count, 3)
            XCTAssertTrue(cases.contains(.improving))
            XCTAssertTrue(cases.contains(.declining))
            XCTAssertTrue(cases.contains(.steady))
        }

        func test_weeklyTrendSnippet_codable_roundTrips() throws {
            let snippet = WeeklyTrendSnippet(
                averageFoodScore: 0.8,
                averageSleepQuality: 0.7,
                daysLogged: 7,
                trendDirection: .steady
            )

            let data = try JSONEncoder().encode(snippet)
            let decoded = try JSONDecoder().decode(WeeklyTrendSnippet.self, from: data)

            XCTAssertEqual(decoded.averageFoodScore, snippet.averageFoodScore, accuracy: 0.001)
            XCTAssertEqual(decoded.trendDirection, snippet.trendDirection)
        }

        // MARK: - DailyBriefing Tests

        func test_dailyBriefing_init_setsAllProperties() {
            let id = UUID()
            let card = CorrelationCard(
                category: .foodToSleep,
                observation: "Test observation",
                confidence: 0.8,
                dataPoints: []
            )
            let nudge = ActionableNudge(
                suggestion: "Try this",
                reasoning: "Because that"
            )

            let briefing = DailyBriefing(
                id: id,
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Your Tuesday in 10 words",
                correlationCards: [card],
                nudge: nudge,
                weeklyTrend: nil,
                isViewed: false
            )

            XCTAssertEqual(briefing.id, id)
            XCTAssertEqual(briefing.headline, "Your Tuesday in 10 words")
            XCTAssertEqual(briefing.correlationCards.count, 1)
            XCTAssertEqual(briefing.nudge.suggestion, "Try this")
            XCTAssertNil(briefing.weeklyTrend)
            XCTAssertFalse(briefing.isViewed)
        }

        func test_dailyBriefing_isViewed_defaultsToFalse() {
            let briefing = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Test",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "S", reasoning: "R")
            )
            XCTAssertFalse(briefing.isViewed)
        }

        func test_dailyBriefing_markAsViewed_updatesFlag() {
            var briefing = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Test",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "S", reasoning: "R")
            )

            briefing.markAsViewed()
            XCTAssertTrue(briefing.isViewed)
        }

        func test_dailyBriefing_hasCorrelations_reflectsCardCount() {
            let empty = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Test",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "S", reasoning: "R")
            )
            XCTAssertFalse(empty.hasCorrelations)

            let withCards = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Test",
                correlationCards: [
                    CorrelationCard(category: .foodToMood, observation: "O", confidence: 0.7, dataPoints: [])
                ],
                nudge: ActionableNudge(suggestion: "S", reasoning: "R")
            )
            XCTAssertTrue(withCards.hasCorrelations)
        }

        func test_dailyBriefing_topCorrelation_returnsHighestConfidence() {
            let low = CorrelationCard(category: .foodToMood, observation: "Low", confidence: 0.5, dataPoints: [])
            let high = CorrelationCard(category: .foodToSleep, observation: "High", confidence: 0.9, dataPoints: [])
            let mid = CorrelationCard(category: .timingPattern, observation: "Mid", confidence: 0.7, dataPoints: [])

            let briefing = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Test",
                correlationCards: [low, high, mid],
                nudge: ActionableNudge(suggestion: "S", reasoning: "R")
            )

            XCTAssertEqual(briefing.topCorrelation?.observation, "High")
        }

        func test_dailyBriefing_topCorrelation_returnsNil_whenEmpty() {
            let briefing = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Test",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "S", reasoning: "R")
            )
            XCTAssertNil(briefing.topCorrelation)
        }

        // MARK: - DailyBriefing Codable

        func test_dailyBriefing_codable_roundTrips() throws {
            let card = CorrelationCard(
                category: .foodToSleep,
                observation: "Late dinners correlate with poor sleep",
                confidence: 0.85,
                dataPoints: [
                    InsightReference(date: self.testDate, description: "Late dinner at 10pm", category: .food)
                ]
            )
            let nudge = ActionableNudge(
                suggestion: "Try eating dinner before 8pm",
                reasoning: "Earlier dinners improve your sleep quality",
                relatedMeal: "Light soup"
            )
            let trend = WeeklyTrendSnippet(
                averageFoodScore: 0.72,
                averageSleepQuality: 0.68,
                daysLogged: 6,
                trendDirection: .improving
            )

            let briefing = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Tuesday: Protein lunch powered your afternoon",
                correlationCards: [card],
                nudge: nudge,
                weeklyTrend: trend,
                isViewed: false
            )

            let data = try JSONEncoder().encode(briefing)
            let decoded = try JSONDecoder().decode(DailyBriefing.self, from: data)

            XCTAssertEqual(decoded.id, briefing.id)
            XCTAssertEqual(decoded.headline, briefing.headline)
            XCTAssertEqual(decoded.correlationCards.count, 1)
            XCTAssertEqual(decoded.correlationCards.first?.category, .foodToSleep)
            XCTAssertEqual(decoded.nudge.suggestion, nudge.suggestion)
            XCTAssertEqual(decoded.nudge.relatedMeal, "Light soup")
            XCTAssertNotNil(decoded.weeklyTrend)
            XCTAssertEqual(decoded.weeklyTrend?.trendDirection, .improving)
            XCTAssertFalse(decoded.isViewed)
        }

        func test_dailyBriefing_codable_withNilWeeklyTrend() throws {
            let briefing = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Test",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "S", reasoning: "R"),
                weeklyTrend: nil
            )

            let data = try JSONEncoder().encode(briefing)
            let decoded = try JSONDecoder().decode(DailyBriefing.self, from: data)

            XCTAssertNil(decoded.weeklyTrend)
        }

        // MARK: - DailyBriefing Equatable

        func test_dailyBriefing_equatable_identicalAreEqual() {
            let id = UUID()
            let nudge = ActionableNudge(suggestion: "S", reasoning: "R")
            let b1 = DailyBriefing(
                id: id, date: self.testDate, generatedAt: self.testDate,
                headline: "H", correlationCards: [], nudge: nudge
            )
            let b2 = DailyBriefing(
                id: id, date: self.testDate, generatedAt: self.testDate,
                headline: "H", correlationCards: [], nudge: nudge
            )
            XCTAssertEqual(b1, b2)
        }

        func test_dailyBriefing_equatable_differentIdsNotEqual() {
            let nudge = ActionableNudge(suggestion: "S", reasoning: "R")
            let b1 = DailyBriefing(
                date: self.testDate, generatedAt: self.testDate,
                headline: "H", correlationCards: [], nudge: nudge
            )
            let b2 = DailyBriefing(
                date: self.testDate, generatedAt: self.testDate,
                headline: "H", correlationCards: [], nudge: nudge
            )
            XCTAssertNotEqual(b1, b2)
        }

        // MARK: - Security: Data Isolation

        func test_dailyBriefing_doesNotExposeRawMealData() {
            let briefing = DailyBriefing(
                date: self.testDate,
                generatedAt: self.testDate,
                headline: "Test",
                correlationCards: [],
                nudge: ActionableNudge(suggestion: "S", reasoning: "R")
            )

            let mirror = Mirror(reflecting: briefing)
            let propertyNames = mirror.children.compactMap(\.label)

            XCTAssertFalse(propertyNames.contains("meals"), "Briefing must not contain raw meal data")
            XCTAssertFalse(propertyNames.contains("journalText"), "Briefing must not contain raw journal text")
            XCTAssertFalse(propertyNames.contains("sleepData"), "Briefing must not contain raw sleep data")
        }
    }
#endif
