import Foundation
import SwiftUI

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

    /// How well meals aligned with the user's stated daily intention
    case intentAlignment

    /// Correlation between focus level and food choices
    case focusFood

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
        case .intentAlignment:
            "target"
        case .focusFood:
            "bolt.circle"
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
        case .intentAlignment:
            "Intent Alignment"
        case .focusFood:
            "Focus & Food"
        }
    }

    /// Accent gradient for card backgrounds (shared across InsightCardView and InsightBottomSheet).
    func gradient(intensity: Double = 0.3) -> LinearGradient {
        let secondary = intensity * 0.66
        return switch self {
        case .foodSleep:
            LinearGradient(
                colors: [.indigo.opacity(intensity), .purple.opacity(secondary)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mindsetFeeling:
            LinearGradient(
                colors: [.teal.opacity(intensity), .cyan.opacity(secondary)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pattern:
            LinearGradient(
                colors: [.orange.opacity(intensity), .yellow.opacity(secondary)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .encouragement:
            LinearGradient(
                colors: [.green.opacity(intensity), .mint.opacity(secondary)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .intentAlignment:
            LinearGradient(
                colors: [.blue.opacity(intensity), .indigo.opacity(secondary)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .focusFood:
            LinearGradient(
                colors: [.yellow.opacity(intensity), .orange.opacity(secondary)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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

    /// References to specific data points that support this insight
    let references: [InsightReference]

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, date, insightText, insightType, confidence, isViewed, references
    }

    // MARK: - Initialization

    /// Creates a new daily insight with all properties.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - date: The date this insight is for
    ///   - insightText: The AI-generated insight message
    ///   - insightType: The category of insight
    ///   - confidence: AI confidence level (0.0-1.0)
    ///   - isViewed: Whether user has seen it (defaults to false)
    ///   - references: Data point references (defaults to empty)
    init(
        id: UUID = UUID(),
        date: Date,
        insightText: String,
        insightType: InsightType,
        confidence: Double,
        isViewed: Bool = false,
        references: [InsightReference] = []
    ) {
        self.id = id
        self.date = date
        self.insightText = String(insightText.prefix(500))
        self.insightType = insightType
        self.confidence = max(0.0, min(confidence, 1.0))
        self.isViewed = isViewed
        self.references = references
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.insightText = try container.decode(String.self, forKey: .insightText)
        self.insightType = try container.decode(InsightType.self, forKey: .insightType)
        let rawConfidence = try container.decode(Double.self, forKey: .confidence)
        self.confidence = max(0.0, min(rawConfidence, 1.0))
        self.isViewed = try container.decodeIfPresent(Bool.self, forKey: .isViewed) ?? false
        self.references = try container.decodeIfPresent([InsightReference].self, forKey: .references) ?? []
    }

    // MARK: - Methods

    /// Marks this insight as viewed by the user.
    mutating func markAsViewed() {
        self.isViewed = true
    }

    /// Returns true if this insight has specific data references
    var hasReferences: Bool {
        !self.references.isEmpty
    }
}
