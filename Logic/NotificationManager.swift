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
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}

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
                notifLogger.error("Notification permission error: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// The "Morning Nudge" to plan the day's meals.
    func scheduleMorningNudge() {
        guard UserDefaults.standard.object(forKey: StorageKeys.morningNudgeEnabled) as? Bool ?? true else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Time to plan your mindful meals for today. The Smiley is waiting for you 🙂"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 8 // 8:00 AM

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_nudge", content: content, trigger: trigger)

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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morning_nudge"])
    }

    /// Cancels all meal reminder notifications (Breakfast, Lunch, Dinner).
    func cancelMealReminders() {
        let ids = ["meal_reminder_Breakfast", "meal_reminder_Lunch", "meal_reminder_Dinner"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Clears all pending notifications.
    func cancelAllNotifications() {
        self.center.removeAllPendingNotificationRequests()
    }
}
