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

    /// Time-of-day greeting for the morning briefing card.
    var currentGreeting: String {
        self.greeting(for: Date())
    }

    /// Returns the appropriate greeting for the given date's hour.
    /// Accepts a date parameter for testability — pass `Date()` in production.
    func greeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return Strings.Briefing.greetingMorning
        case 12..<17: return Strings.Briefing.greetingAfternoon
        case 17..<21: return Strings.Briefing.greetingEvening
        default: return Strings.Briefing.greetingNight
        }
    }
}
