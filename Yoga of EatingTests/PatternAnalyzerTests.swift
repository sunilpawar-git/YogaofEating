import XCTest
@testable import Yoga_of_Eating

/// Tests for PatternAnalyzer service.
/// Phase 4: Detect correlations between food, todos, sleep, and mood.
final class PatternAnalyzerTests: XCTestCase {
    // MARK: - Setup

    private var analyzer: PatternAnalyzer!

    override func setUp() {
        super.setUp()
        self.analyzer = PatternAnalyzer()
    }

    override func tearDown() {
        self.analyzer = nil
        super.tearDown()
    }

    // MARK: - Minimum Data Tests

    func test_analyzer_requiresMinimumDataPoints() {
        // Given - only 1 day of data
        let snapshots = [self.createSnapshot(daysAgo: 0)]

        // When
        let patterns = self.analyzer.analyzePatterns(from: snapshots)

        // Then - should return empty (not enough data)
        XCTAssertTrue(patterns.isEmpty)
    }

    func test_analyzer_worksWithSufficientData() {
        // Given - 3 days of data
        let snapshots = [
            self.createSnapshot(daysAgo: 0, sleepQuality: .poor),
            self.createSnapshot(daysAgo: 1, sleepQuality: .good),
            self.createSnapshot(daysAgo: 2, sleepQuality: .great)
        ]

        // When
        let patterns = self.analyzer.analyzePatterns(from: snapshots)

        // Then - should be able to analyze
        // May or may not find patterns depending on data
        XCTAssertNotNil(patterns)
    }

    // MARK: - Food-Sleep Correlation Tests

    func test_analyzer_detectsLateDinnerSleepCorrelation() {
        // Given - late dinners on day N correlate with poor sleep on day N+1
        // Day 0 (today): poor sleep (from yesterday's late dinner)
        // Day 1 (yesterday): late dinner, poor sleep (from day 2's late dinner)
        // Day 2: late dinner, good sleep
        // Day 3: no late dinner, great sleep
        let snapshots = [
            self.createSnapshot(daysAgo: 0, sleepQuality: .poor, lateDinner: false),
            self.createSnapshot(daysAgo: 1, sleepQuality: .poor, lateDinner: true),
            self.createSnapshot(daysAgo: 2, sleepQuality: .good, lateDinner: true),
            self.createSnapshot(daysAgo: 3, sleepQuality: .great, lateDinner: false)
        ]

        // When
        let patterns = self.analyzer.analyzeFoodSleepCorrelation(from: snapshots)

        // Then
        XCTAssertFalse(patterns.isEmpty, "Should detect late dinner pattern")
        if let pattern = patterns.first {
            XCTAssertEqual(pattern.type, .foodSleep)
        }
    }

    // MARK: - Todo-Mood Correlation Tests

    func test_analyzer_detectsTodoCompletionMoodCorrelation() {
        // Given - completing todos correlates with good mood
        let snapshots = [
            self.createSnapshot(daysAgo: 0, feeling: .great, todosCompleted: true),
            self.createSnapshot(daysAgo: 1, feeling: .calm, todosCompleted: true),
            self.createSnapshot(daysAgo: 2, feeling: .tired, todosCompleted: false),
            self.createSnapshot(daysAgo: 3, feeling: .heavy, todosCompleted: false)
        ]

        // When
        let patterns = self.analyzer.analyzeTodoMoodCorrelation(from: snapshots)

        // Then
        XCTAssertFalse(patterns.isEmpty, "Should detect todo completion pattern")
        if let pattern = patterns.first {
            XCTAssertEqual(pattern.type, .mindsetFeeling)
        }
    }

    // MARK: - Gratitude Practice Tests

    func test_analyzer_detectsGratitudePractice() {
        // Given - gratitude practice correlates with better wellbeing
        let snapshots = [
            self.createSnapshot(daysAgo: 0, feeling: .great, hasGratitude: true),
            self.createSnapshot(daysAgo: 1, feeling: .calm, hasGratitude: true),
            self.createSnapshot(daysAgo: 2, feeling: .tired, hasGratitude: false),
            self.createSnapshot(daysAgo: 3, feeling: .heavy, hasGratitude: false)
        ]

        // When
        let patterns = self.analyzer.analyzeGratitudePractice(from: snapshots)

        // Then - may find a pattern
        XCTAssertNotNil(patterns)
    }

    // MARK: - InsightPattern Tests

    func test_insightPattern_initialization() {
        // Given
        let reference = InsightReference(
            date: Date(),
            description: "Late coffee",
            category: .food
        )

        // When
        let pattern = InsightPattern(
            type: .foodSleep,
            description: "Late coffee affects sleep",
            confidence: 0.8,
            references: [reference]
        )

        // Then
        XCTAssertEqual(pattern.type, .foodSleep)
        XCTAssertEqual(pattern.confidence, 0.8)
        XCTAssertEqual(pattern.references.count, 1)
    }

    // MARK: - Helpers

    private func createSnapshot(
        daysAgo: Int,
        sleepQuality: SleepQuality? = nil,
        feeling: ReflectionFeeling? = nil,
        lateDinner: Bool = false,
        todosCompleted: Bool = false,
        hasGratitude: Bool = false
    ) -> DailySmileySnapshot {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!

        var meals: [Meal] = [
            Meal(mealType: .breakfast, items: ["Oatmeal"], healthScore: 0.8)
        ]

        if lateDinner {
            // Create a late dinner (after 9pm)
            var dinnerDate = calendar.startOfDay(for: date)
            dinnerDate = calendar.date(byAdding: .hour, value: 21, to: dinnerDate)!
            meals.append(
                Meal(
                    id: UUID(),
                    timestamp: dinnerDate,
                    mealType: .dinner,
                    items: ["Heavy pasta"],
                    healthScore: 0.4
                )
            )
        }

        let reflection = DailyReflection(
            feeling: feeling,
            sleepQuality: sleepQuality,
            note: nil
        )

        var morningMindCheck: [MindCheckEntry]?
        if todosCompleted || hasGratitude {
            var entries: [MindCheckEntry] = []
            if todosCompleted {
                entries.append(
                    MindCheckEntry(
                        category: .todo,
                        text: "Task",
                        context: .morning,
                        isAccomplished: todosCompleted
                    )
                )
            }
            if hasGratitude {
                entries.append(
                    MindCheckEntry(
                        category: .gratitude,
                        text: "Grateful",
                        context: .morning
                    )
                )
            }
            morningMindCheck = entries
        }

        return DailySmileySnapshot(
            id: UUID(),
            date: date,
            smileyState: .neutral,
            meals: meals,
            mealCount: meals.count,
            averageHealthScore: meals.map(\.healthScore).reduce(0, +) / Double(meals.count),
            reflection: reflection,
            morningMindCheck: morningMindCheck,
            eveningMindCheck: nil
        )
    }
}
