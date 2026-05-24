import Foundation

/// App-wide `NotificationCenter` notification name constants.
/// Always use these — never post raw string literals via NotificationCenter.
enum AppNotification {
    /// Posted when a user health-profile setting that affects TDEE changes
    /// (e.g. activity level). `MainViewModel` subscribes to trigger a calorie
    /// pill re-render without tight ViewModel-to-ViewModel coupling.
    static let healthProfileDidChange = Notification.Name("com.yogaofeating.healthProfileDidChange")
}
