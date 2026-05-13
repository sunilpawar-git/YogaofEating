import Foundation

/// Represents a fasting period between two consecutive meals.
struct FastingPeriod: Identifiable, Equatable {
    let id: UUID
    let startMealId: UUID
    let endMealId: UUID
    let startTime: Date
    let endTime: Date

    /// Duration of the fasting period in seconds.
    /// Returns 0 for invalid ranges (endTime before startTime) rather than a negative value.
    var duration: TimeInterval {
        max(0, self.endTime.timeIntervalSince(self.startTime))
    }

    /// Duration in hours (for display and calculations)
    var durationInHours: Double {
        self.duration / FastingConstants.secondsPerHour
    }

    /// Formatted duration string for display (e.g., "45m", "1h", "16h 30m").
    /// Returns "0m" for invalid/zero-length periods.
    var formattedDuration: String {
        guard self.duration > 0 else { return "0m" }
        let hours = Int(self.duration / FastingConstants.secondsPerHour)
        let minutes = Int(
            self.duration.truncatingRemainder(dividingBy: FastingConstants.secondsPerHour)
                / FastingConstants.secondsPerMinute
        )
        if hours == 0 {
            // Sub-hour gaps: show minutes only (e.g. "32m", "45m")
            return "\(minutes)m"
        } else if minutes >= 30 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(hours)h"
        }
    }

    /// Whether this is a significant fasting period (12+ hours per `FastingConstants.significanceHoursThreshold`)
    var isSignificant: Bool {
        self.durationInHours >= FastingConstants.significanceHoursThreshold
    }

    /// Glow intensity based on fasting duration (0.0 to 1.0)
    /// Scales from `significanceHoursThreshold` (minimum glow) to 20h+ (maximum glow).
    /// Returns 0.0 for zero-duration periods.
    var glowIntensity: Double {
        guard self.isSignificant else { return 0.0 }
        let minHours = FastingConstants.significanceHoursThreshold
        let maxHours = 20.0
        let normalized = (self.durationInHours - minHours) / (maxHours - minHours)
        return min(max(normalized, 0.3), 1.0)
    }

    init(
        id: UUID = UUID(),
        startMealId: UUID,
        endMealId: UUID,
        startTime: Date,
        endTime: Date
    ) {
        self.id = id
        self.startMealId = startMealId
        self.endMealId = endMealId
        self.startTime = startTime
        self.endTime = endTime
    }
}
