// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for PatternAnalyzer's new CorrelationCard-producing methods.
    /// TDD Phase: RED — tests for foodToFeeling, timingConsistency, todoProductivity,
    /// and the aggregate generateCorrelationCards(from:) entry point.
    final class PatternAnalyzerCorrelationTests: XCTestCase {
        // MARK: - Properties

        private var analyzer: PatternAnalyzer!

        // MARK: - Setup & Teardown

        override func setUp() {
            super.setUp()
            self.analyzer = PatternAnalyzer()
        }

        override func tearDown() {
            self.analyzer = nil
            super.tearDown()
        }

        // MARK: - generateCorrelationCards: Minimum Data Guard

        func test_generateCorrelationCards_requiresMinimumData() {
            let snapshots = [createSnapshot(daysAgo: 0)]
            let cards = self.analyzer.generateCorrelationCards(from: snapshots)
            XCTAssertTrue(cards.isEmpty, "Should return no cards with insufficient data")
        }

        func test_generateCorrelationCards_returnsCards_withSufficientData() {
            let snapshots = self.createHighProteinCorrelationData()
            let cards = self.analyzer.generateCorrelationCards(from: snapshots)
            XCTAssertNotNil(cards)
        }

        func test_generateCorrelationCards_sortedByConfidence() {
            let snapshots = self.createMixedCorrelationData()
            let cards = self.analyzer.generateCorrelationCards(from: snapshots)
            guard cards.count >= 2 else { return }
            for i in 0..<cards.count - 1 {
                XCTAssertGreaterThanOrEqual(
                    cards[i].confidence, cards[i + 1].confidence,
                    "Cards should be sorted by confidence descending"
                )
            }
        }

        // MARK: - Food-to-Feeling Correlation

        func test_foodToFeeling_detectsHighScoreMealsCorrelatingWithGoodMood() {
            let snapshots = [
                createSnapshot(daysAgo: 0, feeling: .great, mealScore: 0.85),
                createSnapshot(daysAgo: 1, feeling: .calm, mealScore: 0.80),
                createSnapshot(daysAgo: 2, feeling: .great, mealScore: 0.90),
                createSnapshot(daysAgo: 3, feeling: .tired, mealScore: 0.30),
                createSnapshot(daysAgo: 4, feeling: .heavy, mealScore: 0.25)
            ]

            let cards = self.analyzer.analyzeFoodToFeeling(from: snapshots)

            XCTAssertFalse(cards.isEmpty, "Should detect food-to-mood correlation")
            if let card = cards.first {
                XCTAssertEqual(card.category, .foodToMood)
                XCTAssertGreaterThanOrEqual(card.confidence, 0.6)
                XCTAssertFalse(card.observation.isEmpty)
            }
        }

        func test_foodToFeeling_returnsEmpty_whenNoMoodData() {
            let snapshots = [
                createSnapshot(daysAgo: 0, feeling: nil, mealScore: 0.8),
                createSnapshot(daysAgo: 1, feeling: nil, mealScore: 0.7),
                createSnapshot(daysAgo: 2, feeling: nil, mealScore: 0.9)
            ]

            let cards = self.analyzer.analyzeFoodToFeeling(from: snapshots)
            XCTAssertTrue(cards.isEmpty, "No mood data means no correlation")
        }

        func test_foodToFeeling_returnsEmpty_whenNoMeals() {
            let snapshots = [
                createSnapshot(daysAgo: 0, feeling: .great, mealScore: nil),
                createSnapshot(daysAgo: 1, feeling: .calm, mealScore: nil),
                createSnapshot(daysAgo: 2, feeling: .tired, mealScore: nil)
            ]

            let cards = self.analyzer.analyzeFoodToFeeling(from: snapshots)
            XCTAssertTrue(cards.isEmpty, "No meal data means no correlation")
        }

        // MARK: - Timing Consistency Correlation

        func test_timingConsistency_detectsRegularMealTimes() {
            let snapshots = [
                createSnapshotWithMealTimes(daysAgo: 0, mealHours: [8, 13, 19], sleepQuality: .great),
                createSnapshotWithMealTimes(daysAgo: 1, mealHours: [8, 12, 19], sleepQuality: .good),
                createSnapshotWithMealTimes(daysAgo: 2, mealHours: [8, 13, 19], sleepQuality: .great),
                createSnapshotWithMealTimes(daysAgo: 3, mealHours: [6, 11, 23], sleepQuality: .poor),
                createSnapshotWithMealTimes(daysAgo: 4, mealHours: [5, 14, 23], sleepQuality: .terrible)
            ]

            let cards = self.analyzer.analyzeTimingConsistency(from: snapshots)

            XCTAssertFalse(cards.isEmpty, "Should detect timing consistency pattern")
            if let card = cards.first {
                XCTAssertEqual(card.category, .timingPattern)
                XCTAssertFalse(card.observation.isEmpty)
            }
        }

        func test_timingConsistency_returnsEmpty_withInsufficientData() {
            let snapshots = [
                createSnapshotWithMealTimes(daysAgo: 0, mealHours: [8, 13], sleepQuality: .good)
            ]

            let cards = self.analyzer.analyzeTimingConsistency(from: snapshots)
            XCTAssertTrue(cards.isEmpty)
        }

        // MARK: - Todo Productivity Correlation

        func test_todoProductivity_detectsCompletionCorrelatingWithHighFoodScore() {
            let snapshots = [
                createSnapshot(daysAgo: 0, mealScore: 0.85, todosCompleted: true, totalTodos: 3),
                createSnapshot(daysAgo: 1, mealScore: 0.80, todosCompleted: true, totalTodos: 2),
                createSnapshot(daysAgo: 2, mealScore: 0.90, todosCompleted: true, totalTodos: 4),
                createSnapshot(daysAgo: 3, mealScore: 0.30, todosCompleted: false, totalTodos: 3),
                createSnapshot(daysAgo: 4, mealScore: 0.25, todosCompleted: false, totalTodos: 2)
            ]

            let cards = self.analyzer.analyzeTodoProductivity(from: snapshots)

            XCTAssertFalse(cards.isEmpty, "Should detect todo-productivity correlation")
            if let card = cards.first {
                XCTAssertEqual(card.category, .focusToFeeling)
                XCTAssertFalse(card.observation.isEmpty)
            }
        }

        func test_todoProductivity_returnsEmpty_whenNoTodos() {
            let snapshots = [
                createSnapshot(daysAgo: 0, mealScore: 0.8),
                createSnapshot(daysAgo: 1, mealScore: 0.7),
                createSnapshot(daysAgo: 2, mealScore: 0.9)
            ]

            let cards = self.analyzer.analyzeTodoProductivity(from: snapshots)
            XCTAssertTrue(cards.isEmpty, "No todos means no productivity correlation")
        }

        // MARK: - CorrelationCard Output Contracts

        func test_correlationCard_confidenceIsClamped() {
            let snapshots = self.createHighProteinCorrelationData()
            let cards = self.analyzer.generateCorrelationCards(from: snapshots)

            for card in cards {
                XCTAssertGreaterThanOrEqual(card.confidence, 0.0)
                XCTAssertLessThanOrEqual(card.confidence, 1.0)
            }
        }

        func test_correlationCard_hasValidCategory() {
            let snapshots = self.createMixedCorrelationData()
            let cards = self.analyzer.generateCorrelationCards(from: snapshots)

            for card in cards {
                XCTAssertTrue(
                    CorrelationCategory.allCases.contains(card.category),
                    "Card category must be a valid CorrelationCategory"
                )
            }
        }

        // MARK: - Helpers

        private func createSnapshot(
            daysAgo: Int,
            feeling: ReflectionFeeling? = nil,
            sleepQuality: SleepQuality? = nil,
            mealScore: Double? = 0.5,
            lateDinner: Bool = false,
            todosCompleted: Bool = false,
            totalTodos: Int = 0
        ) -> DailySmileySnapshot {
            let calendar = Calendar.current
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!

            var meals: [Meal] = []
            if let score = mealScore {
                meals.append(
                    MealBuilder().withMealType(.lunch).withItems(["Test meal"]).withScore(score).build()
                )
            }

            if lateDinner {
                var dinnerDate = calendar.startOfDay(for: date)
                dinnerDate = calendar.date(byAdding: .hour, value: 22, to: dinnerDate)!
                meals.append(
                    MealBuilder()
                        .withTimestamp(dinnerDate)
                        .withMealType(.dinner)
                        .withItems(["Late meal"])
                        .withScore(0.3)
                        .build()
                )
            }

            let reflection = DailyReflection(feeling: feeling, sleepQuality: sleepQuality, note: nil)

            var morningMindCheck: [MindCheckEntry]?
            if totalTodos > 0 {
                morningMindCheck = (0..<totalTodos).map { i in
                    MindCheckEntryBuilder()
                        .withCategory(.todo)
                        .withText("Todo \(i)")
                        .withContext(.morning)
                        .build()
                }
                if todosCompleted {
                    morningMindCheck = morningMindCheck?.map { $0.withAccomplished(true) }
                }
            }

            var builder = DailySmileySnapshotBuilder()
                .withDate(date)
                .withMeals(meals)
                .withReflection(reflection)
            if let morningMindCheck {
                builder = builder.withMorningMindCheck(morningMindCheck)
            }
            return builder.build()
        }

        private func createSnapshotWithMealTimes(
            daysAgo: Int,
            mealHours: [Int],
            sleepQuality: SleepQuality
        ) -> DailySmileySnapshot {
            let calendar = Calendar.current
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let dayStart = calendar.startOfDay(for: date)

            let types: [MealType] = [.breakfast, .lunch, .dinner, .snacks]
            let meals: [Meal] = mealHours.enumerated().map { index, hour in
                let mealTime = calendar.date(byAdding: .hour, value: hour, to: dayStart)!
                let type = index < types.count ? types[index] : .snacks
                return MealBuilder()
                    .withTimestamp(mealTime)
                    .withMealType(type)
                    .withItems(["Meal"])
                    .withScore(0.7)
                    .build()
            }

            let reflection = DailyReflection(feeling: nil, sleepQuality: sleepQuality, note: nil)

            return DailySmileySnapshotBuilder()
                .withDate(date)
                .withMeals(meals)
                .withReflection(reflection)
                .build()
        }

        private func createHighProteinCorrelationData() -> [DailySmileySnapshot] {
            [
                self.createSnapshot(daysAgo: 0, feeling: .great, mealScore: 0.9),
                self.createSnapshot(daysAgo: 1, feeling: .calm, mealScore: 0.85),
                self.createSnapshot(daysAgo: 2, feeling: .great, mealScore: 0.88),
                self.createSnapshot(daysAgo: 3, feeling: .tired, mealScore: 0.3),
                self.createSnapshot(daysAgo: 4, feeling: .heavy, mealScore: 0.2)
            ]
        }

        private func createMixedCorrelationData() -> [DailySmileySnapshot] {
            [
                self.createSnapshot(daysAgo: 0, feeling: .great, mealScore: 0.9, todosCompleted: true, totalTodos: 3),
                self.createSnapshot(daysAgo: 1, feeling: .calm, mealScore: 0.85, todosCompleted: true, totalTodos: 2),
                self.createSnapshot(daysAgo: 2, feeling: .great, mealScore: 0.88, todosCompleted: true, totalTodos: 4),
                self.createSnapshot(daysAgo: 3, feeling: .tired, mealScore: 0.3, todosCompleted: false, totalTodos: 3),
                self.createSnapshot(daysAgo: 4, feeling: .heavy, mealScore: 0.2, todosCompleted: false, totalTodos: 2),
                self.createSnapshot(daysAgo: 5, feeling: .calm, mealScore: 0.75, todosCompleted: true, totalTodos: 1),
                self.createSnapshot(daysAgo: 6, feeling: .tired, mealScore: 0.4, todosCompleted: false, totalTodos: 2)
            ]
        }
    }
#endif
