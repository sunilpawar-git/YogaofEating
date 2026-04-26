import FirebaseCore
import FirebaseFunctions
import Foundation

extension InsightGenerationService {
    // swiftlint:disable cyclomatic_complexity function_body_length
    /// Calls the Firebase Cloud Function to generate insight using Gemini.
    /// - Parameters:
    ///   - snapshots: The recent snapshots to analyze
    ///   - date: The date for the insight
    ///   - healthKitSleepData: Dictionary mapping dates to HealthKit sleep data
    /// - Returns: A DailyInsight if successful, nil otherwise
    func generateInsightFromServer(
        snapshots: [DailySmileySnapshot],
        date: Date,
        healthKitSleepData: [Date: SleepData] = [:]
    ) async -> DailyInsight? {
        guard let functions = self.functions else {
            #if DEBUG
                print("⚠️ Firebase Functions not available for insight generation")
            #endif
            return nil
        }

        // Prepare data for server
        // Mark which day is "today" (the date we're generating insight for)
        let calendar = Calendar.current
        let todayNormalized = calendar.startOfDay(for: date)
        let archetype = ArchetypeClassifier.classify(snapshots: snapshots)

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

            // Add morning energy level and daily intention (Reflect data)
            if let reflection = snapshot.reflection {
                if let energy = reflection.morningEnergyLevel {
                    data["morningEnergyLevel"] = energy
                }
                if let intention = reflection.dailyIntention, !intention.isEmpty {
                    data["dailyIntention"] = intention
                }
                if let focus = reflection.focusRating {
                    data["focusRating"] = focus
                }
            }

            // Add observations from evening mind check
            if let eveningEntries = snapshot.eveningMindCheck {
                let observations = eveningEntries
                    .filter { $0.category == .observation }
                    .map(\.text)
                if !observations.isEmpty {
                    data["observations"] = observations
                }
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
            #if DEBUG
                print("📡 Calling Firebase Cloud Function 'generateInsight'")
            #endif
            // Pass the insight date so server knows which day is "today"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d"
            let insightDateString = dateFormatter.string(from: date)

            let result = try await functions.httpsCallable("generateInsight").call([
                "userData": userData,
                "insightDate": insightDateString,
                "archetype": archetype.rawValue
            ])

            guard let responseData = result.data as? [String: Any] else {
                #if DEBUG
                    print("⚠️ Invalid response format from generateInsight")
                #endif
                return nil
            }

            guard let insightText = responseData["insightText"] as? String,
                  let insightTypeString = responseData["insightType"] as? String,
                  let confidence = responseData["confidence"] as? Double
            else {
                #if DEBUG
                    print("⚠️ Missing required fields in generateInsight response")
                #endif
                return nil
            }

            // Parse insight type
            // swiftlint:disable switch_case_on_newline
            let insightType: InsightType = switch insightTypeString {
            case "foodSleep": .foodSleep
            case "mindsetFeeling": .mindsetFeeling
            case "pattern": .pattern
            case "intentAlignment": .intentAlignment
            case "focusFood": .focusFood
            default: .encouragement
            }
            // swiftlint:enable switch_case_on_newline

            #if DEBUG
                print("✅ Received server insight")
            #endif

            return DailyInsight(
                date: date,
                insightText: insightText,
                insightType: insightType,
                confidence: confidence
            )

        } catch {
            #if DEBUG
                print("❌ Server insight generation failed: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}
