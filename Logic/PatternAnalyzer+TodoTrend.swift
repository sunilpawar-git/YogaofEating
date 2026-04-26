import Foundation

extension PatternAnalyzer {
    /// Analyzes todo completion trends over time.
    /// Detects improving, declining, or consistent completion patterns.
    func analyzeTodoCompletionTrend(
        from snapshots: [DailySmileySnapshot]
    ) -> [InsightPattern] {
        let calendar = Calendar.current
        let sorted = snapshots
            .filter { $0.morningMindCheck?.contains(where: { $0.category == .todo }) == true }
            .sorted { $0.date < $1.date }

        guard sorted.count >= 5 else { return [] }

        let halfIndex = sorted.count / 2
        let firstHalf = Array(sorted.prefix(halfIndex))
        let secondHalf = Array(sorted.suffix(from: halfIndex))

        let firstRate = Self.averageCompletionRate(for: firstHalf)
        let secondRate = Self.averageCompletionRate(for: secondHalf)

        let delta = secondRate - firstRate

        guard abs(delta) >= 0.15 else { return [] }

        let improving = delta > 0
        let description = improving
            ? "Your task completion has been improving lately"
            : "Your task completion has dipped recently"

        let confidence = min(1.0, abs(delta) * 2.0)
        let recentDays = secondHalf.suffix(3)
        let references = recentDays.map { snapshot in
            let completed = snapshot.morningMindCheck?
                .count(where: { $0.category == .todo && $0.isAccomplished == true }) ?? 0
            let total = snapshot.morningMindCheck?
                .count(where: { $0.category == .todo }) ?? 0

            return InsightReference(
                date: snapshot.date,
                description: "\(completed)/\(total) completed",
                category: .todo
            )
        }

        return [
            InsightPattern(
                type: .mindsetFeeling,
                description: description,
                confidence: confidence,
                references: Array(references)
            )
        ]
    }

    // MARK: - Private

    private static func averageCompletionRate(
        for snapshots: [DailySmileySnapshot]
    ) -> Double {
        let rates: [Double] = snapshots.compactMap { snapshot in
            guard let entries = snapshot.morningMindCheck else { return nil }
            let todos = entries.filter { $0.category == .todo }
            guard !todos.isEmpty else { return nil }
            let completed = todos.count(where: { $0.isAccomplished == true })
            return Double(completed) / Double(todos.count)
        }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }
}
