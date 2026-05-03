import Foundation

// MARK: - Trend Direction

/// Direction of the user's overall wellbeing trend across the week.
enum TrendDirection: String, Codable, CaseIterable {
    case improving
    case declining
    case steady
}

// MARK: - Correlation Category

/// Categories of cross-variable correlations the briefing engine can detect.
enum CorrelationCategory: String, Codable, CaseIterable {
    case foodToSleep
    case foodToMood
    case focusToFeeling
    case timingPattern
    /// Two consecutive days of low-quality eating — inflammation and cravings may be elevated.
    case foodDebt

    var icon: String {
        switch self {
        case .foodToSleep:
            "moon.zzz.fill"
        case .foodToMood:
            "face.smiling.inverse"
        case .focusToFeeling:
            "brain.head.profile"
        case .timingPattern:
            "clock.arrow.2.circlepath"
        case .foodDebt:
            "flame.fill"
        }
    }

    var displayName: String {
        switch self {
        case .foodToSleep:
            "Food & Sleep"
        case .foodToMood:
            "Food & Mood"
        case .focusToFeeling:
            "Focus & Feeling"
        case .timingPattern:
            "Timing Pattern"
        case .foodDebt:
            "Food & Momentum"
        }
    }
}

// MARK: - Correlation Card

/// A single correlation finding backed by specific data points.
/// Presented as a swipeable card inside the Morning Briefing.
struct CorrelationCard: Codable, Identifiable, Equatable {
    let id: UUID
    let category: CorrelationCategory
    let observation: String
    let confidence: Double
    let dataPoints: [InsightReference]

    init(
        id: UUID = UUID(),
        category: CorrelationCategory,
        observation: String,
        confidence: Double,
        dataPoints: [InsightReference] = []
    ) {
        self.id = id
        self.category = category
        self.observation = observation
        self.confidence = max(0, min(1, confidence))
        self.dataPoints = dataPoints
    }

    var isHighConfidence: Bool {
        self.confidence > 0.7
    }
}

// MARK: - Actionable Nudge

/// One concrete, immediately actionable suggestion for today.
struct ActionableNudge: Codable, Equatable {
    let suggestion: String
    let reasoning: String
    let relatedMeal: String?

    init(
        suggestion: String,
        reasoning: String,
        relatedMeal: String? = nil
    ) {
        self.suggestion = suggestion
        self.reasoning = reasoning
        self.relatedMeal = relatedMeal
    }
}

// MARK: - Weekly Trend Snippet

/// A lightweight 7-day context block embedded in the briefing.
struct WeeklyTrendSnippet: Codable, Equatable {
    let averageFoodScore: Double
    let averageSleepQuality: Double
    let daysLogged: Int
    let trendDirection: TrendDirection
}

// MARK: - Daily Briefing

/// The top-level model for a structured "Next-Day Insight" delivered each morning.
/// Replaces the single-text DailyInsight with a multi-section briefing card.
struct DailyBriefing: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let generatedAt: Date
    let headline: String
    let correlationCards: [CorrelationCard]
    let nudge: ActionableNudge
    let weeklyTrend: WeeklyTrendSnippet?
    var isViewed: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        generatedAt: Date,
        headline: String,
        correlationCards: [CorrelationCard],
        nudge: ActionableNudge,
        weeklyTrend: WeeklyTrendSnippet? = nil,
        isViewed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.generatedAt = generatedAt
        self.headline = headline
        self.correlationCards = correlationCards
        self.nudge = nudge
        self.weeklyTrend = weeklyTrend
        self.isViewed = isViewed
    }

    // MARK: - Computed Properties

    var hasCorrelations: Bool {
        !self.correlationCards.isEmpty
    }

    var topCorrelation: CorrelationCard? {
        self.correlationCards.max(by: { $0.confidence < $1.confidence })
    }

    // MARK: - Mutations

    mutating func markAsViewed() {
        self.isViewed = true
    }
}
