import Foundation

// MARK: - Day Navigation Extension

extension MainViewModel {
    /// Returns true if the selected date is today.
    var isViewingToday: Bool {
        Calendar.current.isDateInToday(self.selectedDate)
    }

    /// Returns true if the user can navigate to the previous day (within maxDaysBack limit).
    var canNavigateToPreviousDay: Bool {
        self.selectedDayIndex < Self.maxDaysBack
    }

    /// Returns true if the user can navigate to the next day (not beyond today).
    var canNavigateToNextDay: Bool {
        !self.isViewingToday
    }

    /// Returns the number of days between the selected date and today (0 = today).
    var selectedDayIndex: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: self.selectedDate)
        let components = calendar.dateComponents([.day], from: selected, to: today)
        return max(0, components.day ?? 0)
    }

    /// Formatted string for the selected date (e.g., "Monday, 5 Jan 2026").
    var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.string(from: self.selectedDate)
    }

    /// Navigates to a specific date. Future dates are clamped to today.
    func navigateToDate(_ date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)
        self.selectedDate = targetDay > today ? today : targetDay
    }

    /// Navigates to the previous day.
    func navigateToPreviousDay() {
        guard self.canNavigateToPreviousDay else { return }
        if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: self.selectedDate) {
            self.navigateToDate(previousDay)
        }
    }

    /// Navigates to the next day (towards today).
    func navigateToNextDay() {
        guard self.canNavigateToNextDay else { return }
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: self.selectedDate) {
            self.navigateToDate(nextDay)
        }
    }

    /// Navigates back to today.
    func navigateToToday() {
        self.selectedDate = Calendar.current.startOfDay(for: Date())
    }

    /// Navigates to a day by index (0 = today, 1 = yesterday, etc.).
    func navigateToIndex(_ index: Int) {
        let calendar = Calendar.current
        let clampedIndex = max(0, min(index, Self.maxDaysBack))
        let today = calendar.startOfDay(for: Date())
        if let targetDate = calendar.date(byAdding: .day, value: -clampedIndex, to: today) {
            self.selectedDate = targetDate
        }
    }

    /// Returns the meals for the currently selected date.
    func mealsForSelectedDate() -> [Meal] {
        self.isViewingToday ? self.meals : self.snapshotForSelectedDate()?.meals ?? []
    }

    /// Returns the snapshot for the currently selected date, if available.
    func snapshotForSelectedDate() -> DailySmileySnapshot? {
        self.historicalService.getSnapshot(for: self.selectedDate)
    }
}
