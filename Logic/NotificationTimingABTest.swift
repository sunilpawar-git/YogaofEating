import OSLog
import SwiftUI
import UserNotifications

private let abTestLogger = Logger(subsystem: "com.yogaofeating", category: "ABTest")

/**
 * A/B Testing Manager for Daily Briefing Notification Timing
 *
 * Variants:
 * - .fixed(hour: 7, minute: 30) — Traditional 7:30 AM (Control)
 * - .adaptive — Based on user's typical wake time (Variant A)
 * - .smartDelay(secondsAfter: 120) — 2min after sleep log (Variant B)
 *
 * Usage:
 *   let timing = NotificationTimingABTest.getCurrentVariant(for: userId)
 *   await NotificationTimingABTest.scheduleNotification(
 *       headline: "...",
 *       timing: timing,
 *       userId: userId
 *   )
 */

enum NotificationTimingVariant: String, Codable {
    case fixed_730am // Control: 7:30 AM
    case adaptive_wakeTime = "adaptive" // Variant A: Based on user wake time
    case smartDelay_2min = "smartDelay" // Variant B: 2 min after sleep log
}

struct NotificationTimingConfig: Codable {
    let variant: NotificationTimingVariant
    let assignedDate: Date
    let targetDate: Date? // Computed time for this notification
}

class NotificationTimingABTest {
    static let briefingNotificationIdentifier = "morning_briefing"

    private static let userDefaultsKey = "briefing_notification_timing_config"
    private static let variantWeights: [(NotificationTimingVariant, Double)] = [
        (.fixed_730am, 0.50),
        (.adaptive_wakeTime, 0.25),
        (.smartDelay_2min, 0.25)
    ]

    // MARK: - Assignment & Retrieval

    /**
     * Get or assign A/B test variant for a user
     * Persists assignment in UserDefaults for consistency across sessions
     */
    static func getCurrentVariant(for userId: String) -> NotificationTimingVariant {
        let defaults = UserDefaults.standard
        let cacheKey = "\(userDefaultsKey)_\(userId)"

        if let cached = defaults.string(forKey: cacheKey),
           let variant = NotificationTimingVariant(rawValue: cached)
        {
            return variant
        }

        // Assign new variant based on distribution
        let assigned = self._assignVariant()
        defaults.set(assigned.rawValue, forKey: cacheKey)

        abTestLogger
            .info("Assigned variant '\(assigned.rawValue, privacy: .public)' to user \(userId, privacy: .private)")

        return assigned
    }

    /**
     * Reset variant for testing purposes (admin only)
     */
    static func resetVariantForUser(_ userId: String) {
        let defaults = UserDefaults.standard
        let cacheKey = "\(userDefaultsKey)_\(userId)"
        defaults.removeObject(forKey: cacheKey)
    }

    private static func _assignVariant() -> NotificationTimingVariant {
        let rand = Double.random(in: 0..<1.0)
        var cumulative: Double = 0

        for (variant, probability) in Self.variantWeights {
            cumulative += probability
            if rand < cumulative {
                return variant
            }
        }

        return .fixed_730am
    }

    // MARK: - Notification Scheduling

    /**
     * Schedule briefing notification with selected timing variant
     * Returns the actual scheduled time for logging/analysis
     */
    static func scheduleNotification(
        headline: String,
        variant: NotificationTimingVariant,
        userId: String,
        for _: Date = Date()
    ) -> Date? {
        let scheduler = NotificationScheduler()

        switch variant {
        case .fixed_730am:
            return scheduler.scheduleFixed(headline: headline, at: (7, 30))

        case .adaptive_wakeTime:
            let wakeTime = WakeTimePredictor.predictWakeTime(for: userId)
            let (hour, minute) = wakeTime
            return scheduler.scheduleFixed(headline: headline, at: (hour, minute))

        case .smartDelay_2min:
            let delaySeconds = 120
            return scheduler.scheduleDelay(headline: headline, delaySeconds: delaySeconds)
        }
    }

    // MARK: - Analytics & Logging

    /**
     * Log notification scheduling event for analysis
     */
    static func logNotificationScheduled(
        userId: String,
        variant: NotificationTimingVariant,
        scheduledTime: Date
    ) {
        let event = [
            "event": "briefing_notification_scheduled",
            "userId": userId,
            "variant": variant.rawValue,
            "scheduledTime": ISO8601DateFormatter().string(from: scheduledTime),
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        // Log to analytics backend (Firebase Analytics, Amplitude, etc.)
        abTestLogger.info("Notification scheduled: \(event.description, privacy: .public)")
    }

    /**
     * Log notification tap-through for engagement analysis
     */
    static func logNotificationTapped(
        userId: String,
        variant: NotificationTimingVariant,
        delayFromScheduleSeconds: Int
    ) {
        let event: [String: Any] = [
            "event": "briefing_notification_tapped",
            "userId": userId,
            "variant": variant.rawValue,
            "delaySeconds": delayFromScheduleSeconds,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        abTestLogger.info("Notification tapped: \(event.description, privacy: .public)")
    }
}

// MARK: - Helper: Notification Scheduling

class NotificationScheduler {
    /**
     * Schedule notification at fixed time
     */
    func scheduleFixed(headline: String, at time: (hour: Int, minute: Int)) -> Date? {
        let content = UNMutableNotificationContent()
        content.title = "Your Morning Briefing"
        content.body = headline
        content.sound = .default
        content.categoryIdentifier = "briefing"

        var dateComponents = DateComponents()
        dateComponents.hour = time.hour
        dateComponents.minute = time.minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: NotificationTimingABTest.briefingNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

        return Calendar.current.nextDate(
            after: Date(),
            matching: dateComponents,
            matchingPolicy: .nextTimePreservingSmallerComponents
        )
    }

    /**
     * Schedule notification with delay from now
     */
    func scheduleDelay(headline: String, delaySeconds: Int) -> Date? {
        let content = UNMutableNotificationContent()
        content.title = "Your Morning Briefing"
        content.body = headline
        content.sound = .default
        content.categoryIdentifier = "briefing"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(delaySeconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: NotificationTimingABTest.briefingNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

        return Date().addingTimeInterval(TimeInterval(delaySeconds))
    }
}

// MARK: - Helper: Wake Time Prediction

enum WakeTimePredictor {
    /**
     * Predict user's typical wake time based on historical HealthKit data
     * or user preferences, defaulting to 7:00 AM if unknown
     */
    static func predictWakeTime(for userId: String) -> (hour: Int, minute: Int) {
        let userDefaults = UserDefaults.standard
        let key = "user_wake_time_\(userId)"

        if let stored = userDefaults.string(forKey: key) {
            let parts = stored.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2,
               (0...23).contains(parts[0]),
               (0...59).contains(parts[1])
            {
                return (parts[0], parts[1])
            }
        }

        return (7, 0)
    }

    /**
     * Update stored wake time (called after observing user patterns)
     */
    static func updateWakeTime(_ time: (hour: Int, minute: Int), for userId: String) {
        let userDefaults = UserDefaults.standard
        let key = "user_wake_time_\(userId)"
        userDefaults.set("\(time.hour):\(time.minute)", forKey: key)
    }
}

// MARK: - SwiftUI Integration Example

#if DEBUG
    struct NotificationTimingABTestView: View {
        @State private var selectedVariant = NotificationTimingVariant.fixed_730am
        @State private var userId: String = "user-id-123"
        @State private var testOutput: String = ""

        var body: some View {
            NavigationStack {
                Form {
                    Section("A/B Test Variant") {
                        Picker("Select Variant", selection: self.$selectedVariant) {
                            Text("Fixed 7:30 AM (Control)").tag(NotificationTimingVariant.fixed_730am)
                            Text("Adaptive Wake Time").tag(NotificationTimingVariant.adaptive_wakeTime)
                            Text("Smart Delay (2min)").tag(NotificationTimingVariant.smartDelay_2min)
                        }
                    }

                    Section("Test Actions") {
                        Button("Schedule Test Notification") {
                            let scheduledTime = NotificationTimingABTest.scheduleNotification(
                                headline: "Test briefing notification",
                                variant: self.selectedVariant,
                                userId: self.userId
                            )

                            if let time = scheduledTime {
                                self.testOutput = "Scheduled for: \(time.formatted(date: .abbreviated, time: .shortened))"
                            } else {
                                self.testOutput = "Failed to schedule"
                            }
                        }

                        Button("Log Engagement Event", action: {
                            NotificationTimingABTest.logNotificationTapped(
                                userId: self.userId,
                                variant: self.selectedVariant,
                                delayFromScheduleSeconds: 120
                            )
                            self.testOutput = "Engagement logged"
                        })

                        Button("Reset Test for User", role: .destructive, action: {
                            NotificationTimingABTest.resetVariantForUser(self.userId)
                            self.testOutput = "Test reset"
                        })
                    }

                    Section("Output") {
                        Text(self.testOutput)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Notification A/B Test")
            }
        }
    }

    #Preview {
        NotificationTimingABTestView()
    }
#endif
