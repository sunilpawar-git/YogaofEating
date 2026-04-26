import Foundation

/// Represents the current phase of the day, used to auto-select
/// which module card is most relevant on the home screen.
enum DayPhase: Equatable {
    case morning
    case midday
    case evening

    /// Determines the day phase from a 24-hour clock value.
    /// - Parameter hour: Hour in 0-23 range
    /// - Returns: The corresponding day phase
    static func current(at hour: Int) -> DayPhase {
        switch hour {
        case 0..<12: .morning
        case 12..<17: .midday
        default: .evening
        }
    }

    /// Convenience: current phase based on the system clock.
    static var now: DayPhase {
        current(at: Calendar.current.component(.hour, from: Date()))
    }
}
