import Foundation

/// Types of insights the AI can generate based on user data patterns.
enum InsightType: String, Codable, CaseIterable {
    /// Correlation between food choices/timing and sleep quality
    case foodSleep

    /// Correlation between morning mindset and evening feeling
    case mindsetFeeling

    /// Multi-day patterns detected in user behavior
    case pattern

    /// General encouragement when no clear pattern is found
    case encouragement

    /// SF Symbol icon name for this insight type
    var icon: String {
        switch self {
        case .foodSleep:
            "moon.zzz.fill"
        case .mindsetFeeling:
            "brain.head.profile"
        case .pattern:
            "chart.line.uptrend.xyaxis"
        case .encouragement:
            "sparkles"
        }
    }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .foodSleep:
            "Food & Sleep"
        case .mindsetFeeling:
            "Mindset & Feeling"
        case .pattern:
            "Pattern"
        case .encouragement:
            "Encouragement"
        }
    }
}

/// Represents an AI-generated insight based on the user's historical data.
/// Insights are generated overnight and shown the next morning after sleep quality is logged.
struct DailyInsight: Codable, Identifiable, Equatable {
    /// Unique identifier for this insight
    let id: UUID

    /// The date this insight was generated for (typically yesterday's patterns)
    let date: Date

    /// The AI-generated insight text (aim for <50 words)
    let insightText: String

    /// The type of insight (food-sleep correlation, mindset-feeling, etc.)
    let insightType: InsightType

    /// AI confidence in this insight (0.0 to 1.0)
    let confidence: Double

    /// Whether the user has seen/dismissed this insight
    var isViewed: Bool

    // MARK: - Initialization

    /// Creates a new daily insight with all properties.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - date: The date this insight is for
    ///   - insightText: The AI-generated insight message
    ///   - insightType: The category of insight
    ///   - confidence: AI confidence level (0.0-1.0)
    ///   - isViewed: Whether user has seen it (defaults to false)
    init(
        id: UUID = UUID(),
        date: Date,
        insightText: String,
        insightType: InsightType,
        confidence: Double,
        isViewed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.insightText = insightText
        self.insightType = insightType
        self.confidence = confidence
        self.isViewed = isViewed
    }

    // MARK: - Methods

    /// Marks this insight as viewed by the user.
    mutating func markAsViewed() {
        self.isViewed = true
    }
}
