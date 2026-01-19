import FirebaseCore
import FirebaseFunctions
import Foundation

/// Protocol for insight generation to enable testing.
@MainActor
protocol InsightGenerationServiceProtocol {
    func gatherDataForInsight() -> [DailySmileySnapshot]
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String
    func saveInsight(_ insight: DailyInsight, for date: Date)
    func shouldGenerateInsight(for date: Date) -> Bool
    func generateInsight(for date: Date) async throws -> DailyInsight?
    func generateWeeklyInsight() async -> WeeklyInsight?
}

/// Service for generating AI-powered insights from user data.
/// Correlates food, mindset, sleep, and feeling data to provide personalized insights.
/// Tries server-side Gemini generation first, falls back to local PatternAnalyzer.
@MainActor
class InsightGenerationService: InsightGenerationServiceProtocol {
    // MARK: - Properties

    private let historicalService: any HistoricalDataServiceProtocol
    private let patternAnalyzer: PatternAnalyzer
    private var functions: Functions?

    /// Number of days to look back for insight generation
    private let lookbackDays: Int = 7

    /// Number of days to send to server (last 1-3 days for focused insights)
    private let serverLookbackDays: Int = 3

    // MARK: - Initialization

    init(historicalService: any HistoricalDataServiceProtocol, functions: Functions? = nil) {
        self.historicalService = historicalService
        self.patternAnalyzer = PatternAnalyzer()

        // Only initialize Firebase Functions if Firebase is configured
        if let providedFunctions = functions {
            self.functions = providedFunctions
        } else if FirebaseApp.app() != nil {
            self.functions = Functions.functions()
        } else {
            self.functions = nil
        }
    }

    // MARK: - Data Gathering

    /// Gathers the last 7 days of data for insight generation.
    /// Excludes empty days (no meals logged).
    /// - Returns: Array of snapshots with actual data
    func gatherDataForInsight() -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        var snapshots: [DailySmileySnapshot] = []

        for daysAgo in 0..<self.lookbackDays {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            if let snapshot = self.historicalService.getSnapshot(for: date), !snapshot.isEmpty {
                snapshots.append(snapshot)
            }
        }

        return snapshots
    }

    // MARK: - Prompt Creation

    /// Creates a prompt for the AI to generate insights.
    /// Includes meals, sleep, mindset, and feeling data.
    /// - Parameter snapshots: The snapshots to include in the prompt
    /// - Returns: A formatted prompt string for the AI
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String {
        var promptParts: [String] = []

        promptParts
            .append("Analyze the following wellbeing data from the past week and provide a brief, actionable insight.")
        promptParts.append("")

        for snapshot in snapshots.prefix(7) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            let dayName = dateFormatter.string(from: snapshot.date)

            var dayData: [String] = []
            dayData.append("**\(dayName)**:")

            // Meals
            if !snapshot.meals.isEmpty {
                let mealItems = snapshot.meals.flatMap(\.items).prefix(5).joined(separator: ", ")
                dayData.append("  Food: \(mealItems)")
                dayData.append("  Health Score: \(String(format: "%.0f%%", snapshot.averageHealthScore * 100))")
            }

            // Sleep quality
            if let reflection = snapshot.reflection, let sleep = reflection.sleepQuality {
                dayData.append("  Sleep: \(sleep.displayName)")
            }

            // Feeling
            if let reflection = snapshot.reflection, let feeling = reflection.feeling {
                dayData.append("  Feeling: \(feeling.displayName)")
            }

            // Morning mind check (Phase 4: include todo completion)
            if let morningEntries = snapshot.morningMindCheck, !morningEntries.isEmpty {
                // Count completed todos
                let todos = morningEntries.filter { $0.category == .todo }
                if !todos.isEmpty {
                    let completedCount = todos.count(where: { $0.isAccomplished == true })
                    dayData.append("  Todos: \(completedCount)/\(todos.count) completed")
                }
                // Include other thoughts
                let otherThoughts = morningEntries.filter { $0.category != .todo }
                    .map { "\($0.category.displayName): \($0.text)" }
                if !otherThoughts.isEmpty {
                    dayData.append("  Morning thoughts: \(otherThoughts.joined(separator: "; "))")
                }
            }

            // Evening mind check
            if let eveningEntries = snapshot.eveningMindCheck, !eveningEntries.isEmpty {
                let reflections = eveningEntries.map { "\($0.category.displayName): \($0.text)" }
                    .joined(separator: "; ")
                dayData.append("  Evening reflections: \(reflections)")
            }

            promptParts.append(contentsOf: dayData)
            promptParts.append("")
        }

        promptParts.append("Provide a single, personalized insight (2-3 sentences max) that:")
        promptParts.append("1. Identifies a pattern between food choices and sleep/mood/energy")
        promptParts.append("2. Is encouraging and actionable")
        promptParts.append("3. Does not repeat previous insights")

        return promptParts.joined(separator: "\n")
    }

    // MARK: - Insight Storage

    /// Saves a generated insight for a specific date.
    /// - Parameters:
    ///   - insight: The insight to save
    ///   - date: The date to associate the insight with
    func saveInsight(_ insight: DailyInsight, for _: Date) {
        // TODO: Implement storage - will be added in future phase
        // For now, insights are ephemeral
        print("📊 Insight generated: \(insight.insightText)")
    }

    // MARK: - Check Methods

    /// Determines whether an insight should be generated for the given date.
    /// Returns true if: sleep quality is logged AND no insight generated yet today.
    /// - Parameter date: The date to check
    /// - Returns: True if insight should be generated
    func shouldGenerateInsight(for date: Date) -> Bool {
        guard let snapshot = self.historicalService.getSnapshot(for: date) else {
            return false
        }

        // Must have sleep quality logged (morning trigger)
        guard let reflection = snapshot.reflection, reflection.sleepQuality != nil else {
            return false
        }

        // Must have some historical data to analyze
        let data = self.gatherDataForInsight()
        guard data.count >= 2 else {
            return false
        }

        return true
    }

    // MARK: - Insight Generation

    /// Generates an insight for the given date using AI.
    /// Tries server-side Gemini generation first, falls back to local PatternAnalyzer.
    /// - Parameter date: The date to generate insight for
    /// - Returns: A generated insight, or nil if conditions aren't met
    func generateInsight(for date: Date) async throws -> DailyInsight? {
        guard self.shouldGenerateInsight(for: date) else {
            return nil
        }

        let snapshots = self.gatherDataForInsight()

        // Try server-side generation first (last 1-3 days for focused insights)
        let recentSnapshots = Array(snapshots.prefix(self.serverLookbackDays))
        if let serverInsight = await self.generateInsightFromServer(snapshots: recentSnapshots, date: date) {
            print("✨ Using server-generated insight from Gemini")
            self.saveInsight(serverInsight, for: date)
            return serverInsight
        }

        // Fallback to local PatternAnalyzer
        print("📊 Using local PatternAnalyzer for insight generation")
        let patterns = self.patternAnalyzer.analyzePatterns(from: snapshots)

        // Generate insight based on detected patterns or fallback to generic
        let (insightText, insightType, references, confidence) = self.generateRichInsight(
            from: snapshots,
            patterns: patterns
        )

        let insight = DailyInsight(
            date: date,
            insightText: insightText,
            insightType: insightType,
            confidence: confidence,
            references: references
        )

        self.saveInsight(insight, for: date)
        return insight
    }

    // MARK: - Server-Side Generation

    /// Calls the Firebase Cloud Function to generate insight using Gemini.
    /// - Parameters:
    ///   - snapshots: The recent snapshots to analyze
    ///   - date: The date for the insight
    /// - Returns: A DailyInsight if successful, nil otherwise
    private func generateInsightFromServer(
        snapshots: [DailySmileySnapshot],
        date: Date
    ) async -> DailyInsight? {
        guard let functions = self.functions else {
            print("⚠️ Firebase Functions not available for insight generation")
            return nil
        }

        // Prepare data for server
        // Mark which day is "today" (the date we're generating insight for)
        let calendar = Calendar.current
        let todayNormalized = calendar.startOfDay(for: date)

        let userData = snapshots.map { snapshot -> [String: Any] in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            let dayName = dateFormatter.string(from: snapshot.date)

            // Mark if this snapshot is for "today" (the insight date)
            let isToday = calendar.isDate(snapshot.date, inSameDayAs: todayNormalized)

            var data: [String: Any] = [
                "date": dayName,
                "averageHealthScore": snapshot.averageHealthScore,
                "isToday": isToday
            ]

            // Add meals
            if !snapshot.meals.isEmpty {
                data["meals"] = snapshot.meals.map { meal -> [String: Any] in
                    [
                        "items": meal.items,
                        "healthScore": meal.healthScore,
                        "mealType": meal.mealType.rawValue
                    ]
                }
            }

            // Add sleep quality
            if let reflection = snapshot.reflection, let sleep = reflection.sleepQuality {
                data["sleepQuality"] = sleep.displayName
            }

            // Add feeling
            if let reflection = snapshot.reflection, let feeling = reflection.feeling {
                data["feeling"] = feeling.displayName
            }

            // Add morning mind check (Phase 4: include isAccomplished for todos)
            if let morningEntries = snapshot.morningMindCheck, !morningEntries.isEmpty {
                data["morningMindCheck"] = morningEntries.map { entry -> [String: Any] in
                    var entryData: [String: Any] = [
                        "text": entry.text,
                        "category": entry.category.displayName
                    ]
                    // Include completion status for todos
                    if entry.category == .todo {
                        entryData["isAccomplished"] = entry.isAccomplished ?? false
                    }
                    return entryData
                }
            }

            // Add evening mind check
            if let eveningEntries = snapshot.eveningMindCheck, !eveningEntries.isEmpty {
                data["eveningMindCheck"] = eveningEntries.map { entry -> [String: Any] in
                    [
                        "text": entry.text,
                        "category": entry.category.displayName
                    ]
                }
            }

            return data
        }

        do {
            print("📡 Calling Firebase Cloud Function 'generateInsight'")
            // Pass the insight date so server knows which day is "today"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d"
            let insightDateString = dateFormatter.string(from: date)

            let result = try await functions.httpsCallable("generateInsight").call([
                "userData": userData,
                "insightDate": insightDateString
            ])

            guard let responseData = result.data as? [String: Any] else {
                print("⚠️ Invalid response format from generateInsight")
                return nil
            }

            guard let insightText = responseData["insightText"] as? String,
                  let insightTypeString = responseData["insightType"] as? String,
                  let confidence = responseData["confidence"] as? Double
            else {
                print("⚠️ Missing required fields in generateInsight response")
                return nil
            }

            // Parse insight type
            let insightType: InsightType = switch insightTypeString {
            case "foodSleep": .foodSleep
            case "mindsetFeeling": .mindsetFeeling
            case "pattern": .pattern
            default: .encouragement
            }

            print("✅ Received insight from server: \(insightText.prefix(50))...")

            return DailyInsight(
                date: date,
                insightText: insightText,
                insightType: insightType,
                confidence: confidence
            )

        } catch {
            print("❌ Server insight generation failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private Helpers

    private func generateRichInsight(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> (text: String, type: InsightType, references: [InsightReference], confidence: Double) {
        // If we have high-confidence patterns, use them
        if let topPattern = patterns.first, topPattern.confidence >= 0.6 {
            let text = self.formatPatternAsInsight(topPattern)
            return (text, topPattern.type, topPattern.references, topPattern.confidence)
        }

        // Otherwise, generate a generic insight based on data
        let (text, type) = self.generateLocalInsight(from: snapshots)
        return (text, type, [], 0.5)
    }

    private func formatPatternAsInsight(_ pattern: InsightPattern) -> String {
        var parts: [String] = []

        // Add observational part with date references
        if !pattern.references.isEmpty {
            let refStrings = pattern.references.prefix(2).map { ref in
                "On \(ref.formattedDate), \(ref.description.lowercased())"
            }
            parts.append(contentsOf: refStrings)
        }

        // Add the pattern description
        parts.append(pattern.description)

        // Add prescriptive advice based on pattern type
        let advice = self.getPrescriptiveAdvice(for: pattern.type)
        if !advice.isEmpty {
            parts.append(advice)
        }

        return parts.joined(separator: ". ") + "."
    }

    private func getPrescriptiveAdvice(for type: InsightType) -> String {
        switch type {
        case .foodSleep:
            "Consider finishing dinner earlier for better sleep"
        case .mindsetFeeling:
            "Keep setting intentions - it seems to help your mood"
        case .pattern:
            "Your consistency is paying off"
        case .encouragement:
            "Keep up the great work"
        }
    }

    private func generateLocalInsight(from snapshots: [DailySmileySnapshot]) -> (String, InsightType) {
        // Simple local insight generation (fallback when no patterns detected)
        guard snapshots.first != nil else {
            return ("Keep logging your meals and sleep to discover patterns in your wellbeing.", .encouragement)
        }

        let avgScore = snapshots.map(\.averageHealthScore).reduce(0, +) / Double(snapshots.count)
        let insightType = self.determineInsightType(from: snapshots)

        let text = if avgScore > 0.7 {
            "Great job! Your healthy eating choices over the past week are likely contributing to better energy and sleep. Keep it up!"
        } else if avgScore > 0.5 {
            "You're on the right track. Try adding more vegetables to your evening meals - they may help improve your sleep quality."
        } else {
            "Consider lighter, more balanced meals - heavy or processed foods late in the day can affect how you feel the next morning."
        }

        return (text, insightType)
    }

    private func determineInsightType(from snapshots: [DailySmileySnapshot]) -> InsightType {
        // Check what data we have to determine the best insight type
        let hasSleepData = snapshots.contains { $0.reflection?.sleepQuality != nil }
        let hasMindCheckData = snapshots.contains { $0.hasMorningMindCheck || $0.hasEveningMindCheck }
        let hasFeelingData = snapshots.contains { $0.reflection?.feeling != nil }

        if hasSleepData, snapshots.count >= 3 {
            return .foodSleep
        } else if hasMindCheckData, hasFeelingData {
            return .mindsetFeeling
        } else if snapshots.count >= 5 {
            return .pattern
        } else {
            return .encouragement
        }
    }

    // MARK: - Weekly Insight Generation

    /// Generates a weekly insight aggregating the past 7 days of data.
    /// - Returns: A weekly insight summary, or nil if not enough data
    func generateWeeklyInsight() async -> WeeklyInsight? {
        let snapshots = self.gatherDataForInsight()

        // Need at least 3 days of data for a meaningful weekly summary
        guard snapshots.count >= 3 else {
            return nil
        }

        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!

        // Analyze patterns across the week
        let patterns = self.patternAnalyzer.analyzePatterns(from: snapshots)

        // Generate summary and extract wins/improvements
        let (summaryText, wins, improvements) = self.generateWeeklySummary(
            from: snapshots,
            patterns: patterns
        )

        return WeeklyInsight(
            weekStartDate: weekStart,
            weekEndDate: today,
            summaryText: summaryText,
            topPatterns: Array(patterns.prefix(3)),
            dailyInsights: [],
            improvementAreas: improvements,
            wins: wins
        )
    }

    private func generateWeeklySummary(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> (summary: String, wins: [String], improvements: [String]) {
        var wins: [String] = []
        var improvements: [String] = []

        // Analyze the week's data
        let avgHealthScore = snapshots.map(\.averageHealthScore).reduce(0, +) / Double(snapshots.count)
        let daysLogged = snapshots.count
        let hasGoodSleep = snapshots
            .contains { $0.reflection?.sleepQuality == .great || $0.reflection?.sleepQuality == .good }
        let hasMindCheck = snapshots.contains { $0.hasMorningMindCheck || $0.hasEveningMindCheck }

        // Determine wins
        if daysLogged >= 5 {
            wins.append("\(daysLogged) days of consistent logging")
        }
        if avgHealthScore > 0.7 {
            wins.append("Healthy eating choices")
        }
        if hasGoodSleep {
            wins.append("Quality sleep achieved")
        }
        if hasMindCheck {
            wins.append("Mindful reflection practice")
        }

        // Determine improvements
        if avgHealthScore < 0.5 {
            improvements.append("Consider healthier meal choices")
        }
        if let topPattern = patterns.first, topPattern.type == .foodSleep {
            improvements.append("Watch meal timing for better sleep")
        }
        if !hasMindCheck {
            improvements.append("Try morning/evening mind checks")
        }

        // Generate summary
        let summary = if wins.count > improvements.count {
            "Great week! You maintained healthy habits with \(daysLogged) days of logging. Keep up the momentum!"
        } else if wins.isEmpty {
            "This week had room for improvement. Focus on consistency and healthier choices next week."
        } else {
            "A balanced week with some wins and areas to work on. Your \(wins.first ?? "effort") is paying off!"
        }

        return (summary, wins, improvements)
    }
}
