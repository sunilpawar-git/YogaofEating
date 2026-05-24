import Foundation

/// Builds the Firebase Cloud Function payload from daily snapshots.
/// Single source of truth replacing the duplicated payload construction
/// that existed in `InsightServerFetcher` and `BriefingService`.
///
/// Pure enum — no stored state, fully testable without mocks.
/// Security: sensitive fields (meal descriptions) are sent over HTTPS only and never logged.
enum SnapshotPayloadBuilder {
    /// Serialises an array of snapshots into the `userData` array expected by
    /// both `generateInsight` and `generateDailyBriefing` Cloud Functions.
    static func build(
        from snapshots: [DailySmileySnapshot],
        healthKitSleepData: [Date: SleepData],
        relativeTo referenceDate: Date
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        let normalizedRef = calendar.startOfDay(for: referenceDate)

        return snapshots.map { snapshot in
            var data = self.baseFields(for: snapshot, relativeTo: normalizedRef, calendar: calendar)
            self.appendMeals(to: &data, snapshot: snapshot)
            self.appendReflection(to: &data, snapshot: snapshot)
            self.appendRawText(to: &data, snapshot: snapshot)
            self.appendSleepData(
                to: &data,
                snapshot: snapshot,
                healthKitSleepData: healthKitSleepData,
                calendar: calendar
            )
            self.appendMindCheck(to: &data, snapshot: snapshot)
            return data
        }
    }

    /// Serialises a single `MindCheckEntry` into a Cloud Function payload dict.
    static func mindCheckEntryPayload(_ entry: MindCheckEntry) -> [String: Any] {
        var dict: [String: Any] = [
            "text": entry.text,
            "category": entry.category.displayName
        ]
        if entry.category == .todo {
            dict["isAccomplished"] = entry.isAccomplished ?? false
        }
        return dict
    }

    // MARK: - Private helpers

    private static let dayOfWeekFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private static func baseFields(
        for snapshot: DailySmileySnapshot,
        relativeTo normalizedRef: Date,
        calendar: Calendar
    ) -> [String: Any] {
        [
            "date": self.dayOfWeekFormatter.string(from: snapshot.date),
            "averageHealthScore": snapshot.averageHealthScore,
            "isToday": calendar.isDate(snapshot.date, inSameDayAs: normalizedRef)
        ]
    }

    private static func appendMeals(to data: inout [String: Any], snapshot: DailySmileySnapshot) {
        guard !snapshot.meals.isEmpty else { return }
        data["meals"] = snapshot.meals.map { meal -> [String: Any] in
            [
                "items": meal.items,
                "healthScore": meal.healthScore,
                "mealType": meal.mealType.rawValue,
                "time": self.timeFormatter.string(from: meal.timestamp)
            ]
        }
    }

    private static func appendReflection(to data: inout [String: Any], snapshot: DailySmileySnapshot) {
        guard let reflection = snapshot.reflection else { return }
        if let sleep = reflection.sleepQuality { data["sleepQuality"] = sleep.displayName }
        if let feeling = reflection.feeling { data["feeling"] = feeling.displayName }
    }

    private static func appendSleepData(
        to data: inout [String: Any],
        snapshot: DailySmileySnapshot,
        healthKitSleepData: [Date: SleepData],
        calendar: Calendar
    ) {
        let normalizedSnapshot = calendar.startOfDay(for: snapshot.date)
        guard let sleepData = healthKitSleepData.first(where: {
            calendar.isDate($0.key, inSameDayAs: normalizedSnapshot)
        })?.value else { return }

        var apple: [String: Any] = [
            "durationHours": sleepData.sleepDuration / 3600.0,
            "timeInBedHours": sleepData.timeInBed / 3600.0,
            "efficiency": sleepData.efficiency
        ]
        if let score = sleepData.sleepScore { apple["score"] = score }
        data["appleSleepData"] = apple
    }

    // Raw text sent over the existing authenticated HTTPS channel for Gemini grounding.
    // Values are never logged — only serialised into the encrypted-in-transit payload.
    private static func appendRawText(to data: inout [String: Any], snapshot: DailySmileySnapshot) {
        if let thoughts = snapshot.highlightData?.morningThoughts, !thoughts.isEmpty {
            data["morningThoughts"] = thoughts
        }
        if let journal = snapshot.reflectData?.journalText, !journal.isEmpty {
            data["journalEntry"] = journal
        }
    }

    private static func appendMindCheck(to data: inout [String: Any], snapshot: DailySmileySnapshot) {
        if let morning = snapshot.morningMindCheck, !morning.isEmpty {
            data["morningMindCheck"] = morning.map { self.mindCheckEntryPayload($0) }
        }
        if let evening = snapshot.eveningMindCheck, !evening.isEmpty {
            data["eveningMindCheck"] = evening.map { self.mindCheckEntryPayload($0) }
        }
    }
}
