import Foundation

/// Single source of truth for fasting domain constants.
///
/// These are pure time/physics values used by Foundation-layer models.
/// They must not live in a SwiftUI theme file because `FastingPeriod` (a plain Model)
/// would otherwise need to import SwiftUI — a layer inversion.
enum FastingConstants {
    /// Seconds per hour — avoids magic 3600 in duration calculations.
    static let secondsPerHour: Double = 3600

    /// Seconds per minute — avoids magic 60 in duration formatting.
    static let secondsPerMinute: Double = 60

    /// Minimum fasting duration (in hours) to be considered significant (12 h+).
    static let significanceHoursThreshold: Double = 12.0
}
