import Foundation

/// Shared subjective sleep score mapping used by `BodyIntelligenceService` and `TrendDataService`.
/// Centralised here (SSOT) to prevent drift between implementations.
extension SleepQuality {
    /// Converts subjective sleep quality to a numeric score in 0–100.
    var subjectiveScore: Double {
        switch self {
        case .great: 90
        case .good: 70
        case .poor: 45
        case .terrible: 20
        }
    }
}
