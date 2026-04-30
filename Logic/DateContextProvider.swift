import Foundation
import SwiftUI

/// Pure, clock-injectable logic for computing the date header contextual subtext.
///
/// Isolated from MainViewModel so it is fully unit-testable without mocking
/// system time. The ViewModel calls `DateContextProvider.subtext(...)` passing
/// the current hour as a parameter, which makes the hour injectable in tests.
enum DateContextProvider {
    /// Returns the one-line contextual subtext to show below the date header,
    /// or `nil` when no context is meaningful.
    ///
    /// Priority order (first match wins):
    /// 1. Historical day → "X days ago"
    /// 2. Sleep logged → "Slept {quality}"
    /// 3. Before `AppTheme.DateContext.morningHourThreshold`, no sleep, no meals → "Good morning"
    /// 4. Any time, no sleep, has meals → "X meals so far"
    /// 5. Otherwise → nil
    static func subtext(
        isViewingToday: Bool,
        currentHour: Int,
        sleepQuality: SleepQuality?,
        mealCount: Int,
        daysAgo: Int
    ) -> String? {
        guard isViewingToday else {
            return daysAgo > 0 ? Strings.DateHeader.daysAgo(daysAgo) : nil
        }

        if let sleep = sleepQuality {
            return Strings.DateHeader.sleptQualityFormatted(quality: sleep)
        }

        if currentHour < AppTheme.DateContext.morningHourThreshold, mealCount == 0 {
            return Strings.DateHeader.goodMorning
        }

        if mealCount > 0 {
            return Strings.DateHeader.mealsSoFar(mealCount)
        }

        return nil
    }
}
