import Foundation

/// Handles caching and in-flight query coalescing for HealthKit sleep data fetches.
///
/// Without this, multiple concurrent callers (badge fetch, insight generation ×2)
/// all miss the empty cache on app launch and fire redundant HealthKit round-trips.
/// The in-flight dict ensures only the first caller runs the query; subsequent
/// callers for the same date await the same Task and share its result.
@MainActor
final class HealthKitSleepCoalescer {
    private let cacheExpiration: TimeInterval
    private var cache: [Date: (data: SleepData?, timestamp: Date)] = [:]
    private var inFlight: [Date: Task<SleepData?, Error>] = [:]

    // nil resolves to TimingConstants.sleepCacheDuration inside the body (MainActor-safe).
    // Avoids the "nonisolated default-parameter expression" warning on the enum property.
    init(cacheExpiration: TimeInterval? = nil) {
        self.cacheExpiration = cacheExpiration ?? TimingConstants.sleepCacheDuration
    }

    /// Fetches sleep data for `date`, serving from cache or joining an in-flight query.
    /// `query` is called at most once per date per cache window, regardless of concurrency.
    func fetch(for date: Date, query: @escaping () async throws -> SleepData?) async throws -> SleepData? {
        let key = Calendar.current.startOfDay(for: date)

        if let entry = self.cache[key] {
            let age = Date().timeIntervalSince(entry.timestamp)
            if age < self.cacheExpiration { return entry.data }
            self.cache.removeValue(forKey: key)
        }

        if let running = self.inFlight[key] {
            return try await running.value
        }

        let queryTask = Task<SleepData?, Error> { [weak self] in
            let result = try await query()
            self?.cache[key] = (result, Date())
            self?.inFlight.removeValue(forKey: key)
            return result
        }
        self.inFlight[key] = queryTask
        return try await queryTask.value
    }

    /// Returns the age (seconds) of a fresh cached entry, or nil if missing/expired.
    /// Used by callers that want to log cache hits before calling `fetch`.
    func cacheAge(for date: Date) -> TimeInterval? {
        let key = Calendar.current.startOfDay(for: date)
        guard let entry = self.cache[key] else { return nil }
        let age = Date().timeIntervalSince(entry.timestamp)
        return age < self.cacheExpiration ? age : nil
    }

    func clearCache() {
        self.cache.removeAll()
    }
}
