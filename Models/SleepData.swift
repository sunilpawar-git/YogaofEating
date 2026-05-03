import Foundation

// MARK: - Sleep Data Model

/// Represents sleep data fetched from HealthKit
struct SleepData: Equatable {
    /// Total time spent sleeping (in seconds)
    let sleepDuration: TimeInterval

    /// Total time in bed (in seconds)
    let timeInBed: TimeInterval

    /// When sleep started
    let sleepStart: Date?

    /// When sleep ended
    let sleepEnd: Date?

    /// Calculated sleep score (0-100)
    let sleepScore: Double?

    /// Maps sleep score to SleepQuality enum
    var sleepQuality: SleepQuality? {
        guard let score = sleepScore else { return nil }

        if score >= 80 {
            return .great
        } else if score >= 60 {
            return .good
        } else if score >= 40 {
            return .poor
        } else {
            return .terrible
        }
    }

    /// Sleep efficiency percentage (0-100)
    var efficiency: Double {
        guard self.timeInBed > 0 else { return 0 }
        return (self.sleepDuration / self.timeInBed) * 100.0
    }

    /// Formatted sleep duration (e.g., "7h 30m")
    var formattedDuration: String {
        let hours = Int(sleepDuration / 3600)
        let minutes = Int((sleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Sleep Sample Data (for processing)

/// Intermediate representation of a sleep sample for processing
struct SleepSampleData {
    let startDate: Date
    let endDate: Date
    let sleepStage: SleepStage

    var duration: TimeInterval {
        self.endDate.timeIntervalSince(self.startDate)
    }

    var isAsleep: Bool {
        switch self.sleepStage {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            true
        case .inBed, .awake:
            false
        }
    }
}

/// Sleep stages from HealthKit
enum SleepStage: CustomStringConvertible {
    case inBed
    case asleepUnspecified
    case asleepCore
    case asleepDeep
    case asleepREM
    case awake

    var description: String {
        switch self {
        case .inBed:
            "In Bed"
        case .asleepUnspecified:
            "Asleep (Unspecified)"
        case .asleepCore:
            "Asleep (Core)"
        case .asleepDeep:
            "Asleep (Deep)"
        case .asleepREM:
            "Asleep (REM)"
        case .awake:
            "Awake"
        }
    }
}
