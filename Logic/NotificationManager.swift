import Foundation
import UserNotifications

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
                print("Notification permissions granted.")
            } else if let error {
                print("Notification permissions error: \(error.localizedDescription)")
            }
        }
    }

    /// The "Morning Nudge" to plan the day's meals.
    func scheduleMorningNudge() {
        guard UserDefaults.standard.bool(forKey: "morning_nudge_enabled") else {
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
        guard UserDefaults.standard.bool(forKey: "meal_reminders_enabled") else {
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

    /// Clears all pending notifications.
    func cancelAllNotifications() {
        self.center.removeAllPendingNotificationRequests()
    }
}
