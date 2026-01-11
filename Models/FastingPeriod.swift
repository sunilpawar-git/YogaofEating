import Foundation

/// Represents a fasting period between two consecutive meals.
struct FastingPeriod: Identifiable, Equatable {
    let id: UUID
    let startMealId: UUID
    let endMealId: UUID
    let startTime: Date
    let endTime: Date

    /// Duration of the fasting period in seconds
    var duration: TimeInterval {
        self.endTime.timeIntervalSince(self.startTime)
    }

    /// Duration in hours (for display and calculations)
    var durationInHours: Double {
        self.duration / 3600.0
    }

    /// Formatted duration string for display (e.g., "14h", "16h 30m")
    var formattedDuration: String {
        let hours = Int(self.duration / 3600)
        let minutes = Int((self.duration.truncatingRemainder(dividingBy: 3600)) / 60)

        // Only show minutes if >= 30 minutes
        if minutes >= 30 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(hours)h"
        }
    }

    /// Whether this is a significant fasting period (12+ hours)
    var isSignificant: Bool {
        self.durationInHours >= 12.0
    }

    /// Glow intensity based on fasting duration (0.0 to 1.0)
    /// Scales from 12h (minimum glow) to 20h+ (maximum glow)
    var glowIntensity: Double {
        guard self.isSignificant else { return 0.0 }

        let minHours = 12.0
        let maxHours = 20.0
        let normalized = (self.durationInHours - minHours) / (maxHours - minHours)
        return min(max(normalized, 0.3), 1.0) // Clamp between 0.3 and 1.0
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

