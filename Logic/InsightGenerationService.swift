import FirebaseCore
import FirebaseFunctions
import Foundation
import OSLog

private let briefingLogger = Logger(subsystem: "com.yogaofeating", category: "Briefing")

/// Payload-shaping constants for the insight data sent to the server.
enum InsightPayloadConstants {
    /// Maximum number of meal items included per daily snapshot in the server payload.
    static let maxMealItemsPerSnapshot: Int = 5
}

/// Protocol for insight generation to enable testing.
@MainActor
protocol InsightGenerationServiceProtocol {
    func gatherDataForInsight() -> [DailySmileySnapshot]
    func createInsightPrompt(from snapshots: [DailySmileySnapshot]) -> String
    func saveInsight(_ insight: DailyInsight, for date: Date)
    func shouldGenerateInsight(for date: Date) -> Bool
    func generateInsight(for date: Date, healthKitSleepData: [Date: SleepData]) async throws -> DailyInsight?
    func generateWeeklyInsight() async -> WeeklyInsight?
    func generateBriefing(for date: Date, healthKitSleepData: [Date: SleepData]) async -> DailyBriefing?
}

extension InsightGenerationServiceProtocol {
    func generateBriefing(for date: Date) async -> DailyBriefing? {
        await self.generateBriefing(for: date, healthKitSleepData: [:])
    }
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
                let mealItems = snapshot.meals.flatMap(\.items).prefix(InsightPayloadConstants.maxMealItemsPerSnapshot)
                    .joined(separator: ", ")
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
    func saveInsight(_ insight: DailyInsight, for date: Date) {
        self.historicalService.updateInsight(for: date, insight: insight)
        briefingLogger.info("Insight saved for date \(date, privacy: .public)")
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
        guard data.count >= BriefingThresholds.minimumDataPoints else {
            return false
        }

        return true
    }

    // MARK: - Insight Generation

    /// Generates an insight for the given date using AI.
    /// Tries server-side Gemini generation first, falls back to local PatternAnalyzer.
    /// - Parameters:
    ///   - date: The date to generate insight for
    ///   - healthKitSleepData: Dictionary mapping dates to HealthKit sleep data for objective metrics
    /// - Returns: A generated insight, or nil if conditions aren't met
    func generateInsight(for date: Date, healthKitSleepData: [Date: SleepData] = [:]) async throws -> DailyInsight? {
        guard self.shouldGenerateInsight(for: date) else {
            return nil
        }

        let snapshots = self.gatherDataForInsight()

        // Try server-side generation first (last 1-3 days for focused insights)
        let recentSnapshots = Array(snapshots.prefix(self.serverLookbackDays))
        if let serverInsight = await self.generateInsightFromServer(
            snapshots: recentSnapshots,
            date: date,
            healthKitSleepData: healthKitSleepData
        ) {
            briefingLogger.info("Using server-generated insight from Gemini")
            self.saveInsight(serverInsight, for: date)
            return serverInsight
        }

        // Fallback to local PatternAnalyzer
        briefingLogger.info("Using local PatternAnalyzer for insight generation")
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
    ///   - healthKitSleepData: Dictionary mapping dates to HealthKit sleep data
    /// - Returns: A DailyInsight if successful, nil otherwise
    private func generateInsightFromServer(
        snapshots: [DailySmileySnapshot],
        date: Date,
        healthKitSleepData: [Date: SleepData] = [:]
    ) async -> DailyInsight? {
        guard let functions = self.functions else {
            briefingLogger.info("Firebase Functions not available — skipping server insight")
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

            // Add sleep quality (subjective - user's reported feeling)
            if let reflection = snapshot.reflection, let sleep = reflection.sleepQuality {
                data["sleepQuality"] = sleep.displayName
            }

            // Add feeling
            if let reflection = snapshot.reflection, let feeling = reflection.feeling {
                data["feeling"] = feeling.displayName
            }

            // Add Apple HealthKit sleep data (objective metrics)
            let snapshotDateNormalized = calendar.startOfDay(for: snapshot.date)
            if let sleepData = healthKitSleepData.first(where: {
                calendar.isDate($0.key, inSameDayAs: snapshotDateNormalized)
            })?.value {
                var appleSleepData: [String: Any] = [
                    "durationHours": sleepData.sleepDuration / 3600.0,
                    "timeInBedHours": sleepData.timeInBed / 3600.0,
                    "efficiency": sleepData.efficiency
                ]
                if let score = sleepData.sleepScore {
                    appleSleepData["score"] = score
                }
                data["appleSleepData"] = appleSleepData
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
            briefingLogger.info("Calling Firebase Cloud Function 'generateInsight'")
            // Pass the insight date so server knows which day is "today"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d"
            let insightDateString = dateFormatter.string(from: date)

            let result = try await functions.httpsCallable("generateInsight").call([
                "userData": userData,
                "insightDate": insightDateString
            ])

            guard let responseData = result.data as? [String: Any] else {
                briefingLogger.warning("Invalid response format from generateInsight")
                return nil
            }

            guard let insightText = responseData["insightText"] as? String,
                  let insightTypeString = responseData["insightType"] as? String,
                  let confidence = responseData["confidence"] as? Double
            else {
                briefingLogger.warning("Missing required fields in generateInsight response")
                return nil
            }

            // Parse insight type
            let insightType: InsightType = switch insightTypeString {
            case "foodSleep": .foodSleep
            case "mindsetFeeling": .mindsetFeeling
            case "pattern": .pattern
            default: .encouragement
            }

            briefingLogger.info("Received insight from server")

            return DailyInsight(
                date: date,
                insightText: insightText,
                insightType: insightType,
                confidence: confidence
            )

        } catch {
            briefingLogger.error("Server insight generation failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Private Helpers

    private func generateRichInsight(
        from snapshots: [DailySmileySnapshot],
        patterns: [InsightPattern]
    ) -> (text: String, type: InsightType, references: [InsightReference], confidence: Double) {
        // If we have high-confidence patterns, use them
        if let topPattern = patterns.first, topPattern.confidence >= BriefingThresholds.confidenceThreshold {
            let text = self.formatPatternAsInsight(topPattern)
            return (text, topPattern.type, topPattern.references, topPattern.confidence)
        }

        // Otherwise, generate a generic insight based on data
        let (text, type) = self.generateLocalInsight(from: snapshots)
        return (text, type, [], 0.5)
    }

    /// Serialises a single MindCheckEntry to a server payload dictionary.
    /// Both morning and evening entries use the same shape (DRY — replaces duplicated inline closures).
    /// Includes `isAccomplished` for `.todo` entries so the server receives consistent data
    /// regardless of which check (morning vs. evening) the entry belongs to.
    private func mindCheckEntryPayload(_ entry: MindCheckEntry) -> [String: Any] {
        var d: [String: Any] = ["text": entry.text, "category": entry.category.displayName]
        if entry.category == .todo { d["isAccomplished"] = entry.isAccomplished ?? false }
        return d
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

        let avgScore = snapshots.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral
        let insightType = self.determineInsightType(from: snapshots)

        let text = if avgScore > ScoringThresholds.high {
            "Great job! Your healthy eating choices over the past week are likely contributing to better energy and sleep. Keep it up!"
        } else if avgScore > ScoringThresholds.neutral {
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

    // MARK: - Daily Briefing Generation

    /// Generates a structured DailyBriefing from historical data.
    /// Tries the server-side `generateDailyBriefing` Cloud Function first,
    /// falls back to local `PatternAnalyzer` + heuristic headline/nudge.
    func generateBriefing(
        for date: Date,
        healthKitSleepData: [Date: SleepData] = [:]
    ) async -> DailyBriefing? {
        let snapshots = self.gatherDataForInsight()
        guard snapshots.count >= 2 else { return nil }

        // Try server first
        if let serverBriefing = await self.generateBriefingFromServer(
            snapshots: snapshots,
            date: date,
            healthKitSleepData: healthKitSleepData
        ) {
            return serverBriefing
        }

        // Local fallback
        return self.generateLocalBriefing(from: snapshots, date: date)
    }

    // MARK: - Server-Side Briefing

    private func generateBriefingFromServer(
        snapshots: [DailySmileySnapshot],
        date: Date,
        healthKitSleepData: [Date: SleepData]
    ) async -> DailyBriefing? {
        guard let functions = self.functions else { return nil }

        let calendar = Calendar.current
        let todayNormalized = calendar.startOfDay(for: date)
        let recentSnapshots = Array(snapshots.prefix(self.lookbackDays))

        let userData: [[String: Any]] = recentSnapshots.map { snapshot in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let dayName = formatter.string(from: snapshot.date)
            let isToday = calendar.isDate(snapshot.date, inSameDayAs: todayNormalized)

            var data: [String: Any] = [
                "date": dayName,
                "averageHealthScore": snapshot.averageHealthScore,
                "isToday": isToday
            ]

            if !snapshot.meals.isEmpty {
                data["meals"] = snapshot.meals.map { meal -> [String: Any] in
                    var mealDict: [String: Any] = [
                        "items": meal.items,
                        "healthScore": meal.healthScore,
                        "mealType": meal.mealType.rawValue
                    ]
                    let timeFormatter = DateFormatter()
                    timeFormatter.timeStyle = .short
                    mealDict["time"] = timeFormatter.string(from: meal.timestamp)
                    return mealDict
                }
            }

            if let reflection = snapshot.reflection, let sleep = reflection.sleepQuality {
                data["sleepQuality"] = sleep.displayName
            }
            if let reflection = snapshot.reflection, let feeling = reflection.feeling {
                data["feeling"] = feeling.displayName
            }

            let snapshotDate = calendar.startOfDay(for: snapshot.date)
            if let sleepData = healthKitSleepData.first(where: {
                calendar.isDate($0.key, inSameDayAs: snapshotDate)
            })?.value {
                var apple: [String: Any] = [
                    "durationHours": sleepData.sleepDuration / 3600.0,
                    "efficiency": sleepData.efficiency
                ]
                if let score = sleepData.sleepScore { apple["score"] = score }
                data["appleSleepData"] = apple
            }

            if let morning = snapshot.morningMindCheck, !morning.isEmpty {
                data["morningMindCheck"] = morning.map { self.mindCheckEntryPayload($0) }
            }

            if let evening = snapshot.eveningMindCheck, !evening.isEmpty {
                data["eveningMindCheck"] = evening.map { self.mindCheckEntryPayload($0) }
            }

            return data
        }

        do {
            let result = try await functions.httpsCallable("generateDailyBriefing").call(["userData": userData])

            guard let resp = result.data as? [String: Any],
                  let headline = resp["headline"] as? String,
                  let nudgeDict = resp["nudge"] as? [String: Any] else { return nil }

            let cards: [CorrelationCard] = (resp["correlationCards"] as? [[String: Any]] ?? []).compactMap { raw in
                guard let catStr = raw["category"] as? String,
                      let obs = raw["observation"] as? String,
                      let conf = raw["confidence"] as? Double,
                      let cat = CorrelationCategory(rawValue: catStr) else { return nil }
                return CorrelationCard(category: cat, observation: obs, confidence: conf)
            }

            let nudge = ActionableNudge(
                suggestion: nudgeDict["suggestion"] as? String ?? "Keep going today!",
                reasoning: nudgeDict["reasoning"] as? String ?? "",
                relatedMeal: nudgeDict["relatedMeal"] as? String
            )

            var trend: WeeklyTrendSnippet?
            if let trendDict = resp["weeklyTrend"] as? [String: Any] {
                trend = WeeklyTrendSnippet(
                    averageFoodScore: trendDict["averageFoodScore"] as? Double ?? 0.5,
                    averageSleepQuality: trendDict["averageSleepQuality"] as? Double ?? 0.5,
                    daysLogged: trendDict["daysLogged"] as? Int ?? snapshots.count,
                    trendDirection: TrendDirection(rawValue: trendDict["trendDirection"] as? String ?? "steady") ??
                        .steady
                )
            }

            return DailyBriefing(
                date: date,
                generatedAt: Date(),
                headline: headline,
                correlationCards: cards,
                nudge: nudge,
                weeklyTrend: trend
            )
        } catch {
            briefingLogger.error("Briefing server call failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Local Briefing Fallback

    private func generateLocalBriefing(
        from snapshots: [DailySmileySnapshot],
        date: Date
    ) -> DailyBriefing {
        let correlationCards = self.patternAnalyzer.generateCorrelationCards(from: snapshots)

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: date)

        let avgScore = snapshots.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral
        let headline = if avgScore > ScoringThresholds.high {
            "Great week! Your \(dayName) starts on a high note"
        } else if avgScore > ScoringThresholds.neutral {
            "Steady progress — here's your \(dayName) snapshot"
        } else {
            "Small shifts matter — your \(dayName) briefing"
        }

        let nudge = if let top = correlationCards.first {
            ActionableNudge(
                suggestion: "Focus on what worked: \(top.category.displayName.lowercased())",
                reasoning: top.observation
            )
        } else {
            ActionableNudge(
                suggestion: "Log your meals today to unlock deeper patterns",
                reasoning: "More data means richer insights tomorrow"
            )
        }

        var trend: WeeklyTrendSnippet?
        if snapshots.count >= 3 {
            let avgSleep = self.computeAverageSleepQuality(from: snapshots)
            let direction = self.computeTrendDirection(from: snapshots)
            trend = WeeklyTrendSnippet(
                averageFoodScore: avgScore,
                averageSleepQuality: avgSleep,
                daysLogged: snapshots.count,
                trendDirection: direction
            )
        }

        return DailyBriefing(
            date: date,
            generatedAt: Date(),
            headline: headline,
            correlationCards: correlationCards,
            nudge: nudge,
            weeklyTrend: trend
        )
    }

    private func computeAverageSleepQuality(from snapshots: [DailySmileySnapshot]) -> Double {
        let sleepScores: [Double] = snapshots.compactMap { snap -> Double? in
            guard let quality = snap.reflection?.sleepQuality else { return nil }
            return switch quality {
            case .great: 1.0
            case .good: 0.75
            case .poor: 0.25
            case .terrible: 0.0
            }
        }
        guard !sleepScores.isEmpty else { return 0.5 }
        return sleepScores.reduce(0, +) / Double(sleepScores.count)
    }

    private func computeTrendDirection(from snapshots: [DailySmileySnapshot]) -> TrendDirection {
        guard snapshots.count >= 3 else { return .steady }
        let scores = snapshots.reversed().map(\.averageHealthScore)
        let firstHalf = scores.prefix(scores.count / 2)
        let secondHalf = scores.suffix(scores.count / 2)
        let avgFirst = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let avgSecond = secondHalf.reduce(0, +) / Double(secondHalf.count)
        let delta = avgSecond - avgFirst
        if delta > 0.1 { return .improving }
        if delta < -0.1 { return .declining }
        return .steady
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
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            briefingLogger.error("Failed to compute weekStart — skipping weekly insight")
            return nil
        }

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
            topPatterns: Array(patterns.prefix(BriefingThresholds.maximumInsightReferences)),
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
        let avgHealthScore = snapshots.map(\.averageHealthScore).average() ?? ScoringThresholds.neutral
        let daysLogged = snapshots.count
        let hasGoodSleep = snapshots
            .contains { $0.reflection?.sleepQuality == .great || $0.reflection?.sleepQuality == .good }
        let hasMindCheck = snapshots.contains { $0.hasMorningMindCheck || $0.hasEveningMindCheck }

        // Determine wins
        if daysLogged >= ScoringThresholds.minimumConsistentDays {
            wins.append("\(daysLogged) days of consistent logging")
        }
        if avgHealthScore > ScoringThresholds.high {
            wins.append("Healthy eating choices")
        }
        if hasGoodSleep {
            wins.append("Quality sleep achieved")
        }
        if hasMindCheck {
            wins.append("Mindful reflection practice")
        }

        // Determine improvements
        if avgHealthScore < ScoringThresholds.neutral {
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
