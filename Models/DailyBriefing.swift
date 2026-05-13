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
    case foodDebt
    /// Two consecutive poor-sleep nights predicting reduced cognitive clarity.
    case sleepRecoveryCarryover
    /// Morning todos with low completion rate signals momentum leak.
    case intentionFollowthrough
    /// Negative evening journal tone predicting lower wellbeing next day.
    case journalTonePrediction
    /// User rated sleep great but synthesis shows low cognitive clarity.
    case sleepMismatch
    /// Three or more low-wellbeing days in the past week.
    case carryOverLoad

    var icon: String {
        switch self {
        case .foodToSleep: "moon.zzz.fill"
        case .foodToMood: "face.smiling.inverse"
        case .focusToFeeling: "brain.head.profile"
        case .timingPattern: "clock.arrow.2.circlepath"
        case .foodDebt: "flame.fill"
        case .sleepRecoveryCarryover: "bed.double.fill"
        case .intentionFollowthrough: "checkmark.circle.trianglebadge.exclamationmark"
        case .journalTonePrediction: "text.bubble.fill"
        case .sleepMismatch: "exclamationmark.triangle.fill"
        case .carryOverLoad: "chart.line.downtrend.xyaxis"
        }
    }

    var displayName: String {
        switch self {
        case .foodToSleep: Strings.Correlation.foodToSleep
        case .foodToMood: Strings.Correlation.foodToMood
        case .focusToFeeling: Strings.Correlation.focusToFeeling
        case .timingPattern: Strings.Correlation.timingPattern
        case .foodDebt: Strings.Correlation.foodDebt
        case .sleepRecoveryCarryover: Strings.Correlation.sleepRecoveryCarryover
        case .intentionFollowthrough: Strings.Correlation.intentionFollowthrough
        case .journalTonePrediction: Strings.Correlation.journalTonePrediction
        case .sleepMismatch: Strings.Correlation.sleepMismatch
        case .carryOverLoad: Strings.Correlation.carryOverLoad
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
