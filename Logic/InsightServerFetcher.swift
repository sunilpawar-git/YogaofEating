import FirebaseFunctions
import Foundation
import OSLog

private let fetcherLogger = Logger(subsystem: "com.yogaofeating", category: "InsightServerFetcher")

/// Handles the Firebase Cloud Function call for server-side insight generation.
/// Extracted from `InsightGenerationService` to respect the 300-line file limit.
@MainActor
enum InsightServerFetcher {
    static func fetchInsight(
        snapshots: [DailySmileySnapshot],
        date: Date,
        healthKitSleepData: [Date: SleepData],
        functions: Functions
    ) async -> LegacyDailyInsight? {
        let calendar = Calendar.current
        let todayNormalized = calendar.startOfDay(for: date)

        let userData = snapshots.map { snapshot -> [String: Any] in
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
                data["meals"] = snapshot.meals.map { meal -> [String: Any] in [
                    "items": meal.items,
                    "healthScore": meal.healthScore,
                    "mealType": meal.mealType.rawValue
                ] }
            }
            if let reflection = snapshot.reflection {
                if let sleep = reflection.sleepQuality { data["sleepQuality"] = sleep.displayName }
                if let feeling = reflection.feeling { data["feeling"] = feeling.displayName }
            }

            let snapshotNormalized = calendar.startOfDay(for: snapshot.date)
            if let sleepData = healthKitSleepData.first(where: {
                calendar.isDate($0.key, inSameDayAs: snapshotNormalized)
            })?.value {
                var apple: [String: Any] = [
                    "durationHours": sleepData.sleepDuration / 3600.0,
                    "timeInBedHours": sleepData.timeInBed / 3600.0,
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
            fetcherLogger.info("Calling Firebase Cloud Function 'generateInsight'")
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            let result = try await functions.httpsCallable("generateInsight").call([
                "userData": userData,
                "insightDate": formatter.string(from: date)
            ])
            guard let responseData = result.data as? [String: Any],
                  let insightText = responseData["insightText"] as? String,
                  let insightTypeString = responseData["insightType"] as? String,
                  let confidence = responseData["confidence"] as? Double
            else {
                fetcherLogger.warning("Invalid or missing fields in generateInsight response")
                return nil
            }

            let insightType: InsightType = switch insightTypeString {
            case "foodSleep": .foodSleep
            case "mindsetFeeling": .mindsetFeeling
            case "pattern": .pattern
            default: .encouragement
            }

            return LegacyDailyInsight(
                date: date,
                insightText: insightText,
                insightType: insightType,
                confidence: confidence
            )
        } catch {
            fetcherLogger.error("Server insight generation failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Shared payload helper (also used by BriefingService)

    static func mindCheckEntryPayload(_ entry: MindCheckEntry) -> [String: Any] {
        var dict: [String: Any] = ["text": entry.text, "category": entry.category.displayName]
        if entry.category == .todo { dict["isAccomplished"] = entry.isAccomplished ?? false }
        return dict
    }
}
