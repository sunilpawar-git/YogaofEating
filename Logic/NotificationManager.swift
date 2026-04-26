import Foundation
import UserNotifications

/// Protocol to allow mocking of UNUserNotificationCenter
protocol NotificationCenterProtocol: Sendable {
    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping @Sendable (Bool, Error?) -> Void
    )
    func add(
        _ request: UNNotificationRequest,
        withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?
    )
    func removeAllPendingNotificationRequests()
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
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

    // MARK: - Identifiers

    private static let morningNudgeID = "morning_nudge"
    private static let smartNudgePrefix = "smart_nudge_"
    static let maxSmartNudgeSlots = 3

    // MARK: - Morning Nudge

    /// The "Morning Nudge" to plan the day's meals.
    func scheduleMorningNudge() {
        guard UserDefaults.standard.object(
            forKey: StorageKeys.morningNudgeEnabled
        ) as? Bool ?? true else { return }

        let content = UNMutableNotificationContent()
        content.title = Strings.Notifications.morningTitle
        content.body = Strings.Notifications.morningBody
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 8

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: true
        )
        let request = UNNotificationRequest(
            identifier: Self.morningNudgeID,
            content: content,
            trigger: trigger
        )
        self.center.add(request, withCompletionHandler: nil)
    }

    /// Cancels only the morning nudge — does not affect other notifications.
    func cancelMorningNudge() {
        self.center.removePendingNotificationRequests(
            withIdentifiers: [Self.morningNudgeID]
        )
    }

    // MARK: - Meal Reminders

    /// Individual meal reminders.
    func scheduleMealReminder(label: String, hour: Int, minute: Int) {
        guard UserDefaults.standard.object(
            forKey: StorageKeys.mealRemindersEnabled
        ) as? Bool ?? true else { return }

        let content = UNMutableNotificationContent()
        content.title = Strings.Notifications.mealReminderTitle
        content.body = Strings.Notifications.mealReminderBody(label)
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "meal_reminder_\(label)",
            content: content,
            trigger: trigger
        )
        self.center.add(request, withCompletionHandler: nil)
    }

    /// Schedules default meal reminders (Breakfast, Lunch, Dinner).
    func scheduleDefaultMealReminders() {
        self.scheduleMealReminder(label: "Breakfast", hour: 8, minute: 0)
        self.scheduleMealReminder(label: "Lunch", hour: 13, minute: 0)
        self.scheduleMealReminder(label: "Dinner", hour: 20, minute: 0)
    }

    // MARK: - Smart Nudges

    /// Schedules pattern-aware nudges, replacing only smart nudge slots.
    /// Morning nudge and other notifications are NOT affected.
    func scheduleSmartNudges(
        times: [DateComponents], message: String
    ) {
        guard UserDefaults.standard.object(
            forKey: StorageKeys.mealRemindersEnabled
        ) as? Bool ?? true else { return }

        let oldIDs = (0..<Self.maxSmartNudgeSlots).map {
            "\(Self.smartNudgePrefix)\($0)"
        }
        self.center.removePendingNotificationRequests(
            withIdentifiers: oldIDs
        )

        for (idx, time) in times.prefix(Self.maxSmartNudgeSlots).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = Strings.Notifications.mealReminderTitle
            content.body = message
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: time, repeats: true
            )
            let request = UNNotificationRequest(
                identifier: "\(Self.smartNudgePrefix)\(idx)",
                content: content,
                trigger: trigger
            )
            self.center.add(request, withCompletionHandler: nil)
        }
    }

    // MARK: - Cancel

    func cancelAllNotifications() {
        self.center.removeAllPendingNotificationRequests()
    }
}
