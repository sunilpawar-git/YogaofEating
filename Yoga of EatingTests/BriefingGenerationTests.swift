// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for InsightLifecycleService.generateBriefing — replaces InsightGenerationService tests.
    @MainActor
    final class BriefingGenerationTests: XCTestCase {
        private var historicalService: MockHistoricalDataService!
        private var sut: InsightLifecycleService!

        override func setUp() {
            super.setUp()
            self.historicalService = MockHistoricalDataService()
            self.sut = InsightLifecycleService(
                historicalService: self.historicalService,
                functions: nil
            )
        }

        override func tearDown() {
            self.sut = nil
            self.historicalService = nil
            super.tearDown()
        }

        // MARK: - Guard Tests

        func test_generateBriefing_returnsNil_whenNoData() async {
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertNil(result, "Should return nil when no historical data exists")
        }

        func test_generateBriefing_returnsNil_withInsufficientData() async {
            self.seedSnapshots(count: 1)
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertNil(result, "Should return nil with fewer than 2 data points")
        }

        // MARK: - Local Fallback Tests

        func test_generateBriefing_fallsBackToLocal_whenNoFirebase() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertNotNil(result, "Should produce unified insight via local fallback")
        }

        func test_generateBriefing_localFallback_hasHeadline() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertFalse(result?.headline.isEmpty ?? true, "Headline must not be empty")
        }

        func test_generateBriefing_localFallback_hasNudge() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertNotNil(result?.nudge)
            XCTAssertFalse(result!.nudge.suggestion.isEmpty)
        }

        func test_generateBriefing_localFallback_setsDate() async {
            let today = Date()
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(
                for: today,
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertTrue(
                Calendar.current.isDate(result!.date, inSameDayAs: today),
                "Insight date should match the requested date"
            )
        }

        func test_generateBriefing_localFallback_isNotViewed() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertFalse(result?.isViewed ?? true, "New insight must not be marked as viewed")
        }

        func test_generateBriefing_confidenceIsValid() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertGreaterThanOrEqual(result?.confidence ?? -1, 0.0)
            XCTAssertLessThanOrEqual(result?.confidence ?? 2, 1.0)
        }

        // MARK: - Correlation Cards

        func test_generateBriefing_cardsClamped_0to1() async {
            self.seedCorrelatedData()
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            for card in result?.correlationCards ?? [] {
                XCTAssertGreaterThanOrEqual(card.confidence, 0.0)
                XCTAssertLessThanOrEqual(card.confidence, 1.0)
            }
        }

        // MARK: - Weekly Trend

        func test_generateBriefing_includesWeeklyTrend_withEnoughData() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertNotNil(result?.weeklyTrend, "Should compute a weekly trend from 5+ days")
        }

        func test_generateBriefing_weeklyTrend_daysLogged_matchesData() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertEqual(result?.weeklyTrend?.daysLogged, 5)
        }

        // MARK: - Persistence

        func test_generateBriefing_persistsViaUpdateInsight() async {
            self.seedSnapshots(count: 3)
            _ = await self.sut.generateBriefing(
                for: Date(),
                userContext: nil,
                nudgeHistory: [],
                healthKitSleepData: [:]
            )
            XCTAssertTrue(self.historicalService.updateInsightCalled)
        }

        // MARK: - Helpers

        private func seedSnapshots(count: Int) {
            for i in 0..<count {
                let score = Double.random(in: 0.3...0.9)
                let reflection = DailyReflection(
                    feeling: [ReflectionFeeling.great, .calm, .tired].randomElement(),
                    sleepQuality: [SleepQuality.great, .good, .poor].randomElement()
                )
                let snapshot = DailySmileySnapshotBuilder()
                    .daysAgo(i)
                    .withMeals([MealBuilder().withItems(["Test meal \(i)"]).withScore(score).build()])
                    .withReflection(reflection)
                    .build()
                self.historicalService.historicalData.addOrUpdate(snapshot: snapshot)
            }
        }

        private func seedCorrelatedData() {
            let goodFeelings: [ReflectionFeeling] = [.great, .calm, .great, .calm, .great]
            let badFeelings: [ReflectionFeeling] = [.tired, .heavy]
            let goodScores: [Double] = [0.85, 0.90, 0.88, 0.82, 0.86]
            let badScores: [Double] = [0.25, 0.30]
            for i in 0..<7 {
                let isGood = i < 5
                let score = isGood ? goodScores[i] : badScores[i - 5]
                let feeling = isGood ? goodFeelings[i] : badFeelings[i - 5]
                let reflection = DailyReflection(feeling: feeling, sleepQuality: isGood ? .good : .poor)
                let snapshot = DailySmileySnapshotBuilder()
                    .daysAgo(i)
                    .withMeals([MealBuilder().withItems(["Meal"]).withScore(score).build()])
                    .withReflection(reflection)
                    .build()
                self.historicalService.historicalData.addOrUpdate(snapshot: snapshot)
            }
        }
    }
#endif
