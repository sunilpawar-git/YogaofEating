import Foundation

// MARK: - Day Navigation Extension

extension MainViewModel {
    static let maxDaysBack: Int = 30

    var isViewingToday: Bool {
        Calendar.current.isDateInToday(self.selectedDate)
    }

    var canNavigateToPreviousDay: Bool {
        self.selectedDayIndex < Self.maxDaysBack
    }

    var canNavigateToNextDay: Bool {
        !self.isViewingToday
    }

    var selectedDayIndex: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: self.selectedDate)
        let components = calendar.dateComponents([.day], from: selected, to: today)
        return max(0, components.day ?? 0)
    }

    private static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter
    }()

    var formattedSelectedDate: String {
        Self.selectedDateFormatter.string(from: self.selectedDate)
    }

    func navigateToDate(_ date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        self.selectedDate = target > today ? today : target
    }

    func navigateToPreviousDay() {
        guard self.canNavigateToPreviousDay else { return }
        if let prev = Calendar.current.date(byAdding: .day, value: -1, to: self.selectedDate) {
            self.navigateToDate(prev)
        }
    }

    func navigateToNextDay() {
        guard self.canNavigateToNextDay else { return }
        if let next = Calendar.current.date(byAdding: .day, value: 1, to: self.selectedDate) {
            self.navigateToDate(next)
        }
    }

    func navigateToToday() {
        self.selectedDate = Calendar.current.startOfDay(for: Date())
    }

    func navigateToIndex(_ index: Int) {
        let clamped = max(0, min(index, Self.maxDaysBack))
        let today = Calendar.current.startOfDay(for: Date())
        if let target = Calendar.current.date(byAdding: .day, value: -clamped, to: today) {
            self.selectedDate = target
        }
    }

    func mealsForSelectedDate() -> [Meal] {
        self.isViewingToday ? self.meals : (self.snapshotForSelectedDate()?.meals ?? [])
    }

    func snapshotForSelectedDate() -> DailySmileySnapshot? {
        self.historicalService.getSnapshot(for: self.selectedDate)
    }
}
