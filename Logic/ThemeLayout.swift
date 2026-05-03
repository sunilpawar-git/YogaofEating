import SwiftUI

// MARK: - AppTheme Layout, Fasting, and DateContext Extensions

/// Screen-level and domain constants extracted from Theme.swift to keep that file
/// under 300 lines. All constants remain accessible via `AppTheme.*` namespace.
extension AppTheme {
    // MARK: - Layout

    /// Screen-level layout constants extracted from views to avoid magic numbers.
    enum Layout {
        /// Top padding applied to the date header within the main content VStack.
        static let headerTopPadding: CGFloat = 20

        /// Bottom padding applied below the date header (separates header from timeline).
        static let headerBottomPadding: CGFloat = 20

        /// Height of the invisible spacer anchoring the scroll-to-bottom proxy.
        static let bottomScrollBuffer: CGFloat = 100

        /// Minimum drag distance (in points) required to trigger day navigation swipe.
        static let dragThreshold: CGFloat = 50

        /// Height of the sleep quality input sheet.
        static let inputSheetHeight: CGFloat = 320

        /// Height of the overall feeling input sheet.
        static let feelingSheetHeight: CGFloat = 280
    }

    // MARK: - Fasting Domain Constants

    /// Threshold-related constants for fasting period logic, co-located so that
    /// UI visual constants (`AppTheme.Timeline`) and domain constants stay in sync.
    enum Fasting {
        /// Minimum fasting duration (in hours) to be considered significant (12h+ fasting).
        static let significanceHoursThreshold: Double = 12.0

        /// Seconds per hour — used in duration calculation to avoid magic 3600.
        static let secondsPerHour: Double = 3600

        /// Seconds per minute — used in duration formatting to avoid magic 60.
        static let secondsPerMinute: Double = 60
    }

    // MARK: - Date Context

    /// Constants used by `DateContextProvider` to determine contextual date subtext.
    enum DateContext {
        /// Hour of day (24h) before which "Good morning" is shown when no sleep is logged.
        static let morningHourThreshold: Int = 10
    }
}
