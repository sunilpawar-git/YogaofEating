import Foundation

/// Represents how the user felt at the end of the day based on their eating.
/// Part of the "Yoga of Eating" mindfulness tracking.
enum ReflectionFeeling: String, Codable, CaseIterable {
    case great
    case calm
    case ok
    case tired
    case heavy

    /// Emoji representation for UI display
    var emoji: String {
        switch self {
        case .great: "😴"
        case .calm: "😊"
        case .ok: "😐"
        case .tired: "🥱"
        case .heavy: "😣"
        }
    }

    /// Human-readable display name
    var displayName: String {
        self.rawValue.capitalized
    }
}

/// Represents the user's sleep quality for end-of-day reflection.
enum SleepQuality: String, Codable, CaseIterable {
    case great
    case good
    case poor
    case terrible

    /// Emoji representation for UI display
    var emoji: String {
        switch self {
        case .great: "😴"
        case .good: "🙂"
        case .poor: "😕"
        case .terrible: "😫"
        }
    }

    /// Human-readable display name
    var displayName: String {
        self.rawValue.capitalized
    }
}

/// Captures the user's end-of-day reflection about how their eating affected them.
/// This is an optional addition to the daily snapshot for mindful eating awareness.
struct DailyReflection: Codable, Equatable {
    // MARK: - Properties

    /// How the user felt overall based on their eating (required)
    let feeling: ReflectionFeeling

    /// Optional sleep quality assessment
    let sleepQuality: SleepQuality?

    /// Optional free-form note from the user
    let note: String?

    /// When the reflection was recorded
    let timestamp: Date

    // MARK: - Initialization

    /// Creates a new daily reflection with all properties.
    /// - Parameters:
    ///   - feeling: How the user felt (required)
    ///   - sleepQuality: Optional sleep quality
    ///   - note: Optional free-form note
    ///   - timestamp: When recorded (defaults to now)
    init(
        feeling: ReflectionFeeling,
        sleepQuality: SleepQuality? = nil,
        note: String? = nil,
        timestamp: Date = Date()
    ) {
        self.feeling = feeling
        self.sleepQuality = sleepQuality
        self.note = note
        self.timestamp = timestamp
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case feeling
        case sleepQuality
        case note
        case timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.feeling = try container.decode(ReflectionFeeling.self, forKey: .feeling)
        self.sleepQuality = try container.decodeIfPresent(SleepQuality.self, forKey: .sleepQuality)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.feeling, forKey: .feeling)
        try container.encodeIfPresent(self.sleepQuality, forKey: .sleepQuality)
        try container.encodeIfPresent(self.note, forKey: .note)
        try container.encode(self.timestamp, forKey: .timestamp)
    }
}
