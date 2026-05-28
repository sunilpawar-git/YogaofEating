import Foundation
import OSLog
import UserNotifications

private let notifLogger = Logger(subsystem: "com.yogaofeating", category: "Notifications")

/// Protocol to allow mocking of UNUserNotificationCenter
protocol NotificationCenterProtocol: Sendable {
    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping @Sendable (Bool, Error?) -> Void
    )
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
    func removeAllPendingNotificationRequests()
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}

/// Protocol for scheduling and cancelling app notifications.
/// Enables injection of a test double in place of `NotificationManager.shared`.
protocol NotificationScheduling {
    func scheduleMorningNudge(at time: Date)
    func cancelMorningNudge()
    func scheduleDefaultMealReminders()
    func cancelMealReminders()
}

/// Manages mindful nudges and meal planning reminders.
class NotificationManager {
    static let shared = NotificationManager()
    private let center: NotificationCenterProtocol

    init(center: NotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = center
    }

    func requestPermissions() {
        self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                notifLogger.info("Notification permissions granted")
            } else if let error {
                notifLogger.error("Notification permission error: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    /// The "Morning Nudge" to plan the day's meals.
    /// Reads the nudge-enabled flag from UserDefaults; used on app launch.
    func scheduleMorningNudge() {
        guard UserDefaults.standard.object(forKey: StorageKeys.morningNudgeEnabled) as? Bool ?? true else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Time to plan your mindful meals for today. The Smiley is waiting for you \u{1F642}"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 8 // 8:00 AM

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_nudge", content: content, trigger: trigger)

        self.center.add(request, withCompletionHandler: nil)
    }

    /// Schedules the morning nudge at a user-configured time.
    /// The caller is responsible for checking whether the nudge is enabled before calling.
    /// Cancels any existing morning nudge before scheduling the new one.
    func scheduleMorningNudge(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Time to plan your mindful meals for today. The Smiley is waiting for you \u{1F642}"
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: time)
        dateComponents.minute = calendar.component(.minute, from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_nudge", content: content, trigger: trigger)

        self.center.removePendingNotificationRequests(withIdentifiers: ["morning_nudge"])
        self.center.add(request, withCompletionHandler: nil)
    }

    /// Individual meal reminders.
    func scheduleMealReminder(label: String, hour: Int, minute: Int) {
        guard UserDefaults.standard.object(forKey: StorageKeys.mealRemindersEnabled) as? Bool ?? true else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Meal Time"
        content.body = "What are you planning for \(label.lowercased())? Let your friend know."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "meal_reminder_\(label)", content: content, trigger: trigger)

        self.center.add(request, withCompletionHandler: nil)
    }

    /// Schedules default meal reminders (Breakfast, Lunch, Dinner).
    /// Called on app startup.
    func scheduleDefaultMealReminders() {
        self.scheduleMealReminder(label: "Breakfast", hour: 8, minute: 0)
        self.scheduleMealReminder(label: "Lunch", hour: 13, minute: 0)
        self.scheduleMealReminder(label: "Dinner", hour: 20, minute: 0)
    }

    /// Cancels only the morning nudge notification, leaving other notifications intact.
    func cancelMorningNudge() {
        self.center.removePendingNotificationRequests(withIdentifiers: ["morning_nudge"])
    }

    /// Cancels all meal reminder notifications (Breakfast, Lunch, Dinner).
    func cancelMealReminders() {
        let ids = ["meal_reminder_Breakfast", "meal_reminder_Lunch", "meal_reminder_Dinner"]
        self.center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Schedules a local notification for the daily briefing using A/B test variant.
    /// The notification time depends on the assigned A/B test variant.
    /// Called after briefing is generated and ready to display.
    func scheduleBriefingNotification(headline: String, userId: String) {
        let variant = NotificationTimingABTest.getCurrentVariant(for: userId)

        guard let scheduledTime = NotificationTimingABTest.scheduleNotification(
            headline: headline,
            variant: variant,
            userId: userId
        ) else {
            notifLogger.warning("Failed to schedule briefing notification for variant: \(variant.rawValue)")
            return
        }

        // Log the scheduling event for analytics
        NotificationTimingABTest.logNotificationScheduled(
            userId: userId,
            variant: variant,
            scheduledTime: scheduledTime
        )

        notifLogger
            .info(
                "Briefing notification scheduled [\(variant.rawValue)]: \(scheduledTime.formatted(date: .abbreviated, time: .shortened))"
            )
    }

    /// Cancels any pending briefing notification.
    func cancelBriefingNotification() {
        self.center.removePendingNotificationRequests(
            withIdentifiers: [NotificationTimingABTest.briefingNotificationIdentifier]
        )
    }

    /// Clears all pending notifications.
    func cancelAllNotifications() {
        self.center.removeAllPendingNotificationRequests()
    }
}

extension NotificationManager: NotificationScheduling {}
