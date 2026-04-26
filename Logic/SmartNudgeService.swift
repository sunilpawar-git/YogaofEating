import Foundation

enum SmartNudgeService {
    private static let recentDaysWindow = 7
    private static let minimumDataPoints = 3

    static func suggestedMealTimes(
        from snapshots: [DailySmileySnapshot],
        fallback: [Int] = [8, 13, 20]
    ) -> [DateComponents] {
        let recent = snapshots
            .filter { !$0.meals.isEmpty }
            .prefix(self.recentDaysWindow)

        let mealTypes: [MealType] = [.breakfast, .lunch, .dinner]

        return mealTypes.enumerated().map { idx, type in
            let hours = recent.flatMap(\.meals)
                .filter { $0.mealType == type }
                .map {
                    Calendar(identifier: .gregorian).component(
                        .hour, from: $0.timestamp
                    )
                }

            let hour: Int = if hours.count >= self.minimumDataPoints {
                hours.reduce(0, +) / hours.count
            } else {
                fallback[idx]
            }

            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            return components
        }
    }

    static func nudgeMessage(streak: ConsistencyStreak) -> String {
        if streak.current >= 2 {
            return Strings.Nudge.streakKeepGoing(streak.current)
        }
        return Strings.Nudge.gentle
    }
}
