import Foundation

extension Strings {
    // MARK: - Notifications

    enum Notifications {
        static let morningTitle = "Good Morning!"
        static let morningBody =
            "Time to plan your mindful meals for today. The Smiley is waiting for you 🙂"
        static let mealReminderTitle = "Meal Time"

        static func mealReminderBody(_ label: String) -> String {
            "What are you planning for \(label.lowercased())? Let your friend know."
        }
    }

    // MARK: - Widget

    enum Widget {
        static let title = "Yoga of Eating"
        static let description = "Today's body intelligence at a glance."

        static func bisLabel(_ score: Int) -> String { "BIS \(score)" }
        static func streakLabel(_ count: Int) -> String { "\(count)d" }
    }

    // MARK: - Settings

    enum Settings {
        static let mindfulSessionSync = "Log mindful sessions to Health"
        static let mindfulSessionSyncDescription =
            "Each evening review is recorded as a mindful session in the Health app."
        static let radialHomeBeta = "New Home Screen (Beta)"
    }
}
