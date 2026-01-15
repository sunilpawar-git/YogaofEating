import Foundation

/// Centralized storage keys for UserDefaults to ensure consistency
/// across the app and simplify data management operations.
enum StorageKeys {
    // MARK: - User Profile

    static let userName = "user_name"
    static let userHeight = "user_height"
    static let userWeight = "user_weight"
    static let userGender = "user_gender"
    static let userAge = "user_age"

    // MARK: - Appearance

    static let appTheme = "app_theme"
    static let unitSystem = "unit_system"

    // MARK: - Notifications

    static let morningNudgeEnabled = "morning_nudge_enabled"
    static let mealRemindersEnabled = "meal_reminders_enabled"

    // MARK: - Sensory

    static let hapticsEnabled = "haptics_enabled"
    static let soundEnabled = "sound_enabled"

    // MARK: - Integrations

    static let healthSyncEnabled = "health_sync_enabled"
    static let showHealthInsights = "show_health_insights"

    // MARK: - Coachmarks

    static let insightCoachmarkSeen = "insight_coachmark_seen"

    // MARK: - All Keys (for bulk operations like deleteAll)

    static let allKeys: [String] = [
        userName,
        userHeight,
        userWeight,
        userGender,
        userAge,
        appTheme,
        unitSystem,
        morningNudgeEnabled,
        mealRemindersEnabled,
        hapticsEnabled,
        soundEnabled,
        healthSyncEnabled,
        showHealthInsights,
        insightCoachmarkSeen
    ]
}
