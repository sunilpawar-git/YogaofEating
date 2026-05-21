import Foundation

// MARK: - WellbeingDimensions

struct WellbeingDimensions: Codable, Equatable {
    let physicalLoad: Double
    let emotionalTone: Double
    let cognitiveClarity: Double
    let behavioralMomentum: Double

    var overall: Double {
        (self.physicalLoad + self.emotionalTone + self.cognitiveClarity + self.behavioralMomentum) / 4.0
    }

    init(physicalLoad: Double, emotionalTone: Double, cognitiveClarity: Double, behavioralMomentum: Double) {
        self.physicalLoad = min(max(physicalLoad, 0), 1)
        self.emotionalTone = min(max(emotionalTone, 0), 1)
        self.cognitiveClarity = min(max(cognitiveClarity, 0), 1)
        self.behavioralMomentum = min(max(behavioralMomentum, 0), 1)
    }

    static let neutral = WellbeingDimensions(
        physicalLoad: 0.5,
        emotionalTone: 0.5,
        cognitiveClarity: 0.5,
        behavioralMomentum: 0.5
    )
}

// MARK: - WellbeingDimension

enum WellbeingDimension: String, Codable, CaseIterable, Equatable {
    case physicalLoad
    case emotionalTone
    case cognitiveClarity
    case behavioralMomentum

    var displayName: String {
        switch self {
        case .physicalLoad: Strings.Synthesis.Dimension.physicalLoad
        case .emotionalTone: Strings.Synthesis.Dimension.emotionalTone
        case .cognitiveClarity: Strings.Synthesis.Dimension.cognitiveClarity
        case .behavioralMomentum: Strings.Synthesis.Dimension.behavioralMomentum
        }
    }

    func subtitle(mealCount: Int) -> String {
        switch self {
        case .physicalLoad:
            let noun = mealCount == 1
                ? Strings.WellbeingBreakdown.DimensionSubtitle.physicalLoad_meal
                : Strings.WellbeingBreakdown.DimensionSubtitle.physicalLoad_meals
            return String(
                format: Strings.WellbeingBreakdown.DimensionSubtitle.physicalLoad_fmt,
                mealCount, noun
            )
        case .emotionalTone: return Strings.WellbeingBreakdown.DimensionSubtitle.emotionalTone
        case .cognitiveClarity: return Strings.WellbeingBreakdown.DimensionSubtitle.cognitiveClarity
        case .behavioralMomentum: return Strings.WellbeingBreakdown.DimensionSubtitle.behavioralMomentum
        }
    }

    func value(in dimensions: WellbeingDimensions) -> Double {
        switch self {
        case .physicalLoad: dimensions.physicalLoad
        case .emotionalTone: dimensions.emotionalTone
        case .cognitiveClarity: dimensions.cognitiveClarity
        case .behavioralMomentum: dimensions.behavioralMomentum
        }
    }
}

// MARK: - TextSignal

enum TextSignal: String, Codable, CaseIterable, Equatable {
    case stressed
    case clear
    case overwhelmed
    case grateful
    case agentive
    case selfCompassionate
    case neutral

    var displayName: String {
        switch self {
        case .stressed: Strings.Synthesis.Signal.stressed
        case .clear: Strings.Synthesis.Signal.clear
        case .overwhelmed: Strings.Synthesis.Signal.overwhelmed
        case .grateful: Strings.Synthesis.Signal.grateful
        case .agentive: Strings.Synthesis.Signal.agentive
        case .selfCompassionate: Strings.Synthesis.Signal.selfCompassionate
        case .neutral: Strings.Synthesis.Signal.neutral
        }
    }
}

// MARK: - SynthesisTrigger

enum SynthesisTrigger: String, Codable, CaseIterable, Equatable {
    case mealUpdated
    case sleepLogged
    case journalSaved
    case todoCompleted
    case feelingUpdated
    case morningThoughtsChanged
}
