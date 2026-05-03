import Foundation

/// Single source of truth for all timing constants used across the app.
/// All async delays, debounce intervals, and polling periods must reference these constants.
/// Never hardcode nanosecond or millisecond literals in service files, view models, or views.
enum TimingConstants {
    // MARK: - Input Debounce

    /// Debounce delay before a free-text meal entry change is persisted (nanoseconds).
    /// 500 ms balances keystroke responsiveness with reducing unnecessary writes.
    /// Mirrors AppTheme.TextEntry.debounceNanoseconds — both reference the same semantic value.
    static let debounceNanoseconds: UInt64 = 500_000_000

    // MARK: - Day Reset Monitoring

    /// How often the app polls to detect a calendar-day change and reset the slate (nanoseconds).
    /// 60 seconds is frequent enough to catch midnight rollovers without wasting battery.
    static let dayResetPollIntervalNanoseconds: UInt64 = 60_000_000_000

    // MARK: - Sync UI Display

    /// How long the "sync succeeded" status is shown before returning to idle (nanoseconds).
    static let syncSuccessDisplayNanoseconds: UInt64 = 2_000_000_000

    /// How long the "sync error" status is shown before returning to idle (nanoseconds).
    /// Longer than success to give users time to read the message.
    static let syncErrorDisplayNanoseconds: UInt64 = 3_000_000_000

    /// Delay between sync retry attempts (nanoseconds).
    static let syncRetryDelayNanoseconds: UInt64 = 1_000_000_000

    // MARK: - Sync Retry Policy

    /// Maximum number of sync retry attempts before giving up and showing a persistent error.
    static let syncMaxRetryAttempts: Int = 3
}
