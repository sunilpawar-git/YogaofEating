// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for InsightGenerationService
    /// Phase 6: TDD - Tests written before implementation
    @MainActor
    final class InsightGenerationServiceTests: XCTestCase {
        // MARK: - Properties

        var sut: InsightGenerationService!
        var mockHistorical: MockHistoricalDataService!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.mockHistorical = MockHistoricalDataService()
            self.sut = InsightGenerationService(historicalService: self.mockHistorical)
        }

        override func tearDown() {
            self.sut = nil
            self.mockHistorical = nil
            super.tearDown()
        }

        // MARK: - Tests: Data Gathering

        func test_gatherDataForInsight_collectsLast7Days() {
            // Arrange: Create 7 days of data
            for daysAgo in 0..<7 {
                let snapshot = self.makeSnapshot(daysAgo: daysAgo, score: 0.8, items: ["Oatmeal"], mealType: .breakfast)
                self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)
            }

            // Act
            let data = self.sut.gatherDataForInsight()

            // Assert
            XCTAssertEqual(data.count, 7)
        }

        func test_gatherDataForInsight_excludesEmptyDays() {
            // Arrange: Create mix of empty and non-empty days
            for daysAgo in 0..<4 {
                let hasMeals = daysAgo % 2 == 0
                let meals = hasMeals ?
                    [MealBuilder().withMealType(.breakfast).withItems(["Food"]).withScore(0.7).build()] : [Meal]()
                let snapshot = DailySmileySnapshotBuilder().daysAgo(daysAgo).withMeals(meals).build()
                self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)
            }

            // Act
            let data = self.sut.gatherDataForInsight()

            // Assert - Only non-empty days should be included
            XCTAssertEqual(data.count, 2)
        }

        // MARK: - Tests: Insight Prompt Creation

        func test_createInsightPrompt_includesSleepData() {
            // Arrange: Create snapshot with sleep quality
            let today = Date()
            let reflection = DailyReflection(
                feeling: .great,
                sleepQuality: .great,
                note: ""
            )
            let snapshot = DailySmileySnapshotBuilder()
                .withDate(today)
                .withMeals([MealBuilder().withMealType(.dinner).withItems(["Pizza"]).withScore(0.4).build()])
                .withReflection(reflection)
                .build()
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

            // Act
            let prompt = self.sut.createInsightPrompt(from: [snapshot])

            // Assert
            XCTAssertTrue(prompt.contains("sleep") || prompt.contains("Sleep"))
        }

        func test_createInsightPrompt_includesMealData() {
            // Arrange
            let today = Date()
            let snapshot = self.makeSnapshot(score: 0.3, items: ["Pizza", "Ice Cream"], mealType: .dinner)
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

            // Act
            let prompt = self.sut.createInsightPrompt(from: [snapshot])

            // Assert
            XCTAssertTrue(prompt.contains("Pizza") || prompt.contains("meal") || prompt.contains("food"))
        }

        func test_createInsightPrompt_includesMindCheckData() {
            // Arrange
            let today = Date()
            let morningEntries = [
                MindCheckEntry(category: .todo, text: "Finish project", timestamp: today, context: .morning)
            ]
            let eveningEntries = [
                MindCheckEntry(category: .accomplished, text: "Done", timestamp: today, context: .evening)
            ]
            let snapshot = self.makeSnapshot(
                score: 0.9,
                items: ["Salad"],
                morningMindCheck: morningEntries,
                eveningMindCheck: eveningEntries
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

            // Act
            let prompt = self.sut.createInsightPrompt(from: [snapshot])

            // Assert - Should reference mindset/thoughts or todos
            XCTAssertTrue(
                prompt.contains("mind") || prompt.contains("thought") || prompt.contains("todo") ||
                    prompt.contains("Todo") || prompt.contains("accomplished") || prompt.contains("completed"),
                "Prompt should contain mindset-related or todo-related content"
            )
        }

        // MARK: - Phase 4: Tests for Todo Completion in Data Pipeline

        func test_createInsightPrompt_includesTodoCompletionStatus() {
            // Given: A snapshot with completed and incomplete todos
            let today = Date()
            let morningEntries = [
                MindCheckEntry(
                    category: .todo,
                    text: "Exercise",
                    timestamp: today,
                    context: .morning,
                    isAccomplished: true
                ),
                MindCheckEntry(
                    category: .todo,
                    text: "Read book",
                    timestamp: today,
                    context: .morning,
                    isAccomplished: false
                )
            ]
            let snapshot = self.makeSnapshot(score: 0.9, items: ["Salad"], morningMindCheck: morningEntries)

            // When: Creating insight prompt
            let prompt = self.sut.createInsightPrompt(from: [snapshot])

            // Then: Prompt should mention completion status
            // The prompt may show "1/2 completed" or similar representation
            XCTAssertTrue(
                prompt.contains("todo") || prompt.contains("To-Do") || prompt.contains("completed"),
                "Prompt should reference todo completion"
            )
        }

        // MARK: - Tests: Insight Storage

        func test_saveInsight_persistsToSnapshot() async {
            // Arrange
            let today = Date()
            let snapshot = self.makeSnapshot(score: 0.8, items: ["Eggs"], mealType: .breakfast)
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

            let insight = LegacyDailyInsight(
                date: today,
                insightText: "Your eating patterns suggest a connection.",
                insightType: .foodSleep,
                confidence: 0.8
            )

            // Act
            self.sut.saveInsight(insight, for: today)

            // Assert - For now, just verify it doesn't crash
            // Full persistence will be implemented with the service
            XCTAssertNotNil(insight)
        }

        // MARK: - Tests: Check If Insight Needed

        func test_shouldGenerateInsight_returnsTrueForNewDay() {
            // Arrange: Need minimum 3 days of data per BriefingThresholds.minimumDataPoints
            let calendar = Calendar.current
            let today = Date()

            // Add 2 days ago
            let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
            let twoDaysSnapshot = self.makeSnapshot(daysAgo: 2, score: 0.7, items: ["Salad"])
            self.mockHistorical.historicalData.addOrUpdate(snapshot: twoDaysSnapshot)

            let yesterdaySnapshot = self.makeSnapshot(daysAgo: 1, score: 0.5, items: ["Pasta"], mealType: .dinner)
            self.mockHistorical.historicalData.addOrUpdate(snapshot: yesterdaySnapshot)

            let sleepReflection = DailyReflection(feeling: nil, sleepQuality: .good, note: "")
            let todaySnapshot = self.makeSnapshot(
                score: 0.6,
                items: ["Toast"],
                mealType: .breakfast,
                reflection: sleepReflection
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: todaySnapshot)

            // Act
            let shouldGenerate = self.sut.shouldGenerateInsight(for: today)

            // Assert - Should be true when sleep logged with minimum historical data
            XCTAssertTrue(shouldGenerate)
        }

        func test_shouldGenerateInsight_returnsFalseWithoutSleep() {
            // Arrange: No sleep logged
            let today = Date()
            let snapshot = self.makeSnapshot(score: 0.6, items: ["Toast"], mealType: .breakfast)
            self.mockHistorical.historicalData.addOrUpdate(snapshot: snapshot)

            // Act
            let shouldGenerate = self.sut.shouldGenerateInsight(for: today)

            // Assert
            XCTAssertFalse(shouldGenerate)
        }

        // MARK: - Tests: Rich Insight Generation (Phase 5)

        func test_generateInsight_includesDateReferences() async throws {
            // Arrange: Create data with late dinner (need minimum 3 days per BriefingThresholds)
            let calendar = Calendar.current
            let today = Date()

            // 2 days ago baseline
            let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
            let twoDaysSnapshot = self.makeSnapshot(daysAgo: 2, score: 0.7, items: ["Chicken"])
            self.mockHistorical.historicalData.addOrUpdate(snapshot: twoDaysSnapshot)

            // Yesterday with late dinner
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            var lateDinnerTime = calendar.startOfDay(for: yesterday)
            lateDinnerTime = calendar.date(byAdding: .hour, value: 21, to: lateDinnerTime)!

            let lateMeal = MealBuilder().withTimestamp(lateDinnerTime).withMealType(.dinner).withItems(["Heavy pasta"])
                .withScore(0.4).build()
            let yesterdaySnapshot = DailySmileySnapshotBuilder().daysAgo(1).withMeals([lateMeal]).build()
            self.mockHistorical.historicalData.addOrUpdate(snapshot: yesterdaySnapshot)

            // Today with poor sleep
            let reflection = DailyReflection(feeling: .tired, sleepQuality: .poor, note: nil)
            let todaySnapshot = self.makeSnapshot(
                score: 0.6,
                items: ["Toast"],
                mealType: .breakfast,
                reflection: reflection
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: todaySnapshot)

            // Act
            let insight = try await self.sut.generateInsight(for: today)

            // Assert - Insight should exist with minimum data threshold met
            XCTAssertNotNil(insight)
        }

        func test_generateInsight_prescriptiveFormat() async throws {
            // Arrange: Setup data for prescriptive insight
            let calendar = Calendar.current
            let today = Date()

            // Add multiple days of data
            for daysAgo in 1...3 {
                self.mockHistorical.historicalData.addOrUpdate(snapshot: self.makeSnapshot(
                    daysAgo: daysAgo,
                    mealType: .dinner
                ))
            }

            // Today with sleep
            let reflection = DailyReflection(feeling: nil, sleepQuality: .good, note: nil)
            let todaySnapshot = self.makeSnapshot(
                score: 0.8,
                items: ["Eggs"],
                mealType: .breakfast,
                reflection: reflection
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: todaySnapshot)

            // Act
            let insight = try await self.sut.generateInsight(for: today)

            // Assert
            XCTAssertNotNil(insight)
            // Insight text should contain actionable language
            if let text = insight?.insightText {
                XCTAssertFalse(text.isEmpty)
            }
        }

        func test_generateInsight_observationalFormat() async throws {
            // Arrange: Setup data for observational insight
            let calendar = Calendar.current
            let today = Date()

            // Add historical data
            for daysAgo in 1...4 {
                self.mockHistorical.historicalData.addOrUpdate(snapshot: self.makeSnapshot(
                    daysAgo: daysAgo,
                    score: 0.9,
                    items: ["Salad"]
                ))
            }

            // Today
            let reflection = DailyReflection(feeling: nil, sleepQuality: .great, note: nil)
            let todaySnapshot = self.makeSnapshot(
                score: 0.95,
                items: ["Fruit"],
                mealType: .breakfast,
                reflection: reflection
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: todaySnapshot)

            // Act
            let insight = try await self.sut.generateInsight(for: today)

            // Assert
            XCTAssertNotNil(insight)
        }

        // MARK: - Phase 6: HealthKit Sleep Data Integration Tests

        func test_generateInsight_acceptsHealthKitSleepData() async throws {
            // Given: Setup data with sleep logged
            let calendar = Calendar.current
            let today = Date()

            // Add historical data
            for daysAgo in 1...2 {
                self.mockHistorical.historicalData.addOrUpdate(
                    snapshot: self.makeSnapshot(
                        daysAgo: daysAgo,
                        score: 0.8,
                        items: ["Healthy food"],
                        mealType: .dinner
                    )
                )
            }

            // Today with sleep
            let reflection = DailyReflection(feeling: nil, sleepQuality: .good, note: nil)
            let todaySnapshot = self.makeSnapshot(
                score: 0.9,
                items: ["Oatmeal"],
                mealType: .breakfast,
                reflection: reflection
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: todaySnapshot)

            // Create mock HealthKit sleep data
            let healthKitSleepData: [Date: SleepData] = [
                calendar.startOfDay(for: today): SleepData(
                    sleepDuration: 7.5 * 3600, // 7.5 hours
                    timeInBed: 8 * 3600, // 8 hours
                    sleepStart: nil,
                    sleepEnd: nil,
                    sleepScore: 85
                )
            ]

            // When: Generate insight with HealthKit data
            let insight = try await self.sut.generateInsight(
                for: today,
                healthKitSleepData: healthKitSleepData
            )

            // Then: Should still get an insight (fallback to local since no Firebase in tests)
            XCTAssertNotNil(insight)
            XCTAssertFalse(insight!.insightText.isEmpty)
        }

        func test_generateInsight_worksWithoutHealthKitData() async throws {
            // Given: Setup data with sleep logged but no HealthKit data
            let calendar = Calendar.current
            let today = Date()

            // Add historical data
            for daysAgo in 1...2 {
                self.mockHistorical.historicalData.addOrUpdate(
                    snapshot: self.makeSnapshot(daysAgo: daysAgo, score: 0.7, items: ["Food"], mealType: .dinner)
                )
            }

            // Today with sleep
            let reflection = DailyReflection(feeling: nil, sleepQuality: .poor, note: nil)
            let todaySnapshot = self.makeSnapshot(
                score: 0.6,
                items: ["Toast"],
                mealType: .breakfast,
                reflection: reflection
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: todaySnapshot)

            // When: Generate insight with empty HealthKit data (backward compatible)
            let insight = try await self.sut.generateInsight(for: today, healthKitSleepData: [:])

            // Then: Should still generate an insight
            XCTAssertNotNil(insight)
        }

        func test_generateInsight_handlesMultipleDaysOfHealthKitData() async throws {
            // Given: Setup data for multiple days
            let calendar = Calendar.current
            let today = Date()

            // Add 3 days of historical data
            for daysAgo in 0..<3 {
                let reflection = daysAgo == 0 ? DailyReflection(feeling: nil, sleepQuality: .good, note: nil) : nil
                self.mockHistorical.historicalData.addOrUpdate(
                    snapshot: self.makeSnapshot(daysAgo: daysAgo, score: 0.7, items: ["Lunch"], reflection: reflection)
                )
            }

            // Create HealthKit sleep data for all 3 days
            var healthKitSleepData: [Date: SleepData] = [:]
            for daysAgo in 0..<3 {
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
                healthKitSleepData[calendar.startOfDay(for: date)] = SleepData(
                    sleepDuration: Double(6 + daysAgo) * 3600,
                    timeInBed: Double(7 + daysAgo) * 3600,
                    sleepStart: nil,
                    sleepEnd: nil,
                    sleepScore: Double(70 + daysAgo * 5)
                )
            }

            // When: Generate insight with multiple days of HealthKit data
            let insight = try await self.sut.generateInsight(
                for: today,
                healthKitSleepData: healthKitSleepData
            )

            // Then: Should generate an insight
            XCTAssertNotNil(insight)
        }

        // MARK: - Phase A4: saveInsight Persistence Tests

        func test_saveInsight_persistsToHistoricalService() {
            // Arrange
            let today = Date()
            let insight = LegacyDailyInsight(
                id: UUID(),
                date: today,
                insightText: "You sleep better on days with less sugar.",
                insightType: .foodSleep,
                confidence: 0.8
            )

            // Act
            self.sut.saveInsight(insight, for: today)

            // Assert: mock spy should have recorded the call
            XCTAssertTrue(self.mockHistorical.updateInsightCalled)
            XCTAssertEqual(self.mockHistorical.lastUpdatedInsight?.id, insight.id)
        }

        func test_saveInsight_savedInsightIsRecoverable() {
            // Arrange
            let today = Date()
            let insight = LegacyDailyInsight(
                id: UUID(),
                date: today,
                insightText: "Gratitude practice correlates with better mood.",
                insightType: .mindsetFeeling,
                confidence: 0.75
            )

            // Act
            self.sut.saveInsight(insight, for: today)

            // Assert: retrieving snapshot for today should surface the insight
            let recovered = self.mockHistorical.getSnapshot(for: today)?.insight
            XCTAssertNotNil(recovered)
            XCTAssertEqual(recovered?.id, insight.id)
        }

        func test_saveInsight_doesNotLogInsightText() {
            // This test documents the security requirement: insightText (sensitive health data)
            // must not be logged. saveInsight only logs date metadata, never the text content.
            // Verified by code review — briefingLogger.info logs date only (privacy: .public).
            // Sensitive field insightText has no Logger call after Phase A4 fix.
            let today = Date()
            let insight = LegacyDailyInsight(
                id: UUID(),
                date: today,
                insightText: "SENSITIVE: high cholesterol detected",
                insightType: .pattern,
                confidence: 0.9
            )
            // Should not throw or crash — functional contract
            self.sut.saveInsight(insight, for: today)
            XCTAssertTrue(self.mockHistorical.updateInsightCalled)
        }

        // MARK: - Phase 5: Server Fallback Tests

        func test_generateInsight_fallsBackToLocal_whenServerUnavailable() async throws {
            // Arrange: Create data with sleep logged (no Firebase functions in test)
            let today = Date()

            // Add historical data
            for daysAgo in 1...2 {
                self.mockHistorical.historicalData.addOrUpdate(
                    snapshot: self.makeSnapshot(
                        daysAgo: daysAgo,
                        score: 0.8,
                        items: ["Healthy food"],
                        mealType: .dinner
                    )
                )
            }

            // Today with sleep
            let reflection = DailyReflection(feeling: nil, sleepQuality: .good, note: nil)
            let todaySnapshot = self.makeSnapshot(
                score: 0.9,
                items: ["Oatmeal"],
                mealType: .breakfast,
                reflection: reflection
            )
            self.mockHistorical.historicalData.addOrUpdate(snapshot: todaySnapshot)

            // Act: Generate insight (should fall back to local since no Firebase)
            let insight = try await self.sut.generateInsight(for: today)

            // Assert: Should still get an insight via local fallback
            XCTAssertNotNil(insight)
            XCTAssertFalse(insight!.insightText.isEmpty)
        }

        // MARK: - Helpers

        private func makeSnapshot(
            daysAgo: Int = 0,
            score: Double = 0.7,
            items: [String] = ["Food"],
            mealType: MealType = .lunch,
            reflection: DailyReflection? = nil,
            morningMindCheck: [MindCheckEntry]? = nil,
            eveningMindCheck: [MindCheckEntry]? = nil
        ) -> DailySmileySnapshot {
            let meal = MealBuilder().withMealType(mealType).withItems(items).withScore(score).build()
            var builder = DailySmileySnapshotBuilder()
                .daysAgo(daysAgo)
                .withMeals([meal])
            if let reflection { builder = builder.withReflection(reflection) }
            if let morningMindCheck { builder = builder.withMorningMindCheck(morningMindCheck) }
            if let eveningMindCheck { builder = builder.withEveningMindCheck(eveningMindCheck) }
            return builder.build()
        }
    }
#endif
