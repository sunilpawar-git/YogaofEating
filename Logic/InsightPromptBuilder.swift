import Foundation

/// Builds text prompts for the AI insight generation service.
/// Single-responsibility: knows only how to format data into a prompt string.
enum InsightPromptBuilder {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    static func dailyPrompt(from snapshots: [DailySmileySnapshot]) -> String {
        var parts: [String] = [
            "Analyze the following wellbeing data from the past week and provide a brief, actionable insight.",
            ""
        ]
        for snapshot in snapshots.prefix(7) {
            parts.append(contentsOf: Self.dayLines(for: snapshot))
            parts.append("")
        }
        parts.append(contentsOf: Self.instructionLines)
        return parts.joined(separator: "\n")
    }
}

// MARK: - Private helpers

private extension InsightPromptBuilder {
    static let instructionLines: [String] = [
        "Provide a single, personalized insight (2-3 sentences max) that:",
        "1. Identifies a pattern between food choices and sleep/mood/energy/focus",
        "2. If focus data exists, consider how food affected focus levels",
        "3. If observations exist, weave them into the insight",
        "4. Is encouraging and actionable",
        "5. Does not repeat previous insights"
    ]

    static func dayLines(for snapshot: DailySmileySnapshot) -> [String] {
        let dayName = Self.dayFormatter.string(from: snapshot.date)
        var lines = ["**\(dayName)**:"]
        lines.append(contentsOf: Self.reflectionLines(from: snapshot.reflection))
        lines.append(contentsOf: Self.mealLines(from: snapshot))
        lines.append(contentsOf: Self.morningMindCheckLines(from: snapshot.morningMindCheck))
        lines.append(contentsOf: Self.eveningMindCheckLines(from: snapshot.eveningMindCheck))
        return lines
    }

    static func reflectionLines(from reflection: DailyReflection?) -> [String] {
        guard let reflection else { return [] }
        var lines: [String] = []
        if let energy = reflection.morningEnergyLevel { lines.append("  Morning Energy: \(energy)/5") }
        if let intention = reflection.dailyIntention, !intention.isEmpty {
            lines.append("  Daily Intention: \"\(intention)\"")
        }
        if let focus = reflection.focusRating {
            let clamped = max(0, min(focus, 3))
            let label = ["", "Scattered", "Okay", "Locked In"][clamped]
            lines.append("  Focus: \(label) (\(focus)/3)")
        }
        if let sleep = reflection.sleepQuality { lines.append("  Sleep: \(sleep.displayName)") }
        if let feeling = reflection.feeling { lines.append("  Feeling: \(feeling.displayName)") }
        return lines
    }

    static func mealLines(from snapshot: DailySmileySnapshot) -> [String] {
        guard !snapshot.meals.isEmpty else { return [] }
        let items = snapshot.meals.flatMap(\.items).prefix(5).joined(separator: ", ")
        return [
            "  Food: \(items)",
            "  Health Score: \(String(format: "%.0f%%", snapshot.averageHealthScore * 100))"
        ]
    }

    static func morningMindCheckLines(from entries: [MindCheckEntry]?) -> [String] {
        guard let entries, !entries.isEmpty else { return [] }
        var lines: [String] = []
        let todos = entries.filter { $0.category == .todo }
        if !todos.isEmpty {
            let done = todos.count(where: { $0.isAccomplished == true })
            lines.append("  Todos: \(done)/\(todos.count) completed")
        }
        let others = entries.filter { $0.category != .todo }
            .map { "\($0.category.displayName): \($0.text)" }
        if !others.isEmpty { lines.append("  Morning thoughts: \(others.joined(separator: "; "))") }
        return lines
    }

    static func eveningMindCheckLines(from entries: [MindCheckEntry]?) -> [String] {
        guard let entries, !entries.isEmpty else { return [] }
        var lines: [String] = []
        let obs = entries.filter { $0.category == .observation }.map(\.text)
        if !obs.isEmpty { lines.append("  Observations: \(obs.joined(separator: "; "))") }
        let other = entries.filter { $0.category != .observation }
            .map { "\($0.category.displayName): \($0.text)" }
        if !other.isEmpty { lines.append("  Evening reflections: \(other.joined(separator: "; "))") }
        return lines
    }
}
