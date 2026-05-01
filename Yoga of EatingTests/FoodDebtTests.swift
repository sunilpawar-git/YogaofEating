// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// TDD tests for the food-debt feature.
    /// Feature: 2 consecutive days with averageHealthScore < ScoringThresholds.foodDebtBadDay
    /// causes the smiley to start as .concerned on the next day, and generates a
    /// CorrelationCard (category: .foodDebt) in the morning briefing.
    @MainActor
    final class FoodDebtTests: XCTestCase {
        // MARK: - Properties

        private var sut: HistoricalDataService!
        private var mockPersistence: MockPersistenceService!
        private var mockAuth: MockAuthService!
        private var mockSync: MockCloudSyncService!
        private var analyzer: PatternAnalyzer!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockPersistence = MockPersistenceService()
            self.mockAuth = MockAuthService()
            self.mockSync = MockCloudSyncService()
            self.sut = HistoricalDataService(
                persistenceService: self.mockPersistence,
                authService: self.mockAuth,
                syncService: self.mockSync
            )
            self.analyzer = PatternAnalyzer()
        }

        override func tearDown() {
            self.sut = nil
            self.mockPersistence = nil
            self.mockAuth = nil
            self.mockSync = nil
            self.analyzer = nil
            super.tearDown()
        }

        // MARK: - SmileyMood.concerned codable

        func test_smileyMood_concerned_codableRoundTrip() throws {
            let state = SmileyState(scale: 1.1, mood: .concerned)
            let encoded = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(SmileyState.self, from: encoded)
            XCTAssertEqual(decoded.mood, .concerned)
            XCTAssertEqual(decoded.scale, 1.1, accuracy: 0.001)
        }

        func test_smileyState_concerned_staticProperty_hasConcernedMood() {
            XCTAssertEqual(SmileyState.concerned.mood, .concerned)
            XCTAssertEqual(SmileyState.concerned.scale, 1.1, accuracy: 0.001)
        }

        // MARK: - HistoricalDataService.foodDebtStartingState tests

        func test_foodDebtState_twoBadDays_returnsConcerned() {
            self.seedSnapshot(daysAgo: 1, averageScore: 0.30, mealCount: 2)
            self.seedSnapshot(daysAgo: 2, averageScore: 0.25, mealCount: 3)

            let state = self.sut.foodDebtStartingState(relativeTo: Date())

            XCTAssertEqual(state.mood, .concerned, "Two consecutive bad days should return .concerned")
        }

        func test_foodDebtState_oneBadDay_returnsNeutral() {
            self.seedSnapshot(daysAgo: 1, averageScore: 0.30, mealCount: 2)
            self.seedSnapshot(daysAgo: 2, averageScore: 0.80, mealCount: 2) // good day

            let state = self.sut.foodDebtStartingState(relativeTo: Date())

            XCTAssertEqual(state.mood, .neutral, "One bad day is not enough to trigger food debt")
        }

        func test_foodDebtState_twoBadDaysOneWithNoMeals_returnsNeutral() {
            self.seedSnapshot(daysAgo: 1, averageScore: 0.30, mealCount: 0) // no meals logged
            self.seedSnapshot(daysAgo: 2, averageScore: 0.25, mealCount: 2)

            let state = self.sut.foodDebtStartingState(relativeTo: Date())

            XCTAssertEqual(
                state.mood, .neutral,
                "A day with no meals logged should not count as a bad day"
            )
        }

        func test_foodDebtState_noHistoricalData_returnsNeutral() {
            // No snapshots seeded
            let state = self.sut.foodDebtStartingState(relativeTo: Date())
            XCTAssertEqual(state.mood, .neutral)
        }

        func test_foodDebtState_twoBadDaysAtThreshold_returnsNeutral() {
            // Exactly at threshold (not strictly below) — should NOT trigger
            let threshold = ScoringThresholds.foodDebtBadDay
            self.seedSnapshot(daysAgo: 1, averageScore: threshold, mealCount: 2)
            self.seedSnapshot(daysAgo: 2, averageScore: threshold, mealCount: 2)

            let state = self.sut.foodDebtStartingState(relativeTo: Date())

            XCTAssertEqual(state.mood, .neutral, "Exactly at threshold is not below it — no food debt")
        }

        // MARK: - MainViewModel resetDay food debt integration

        func test_resetDay_twoBadDays_smileyConcerned() {
            let mockHistorical = MockHistoricalDataService()

            // Seed 2 bad days
            let d1 = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let d2 = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            mockHistorical.historicalData.addOrUpdate(snapshot: self.makeSnapshot(on: d1, score: 0.25, mealCount: 2))
            mockHistorical.historicalData.addOrUpdate(snapshot: self.makeSnapshot(on: d2, score: 0.30, mealCount: 2))

            let vm = MainViewModel(historicalService: mockHistorical, skipDataLoading: true)
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            vm.lastResetDate = yesterday

            vm.resetDay()

            XCTAssertEqual(
                vm.smileyState.mood,
                .concerned,
                "After resetDay with 2 bad days, smiley should be .concerned"
            )
        }

        func test_resetDay_oneBadDay_smileyNeutral() {
            let mockHistorical = MockHistoricalDataService()

            let d1 = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let d2 = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            mockHistorical.historicalData.addOrUpdate(snapshot: self.makeSnapshot(on: d1, score: 0.25, mealCount: 2))
            mockHistorical.historicalData.addOrUpdate(snapshot: self.makeSnapshot(
                on: d2,
                score: 0.85,
                mealCount: 2
            )) // good

            let vm = MainViewModel(historicalService: mockHistorical, skipDataLoading: true)
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            vm.lastResetDate = yesterday

            vm.resetDay()

            XCTAssertEqual(vm.smileyState.mood, .neutral, "One bad day should not trigger food debt")
        }

        // MARK: - PatternAnalyzer.analyzeFoodDebt tests

        func test_patternAnalyzer_foodDebt_cardGeneratedForTwoBadDays() {
            let snapshots = [
                makeSnapshot(daysAgo: 1, score: 0.25, mealCount: 2),
                makeSnapshot(daysAgo: 2, score: 0.30, mealCount: 2),
                makeSnapshot(daysAgo: 3, score: 0.75, mealCount: 2) // older good day
            ]

            let cards = self.analyzer.analyzeFoodDebt(from: snapshots)

            XCTAssertFalse(cards.isEmpty, "Food debt card should be generated for 2 consecutive bad days")
            XCTAssertEqual(cards.first?.category, .foodDebt)
        }

        func test_patternAnalyzer_foodDebt_cardNotGeneratedForOneBadDay() {
            let snapshots = [
                makeSnapshot(daysAgo: 1, score: 0.25, mealCount: 2),
                makeSnapshot(daysAgo: 2, score: 0.80, mealCount: 2) // good
            ]

            let cards = self.analyzer.analyzeFoodDebt(from: snapshots)

            XCTAssertTrue(cards.isEmpty, "One bad day is insufficient for a food debt card")
        }

        func test_patternAnalyzer_foodDebt_cardNotGeneratedWithNoMeals() {
            let snapshots = [
                makeSnapshot(daysAgo: 1, score: 0.20, mealCount: 0), // no meals
                makeSnapshot(daysAgo: 2, score: 0.25, mealCount: 2)
            ]

            let cards = self.analyzer.analyzeFoodDebt(from: snapshots)

            XCTAssertTrue(cards.isEmpty, "Day with no meals should not count toward food debt")
        }

        func test_patternAnalyzer_foodDebt_confidenceScalesWithSeverity() {
            // Very low scores → higher confidence
            let badSnapshots = [
                makeSnapshot(daysAgo: 1, score: 0.10, mealCount: 2),
                makeSnapshot(daysAgo: 2, score: 0.10, mealCount: 2)
            ]
            // Borderline scores → lower confidence
            let borderlineSnapshots = [
                makeSnapshot(daysAgo: 1, score: 0.42, mealCount: 2),
                makeSnapshot(daysAgo: 2, score: 0.43, mealCount: 2)
            ]

            let badCards = self.analyzer.analyzeFoodDebt(from: badSnapshots)
            let borderlineCards = self.analyzer.analyzeFoodDebt(from: borderlineSnapshots)

            guard let badConf = badCards.first?.confidence,
                  let borderlineConf = borderlineCards.first?.confidence
            else {
                XCTFail("Expected food debt cards from both snap sets")
                return
            }
            XCTAssertGreaterThan(
                badConf, borderlineConf,
                "Very bad scores should produce higher confidence than borderline scores"
            )
        }

        func test_patternAnalyzer_generateCorrelationCards_includesFoodDebtWhenTriggered() {
            // 2 bad recent days + enough total snapshots to pass the minimumDataPoints guard
            let snapshots = [
                makeSnapshot(daysAgo: 1, score: 0.20, mealCount: 2),
                makeSnapshot(daysAgo: 2, score: 0.25, mealCount: 2),
                makeSnapshot(daysAgo: 3, score: 0.70, mealCount: 2)
            ]

            let cards = self.analyzer.generateCorrelationCards(from: snapshots)
            let hasDebtCard = cards.contains { $0.category == .foodDebt }

            XCTAssertTrue(hasDebtCard, "generateCorrelationCards should include food debt card when triggered")
        }

        // MARK: - Helpers

        private func seedSnapshot(daysAgo: Int, averageScore: Double, mealCount: Int) {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            self.sut.historicalData.addOrUpdate(snapshot: self.makeSnapshot(
                on: date,
                score: averageScore,
                mealCount: mealCount
            ))
        }

        private func makeSnapshot(on date: Date, score: Double, mealCount: Int) -> DailySmileySnapshot {
            let meals = (0..<mealCount).map { _ in
                Meal(mealType: .lunch, items: ["Test"], healthScore: score)
            }
            return DailySmileySnapshot(
                id: UUID(),
                date: Calendar.current.startOfDay(for: date),
                smileyState: .neutral,
                meals: meals,
                mealCount: mealCount,
                averageHealthScore: score
            )
        }

        private func makeSnapshot(daysAgo: Int, score: Double, mealCount: Int) -> DailySmileySnapshot {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            return self.makeSnapshot(on: date, score: score, mealCount: mealCount)
        }
    }
#endif
