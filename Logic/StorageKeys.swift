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

    // MARK: - Session Continuity

    /// UID of the most-recently authenticated user.
    /// Compared on launch to detect account switches and prevent cross-user data leakage.
    static let lastSignedInUID = "last_signed_in_uid"

    // MARK: - Data Lifecycle

    /// Set to `true` when the user explicitly deletes all data via Settings.
    /// Checked in `triggerCloudRestoreIfNeeded()` to prevent re-downloading just-deleted data.
    /// Intentionally NOT in `allKeys` — must survive the `deleteAll` UserDefaults loop.
    /// Cleared when a new account signs in (account switch), allowing the new user's restore.
    static let hasDeletedAllData = "has_deleted_all_data"

    // MARK: - All Keys (for bulk operations like deleteAll)

    //
    // MAINTENANCE: When adding a new key constant above, you MUST also add it here.
    // Failing to do so will leave orphan UserDefaults entries after a factory reset.

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
        insightCoachmarkSeen,
        lastSignedInUID
    ]
}
