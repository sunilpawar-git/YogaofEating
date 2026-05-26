import Foundation

// MARK: - Date Header Context (Phase 4)

extension MainViewModel {
    /// One-line contextual subtext for the date header, or nil when no context is meaningful.
    ///
    /// Delegates pure logic to `DateContextProvider` so the decision function is
    /// independently testable. The ViewModel only supplies runtime values.
    var dateContextSubtext: String? {
        DateContextProvider.subtext(
            isViewingToday: self.isViewingToday,
            currentHour: Calendar.current.component(.hour, from: Date()),
            sleepQuality: self.todaysSleepQuality,
            mealCount: self.meals.count,
            daysAgo: self.selectedDayIndex
        )
    }
}
