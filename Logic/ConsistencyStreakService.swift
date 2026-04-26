import Foundation

enum ConsistencyStreakService {
    /// - Parameter todayLoggedOverride: When non-nil, overrides snapshot-based
    ///   today detection. Pass `!mainViewModel.meals.isEmpty` for accurate live state.
    static func compute(
        from snapshots: [DailySmileySnapshot],
        today: Date = Date(),
        todayLoggedOverride: Bool? = nil
    ) -> ConsistencyStreak {
        let calendar = Calendar(identifier: .gregorian)
        let todayStart = calendar.startOfDay(for: today)

        let dayMap = self.buildDayMap(
            snapshots: snapshots, calendar: calendar
        )

        let todayLogged = todayLoggedOverride
            ?? (dayMap[todayStart] == true)

        guard todayLogged || !dayMap.isEmpty else { return .empty }

        let current = self.computeCurrentStreak(
            from: todayStart,
            dayMap: dayMap,
            calendar: calendar,
            todayLogged: todayLogged
        )

        let best = self.computeBestStreak(
            dayMap: dayMap, calendar: calendar
        )

        return ConsistencyStreak(
            current: current,
            best: max(best, current),
            todayLogged: todayLogged
        )
    }

    private static func buildDayMap(
        snapshots: [DailySmileySnapshot],
        calendar: Calendar
    ) -> [Date: Bool] {
        var map: [Date: Bool] = [:]
        for snapshot in snapshots {
            let day = calendar.startOfDay(for: snapshot.date)
            let hasLoggedMeals = snapshot.meals.contains {
                !$0.items.isEmpty
            }
            let hasMeals = snapshot.mealCount > 0 || hasLoggedMeals
            map[day] = hasMeals
        }
        return map
    }

    private static func computeCurrentStreak(
        from todayStart: Date,
        dayMap: [Date: Bool],
        calendar: Calendar,
        todayLogged: Bool
    ) -> Int {
        guard todayLogged else { return 0 }

        var streak = 1
        var checkDate = todayStart

        while let previousDay = calendar.date(
            byAdding: .day, value: -1, to: checkDate
        ) {
            let dayStart = calendar.startOfDay(for: previousDay)
            guard dayMap[dayStart] == true else { break }
            streak += 1
            checkDate = dayStart
        }

        return streak
    }

    private static func computeBestStreak(
        dayMap: [Date: Bool],
        calendar: Calendar
    ) -> Int {
        let sortedDays = dayMap.keys.sorted()
        guard !sortedDays.isEmpty else { return 0 }

        var bestRun = 0
        var currentRun = 0

        for (idx, day) in sortedDays.enumerated() {
            guard dayMap[day] == true else {
                currentRun = 0
                continue
            }

            if idx == 0 {
                currentRun = 1
            } else {
                let previousDay = sortedDays[idx - 1]
                let expected = calendar.date(
                    byAdding: .day, value: -1, to: day
                )
                let isConsecutive = expected.map {
                    calendar.isDate($0, inSameDayAs: previousDay)
                } ?? false

                if isConsecutive, dayMap[previousDay] == true {
                    currentRun += 1
                } else {
                    currentRun = 1
                }
            }

            bestRun = max(bestRun, currentRun)
        }

        return bestRun
    }
}
