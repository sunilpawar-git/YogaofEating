import Foundation

/// Pre-Phase1 text-only insight model. Retained for Codable migration during Phase 2.
/// Do not use in new code — use `DailyInsight` instead.
struct LegacyDailyInsight: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let insightText: String
    let insightType: InsightType
    let confidence: Double
    var isViewed: Bool
    let references: [InsightReference]

    enum CodingKeys: String, CodingKey {
        case id, date, insightText, insightType, confidence, isViewed, references
    }

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
        self.insightText = insightText
        self.insightType = insightType
        self.confidence = confidence
        self.isViewed = isViewed
        self.references = references
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.insightText = try container.decode(String.self, forKey: .insightText)
        self.insightType = try container.decode(InsightType.self, forKey: .insightType)
        self.confidence = try container.decode(Double.self, forKey: .confidence)
        self.isViewed = try container.decode(Bool.self, forKey: .isViewed)
        self.references = try container.decodeIfPresent([InsightReference].self, forKey: .references) ?? []
    }

    mutating func markAsViewed() {
        self.isViewed = true
    }

    var hasReferences: Bool { !self.references.isEmpty }
}

/// Legacy insight categorisation. Retained for `LegacyDailyInsight` and `InsightPattern` decoding.
/// Will be deleted in Phase 5 alongside all legacy insight types.
enum InsightType: String, Codable, CaseIterable {
    case foodSleep
    case mindsetFeeling
    case pattern
    case encouragement

    var icon: String {
        switch self {
        case .foodSleep: "moon.zzz.fill"
        case .mindsetFeeling: "brain.head.profile"
        case .pattern: "chart.line.uptrend.xyaxis"
        case .encouragement: "sparkles"
        }
    }

    var displayName: String {
        switch self {
        case .foodSleep: Strings.Insight.InsightType.foodSleep
        case .mindsetFeeling: Strings.Insight.InsightType.mindsetFeeling
        case .pattern: Strings.Insight.InsightType.pattern
        case .encouragement: Strings.Insight.InsightType.encouragement
        }
    }
}
