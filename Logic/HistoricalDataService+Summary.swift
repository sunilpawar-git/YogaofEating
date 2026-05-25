import Foundation

extension HistoricalDataService {
    func computeHistoricalSummary(relativeTo date: Date) -> HistoricalSummary {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: startOfToday),
              let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: startOfToday)
        else { return .empty }

        let snaps30 = self.historicalData.snapshots(in: thirtyDaysAgo...startOfToday)
            .filter { $0.mealCount > 0 }
        let snaps90 = self.historicalData.snapshots(in: ninetyDaysAgo...startOfToday)
            .filter { $0.mealCount > 0 }

        let avg30 = snaps30.isEmpty ? 0.0
            : snaps30.map(\.averageHealthScore).reduce(0.0, +) / Double(snaps30.count)
        let thirtyStats = PeriodStats(averageFoodScore: avg30, daysLogged: snaps30.count)

        let ninetyStats: PeriodStats? = snaps90.count > snaps30.count ? {
            let avg = snaps90.map(\.averageHealthScore).reduce(0.0, +) / Double(snaps90.count)
            return PeriodStats(averageFoodScore: avg, daysLogged: snaps90.count)
        }() : nil

        let currentStreak = self.computeStreak(from: startOfToday, calendar: calendar)

        let dimSnaps = snaps30.compactMap(\.wellbeingDimensions)
        let bestDimension: WellbeingDimension?
        let worstDimension: WellbeingDimension?
        if dimSnaps.isEmpty {
            bestDimension = nil
            worstDimension = nil
        } else {
            let scores = WellbeingDimension.allCases.map { dim -> (WellbeingDimension, Double) in
                let avg = dimSnaps.map { dim.value(in: $0) }.reduce(0.0, +) / Double(dimSnaps.count)
                return (dim, avg)
            }
            bestDimension = scores.max(by: { $0.1 < $1.1 })?.0
            worstDimension = scores.min(by: { $0.1 < $1.1 })?.0
        }

        return HistoricalSummary(
            thirtyDayStats: thirtyStats,
            ninetyDayStats: ninetyStats,
            currentStreak: currentStreak,
            bestDimension: bestDimension,
            worstDimension: worstDimension
        )
    }

    private func computeStreak(from startOfToday: Date, calendar: Calendar) -> Int {
        var streak = 0
        var checkDate = startOfToday
        while let snap = self.historicalData.snapshot(for: checkDate), snap.mealCount > 0 {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }
}
