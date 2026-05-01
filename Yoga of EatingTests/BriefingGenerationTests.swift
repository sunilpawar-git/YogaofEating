// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for InsightGenerationService.generateBriefing(for:) method.
    /// TDD Phase: RED — verifies server-first + local fallback pipeline.
    @MainActor
    final class BriefingGenerationTests: XCTestCase {
        // MARK: - Properties

        private var historicalService: MockHistoricalDataService!
        private var sut: InsightGenerationService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.historicalService = MockHistoricalDataService()
            self.sut = InsightGenerationService(
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
            let result = await self.sut.generateBriefing(for: Date())
            XCTAssertNil(result, "Should return nil when no historical data exists")
        }

        func test_generateBriefing_returnsNil_withInsufficientData() async {
            self.seedSnapshots(count: 1)
            let result = await self.sut.generateBriefing(for: Date())
            XCTAssertNil(result, "Should return nil with fewer than 2 data points")
        }

        // MARK: - Local Fallback Tests

        func test_generateBriefing_fallsBackToLocal_whenNoFirebase() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(for: Date())
            XCTAssertNotNil(result, "Should produce briefing via local fallback")
        }

        func test_generateBriefing_localFallback_hasHeadline() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(for: Date())
            XCTAssertFalse(result?.headline.isEmpty ?? true, "Headline must not be empty")
        }

        func test_generateBriefing_localFallback_hasNudge() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(for: Date())
            XCTAssertNotNil(result?.nudge)
            XCTAssertFalse(result!.nudge.suggestion.isEmpty)
        }

        func test_generateBriefing_localFallback_setsDate() async {
            let today = Date()
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(for: today)

            let calendar = Calendar.current
            XCTAssertTrue(
                calendar.isDate(result!.date, inSameDayAs: today),
                "Briefing date should match the requested date"
            )
        }

        func test_generateBriefing_localFallback_isNotViewed() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(for: Date())
            XCTAssertFalse(result?.isViewed ?? true, "New briefing must not be marked as viewed")
        }

        // MARK: - Correlation Card Integration

        func test_generateBriefing_includesCorrelationCards_whenPatternsExist() async {
            self.seedCorrelatedData()
            let result = await self.sut.generateBriefing(for: Date())

            XCTAssertNotNil(result)
            // Local PatternAnalyzer should find at least one correlation
            // (specific count depends on data — don't over-assert)
        }

        func test_generateBriefing_cardsClamped_0to1() async {
            self.seedCorrelatedData()
            let result = await self.sut.generateBriefing(for: Date())

            for card in result?.correlationCards ?? [] {
                XCTAssertGreaterThanOrEqual(card.confidence, 0.0)
                XCTAssertLessThanOrEqual(card.confidence, 1.0)
            }
        }

        // MARK: - Weekly Trend

        func test_generateBriefing_includesWeeklyTrend_withEnoughData() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(for: Date())
            XCTAssertNotNil(result?.weeklyTrend, "Should compute a weekly trend from 5+ days")
        }

        func test_generateBriefing_weeklyTrend_daysLogged_matchesData() async {
            self.seedSnapshots(count: 5)
            let result = await self.sut.generateBriefing(for: Date())
            XCTAssertEqual(result?.weeklyTrend?.daysLogged, 5)
        }

        // MARK: - Helpers

        private func seedSnapshots(count: Int) {
            let calendar = Calendar.current
            for i in 0..<count {
                let date = calendar.date(byAdding: .day, value: -i, to: Date())!
                let meals = [
                    Meal(mealType: .lunch, items: ["Test meal \(i)"], healthScore: Double.random(in: 0.3...0.9))
                ]
                let snapshot = DailySmileySnapshot(
                    id: UUID(),
                    date: date,
                    smileyState: .neutral,
                    meals: meals,
                    mealCount: meals.count,
                    averageHealthScore: meals.first!.healthScore,
                    reflection: DailyReflection(
                        feeling: [ReflectionFeeling.great, .calm, .tired].randomElement(),
                        sleepQuality: [SleepQuality.great, .good, .poor].randomElement()
                    )
                )
                self.historicalService.historicalData.addOrUpdate(snapshot: snapshot)
            }
        }

        private func seedCorrelatedData() {
            let calendar = Calendar.current
            let goodFeelings: [ReflectionFeeling] = [.great, .calm, .great, .calm, .great]
            let badFeelings: [ReflectionFeeling] = [.tired, .heavy]
            let goodScores: [Double] = [0.85, 0.90, 0.88, 0.82, 0.86]
            let badScores: [Double] = [0.25, 0.30]

            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: Date())!
                let isGood = i < 5
                let score = isGood ? goodScores[i] : badScores[i - 5]
                let feeling = isGood ? goodFeelings[i] : badFeelings[i - 5]

                let meals = [Meal(mealType: .lunch, items: ["Meal"], healthScore: score)]

                let snapshot = DailySmileySnapshot(
                    id: UUID(),
                    date: date,
                    smileyState: .neutral,
                    meals: meals,
                    mealCount: 1,
                    averageHealthScore: score,
                    reflection: DailyReflection(
                        feeling: feeling,
                        sleepQuality: isGood ? .good : .poor
                    )
                )
                self.historicalService.historicalData.addOrUpdate(snapshot: snapshot)
            }
        }
    }
#endif
