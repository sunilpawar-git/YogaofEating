import Foundation

enum BodyIntelligenceService {
    /// Computes a daily composite score using four equal weighted pillars.
    /// - Parameters:
    ///   - snapshot: Source daily snapshot.
    ///   - sleepData: Optional HealthKit sleep score (preferred over subjective proxy).
    static func compute(
        from snapshot: DailySmileySnapshot,
        sleepData: SleepData?
    ) -> BodyIntelligenceScore {
        let module = DayModuleProgress.compute(from: snapshot).overallProgress * 100
        let sleep = Self.sleepScore(snapshot: snapshot, sleepData: sleepData)
        let nutrition = snapshot.averageHealthScore * 100
        let execution = Self.todoCompletion(snapshot: snapshot) * 100

        let value = (module + sleep + nutrition + execution) / 4.0
        return BodyIntelligenceScore(
            value: value,
            moduleContribution: module,
            sleepContribution: sleep,
            nutritionContribution: nutrition,
            executionContribution: execution
        )
    }
}

private extension BodyIntelligenceService {
    static func sleepScore(snapshot: DailySmileySnapshot, sleepData: SleepData?) -> Double {
        if let score = sleepData?.sleepScore { return min(100, max(0, score)) }
        return snapshot.reflection?.sleepQuality?.subjectiveScore ?? 0
    }

    static func todoCompletion(snapshot: DailySmileySnapshot) -> Double {
        guard let todos = snapshot.morningMindCheck?.filter({ $0.category == .todo }), !todos.isEmpty else {
            return 0
        }
        let completed = todos.count(where: { $0.isAccomplished == true })
        return Double(completed) / Double(todos.count)
    }
}
