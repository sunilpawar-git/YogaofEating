import Foundation

// swiftlint:disable identifier_name switch_case_on_newline
enum ReflectionFeeling: String, Codable, CaseIterable {
    case great
    case calm
    case ok
    case tired
    case heavy

    /// Emoji representation for UI display
    var emoji: String {
        switch self {
        case .great: "😊"
        case .calm: "😌"
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

/// Represents the user's sleep quality for morning reflection.
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

// swiftlint:enable identifier_name switch_case_on_newline

/// Captures the user's daily reflection about sleep quality (morning) and overall feeling (evening).
/// Supports separate logging of sleep and feeling at different times of day.
struct DailyReflection: Codable, Equatable {
    // MARK: - Properties

    /// How the user felt overall based on their eating (optional - logged in evening)
    let feeling: ReflectionFeeling?

    /// Sleep quality assessment (optional - logged in morning)
    let sleepQuality: SleepQuality?

    /// Optional free-form note from the user
    let note: String?

    /// When the reflection was created/last modified
    let timestamp: Date

    /// When sleep quality was logged (morning)
    let sleepLoggedAt: Date?

    /// When overall feeling was logged (evening)
    let feelingLoggedAt: Date?

    /// Morning energy level on a 1-5 scale (logged alongside sleep quality)
    let morningEnergyLevel: Int?

    /// Short daily eating intention set in the morning (~140 chars max)
    let dailyIntention: String?

    /// Mid-day focus rating (1=scattered, 2=okay, 3=locked-in)
    let focusRating: Int?

    // MARK: - Computed Properties

    /// Returns true if sleep quality has been logged
    var hasSleepLogged: Bool {
        self.sleepQuality != nil
    }

    /// Returns true if overall feeling has been logged
    var hasFeelingLogged: Bool {
        self.feeling != nil
    }

    // MARK: - Initialization

    /// Creates a new daily reflection with all properties.
    /// - Parameters:
    ///   - feeling: How the user felt (optional)
    ///   - sleepQuality: Sleep quality (optional)
    ///   - sleepLoggedAt: When sleep was logged (optional)
    ///   - feelingLoggedAt: When feeling was logged (optional)
    ///   - note: Optional free-form note
    ///   - timestamp: When recorded (defaults to now)
    init(
        feeling: ReflectionFeeling? = nil,
        sleepQuality: SleepQuality? = nil,
        sleepLoggedAt: Date? = nil,
        feelingLoggedAt: Date? = nil,
        morningEnergyLevel: Int? = nil,
        dailyIntention: String? = nil,
        focusRating: Int? = nil,
        note: String? = nil,
        timestamp: Date = Date()
    ) {
        self.feeling = feeling
        self.sleepQuality = sleepQuality
        self.sleepLoggedAt = sleepLoggedAt
        self.feelingLoggedAt = feelingLoggedAt
        self.morningEnergyLevel = morningEnergyLevel.map { max(1, min($0, 5)) }
        self.dailyIntention = dailyIntention.map { String($0.prefix(200)) }
        self.focusRating = focusRating.map { max(1, min($0, 3)) }
        self.note = note.map { String($0.prefix(500)) }
        self.timestamp = timestamp
    }

    // MARK: - Factory Methods

    /// Creates a reflection with only sleep quality logged.
    /// - Parameters:
    ///   - quality: The sleep quality
    ///   - date: When it was logged (defaults to now)
    /// - Returns: A new DailyReflection with sleep data
    static func withSleepQuality(_ quality: SleepQuality, at date: Date = Date()) -> DailyReflection {
        DailyReflection(
            sleepQuality: quality,
            sleepLoggedAt: date,
            timestamp: date
        )
    }

    /// Creates a reflection with only overall feeling logged.
    /// - Parameters:
    ///   - feeling: The overall feeling
    ///   - date: When it was logged (defaults to now)
    /// - Returns: A new DailyReflection with feeling data
    static func withFeeling(_ feeling: ReflectionFeeling, at date: Date = Date()) -> DailyReflection {
        DailyReflection(
            feeling: feeling,
            feelingLoggedAt: date,
            timestamp: date
        )
    }

    /// Creates a reflection with morning energy level and daily intention.
    /// - Parameters:
    ///   - energyLevel: Morning energy (1-5)
    ///   - intention: Daily eating intention
    ///   - date: When it was logged (defaults to now)
    /// - Returns: A new DailyReflection with reflect data
    static func withReflect(
        energyLevel: Int,
        intention: String,
        at date: Date = Date()
    ) -> DailyReflection {
        DailyReflection(
            morningEnergyLevel: energyLevel,
            dailyIntention: intention,
            timestamp: date
        )
    }

    /// Merges this reflection with another, combining sleep and feeling data.
    /// - Parameter other: The other reflection to merge with
    /// - Returns: A new DailyReflection with combined data
    func merging(with other: DailyReflection) -> DailyReflection {
        DailyReflection(
            feeling: self.feeling ?? other.feeling,
            sleepQuality: self.sleepQuality ?? other.sleepQuality,
            sleepLoggedAt: self.sleepLoggedAt ?? other.sleepLoggedAt,
            feelingLoggedAt: self.feelingLoggedAt ?? other.feelingLoggedAt,
            morningEnergyLevel: self.morningEnergyLevel ?? other.morningEnergyLevel,
            dailyIntention: self.dailyIntention ?? other.dailyIntention,
            focusRating: self.focusRating ?? other.focusRating,
            note: self.note ?? other.note,
            timestamp: max(self.timestamp, other.timestamp)
        )
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case feeling
        case sleepQuality
        case note
        case timestamp
        case sleepLoggedAt
        case feelingLoggedAt
        case morningEnergyLevel
        case dailyIntention
        case focusRating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.feeling = try container.decodeIfPresent(ReflectionFeeling.self, forKey: .feeling)
        self.sleepQuality = try container.decodeIfPresent(SleepQuality.self, forKey: .sleepQuality)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.sleepLoggedAt = try container.decodeIfPresent(Date.self, forKey: .sleepLoggedAt)
        self.feelingLoggedAt = try container.decodeIfPresent(Date.self, forKey: .feelingLoggedAt)
        self.morningEnergyLevel = try container.decodeIfPresent(Int.self, forKey: .morningEnergyLevel)
        self.dailyIntention = try container.decodeIfPresent(String.self, forKey: .dailyIntention)
        self.focusRating = try container.decodeIfPresent(Int.self, forKey: .focusRating)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.feeling, forKey: .feeling)
        try container.encodeIfPresent(self.sleepQuality, forKey: .sleepQuality)
        try container.encodeIfPresent(self.note, forKey: .note)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encodeIfPresent(self.sleepLoggedAt, forKey: .sleepLoggedAt)
        try container.encodeIfPresent(self.feelingLoggedAt, forKey: .feelingLoggedAt)
        try container.encodeIfPresent(self.morningEnergyLevel, forKey: .morningEnergyLevel)
        try container.encodeIfPresent(self.dailyIntention, forKey: .dailyIntention)
        try container.encodeIfPresent(self.focusRating, forKey: .focusRating)
    }
}
