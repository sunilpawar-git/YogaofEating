import Foundation

// MARK: - Sleep Data Processor

/// Processes raw sleep samples into structured sleep data.
/// Handles session detection, duration calculation, and score computation.
enum SleepDataProcessor {
    /// Gap threshold (in seconds) to consider samples as separate sleep sessions
    static let sessionGapThreshold: TimeInterval = 2 * 3600 // 2 hours

    // MARK: - Session Detection

    /// Identifies distinct sleep sessions from a list of samples.
    /// Sessions are separated by gaps > 2 hours.
    /// - Parameter samples: Sorted sleep samples (ascending by start date)
    /// - Returns: Array of sleep sessions, each containing related samples
    static func identifySleepSessions(from samples: [SleepSampleData]) -> [[SleepSampleData]] {
        guard !samples.isEmpty else { return [] }

        var sessions: [[SleepSampleData]] = []
        var currentSession: [SleepSampleData] = []

        for sample in samples {
            // Check if this sample starts a new session (gap > threshold from last sample)
            if let lastSample = currentSession.last {
                let gap = sample.startDate.timeIntervalSince(lastSample.endDate)
                if gap > self.sessionGapThreshold {
                    if !currentSession.isEmpty {
                        sessions.append(currentSession)
                    }
                    currentSession = []
                }
            }

            currentSession.append(sample)
        }

        // Don't forget the last session
        if !currentSession.isEmpty {
            sessions.append(currentSession)
        }

        return sessions
    }

    // MARK: - Duration Calculation

    /// Calculates total asleep and in-bed durations for a sleep session.
    /// - Parameter samples: Samples from a single sleep session
    /// - Returns: Tuple of (asleep duration, in-bed duration, session start, session end)
    static func calculateSessionDurations(
        from samples: [SleepSampleData]
    ) -> (asleepDuration: TimeInterval, inBedDuration: TimeInterval, start: Date?, end: Date?) {
        var totalAsleep: TimeInterval = 0
        var totalInBed: TimeInterval = 0
        var sessionStart: Date?
        var sessionEnd: Date?

        for sample in samples {
            // Track session boundaries
            if sessionStart == nil || sample.startDate < sessionStart! {
                sessionStart = sample.startDate
            }
            if sessionEnd == nil || sample.endDate > sessionEnd! {
                sessionEnd = sample.endDate
            }

            // Count in-bed time for all samples
            totalInBed += sample.duration

            // Only count actual sleep time (not awake or just in-bed)
            if sample.isAsleep {
                totalAsleep += sample.duration
            }
        }

        return (totalAsleep, totalInBed, sessionStart, sessionEnd)
    }

    // MARK: - Score Calculation

    /// Calculates a sleep score (0-100) based on duration and efficiency.
    /// - Parameters:
    ///   - sleepDuration: Total time asleep (seconds)
    ///   - timeInBed: Total time in bed (seconds)
    /// - Returns: Score from 0-100, or nil if invalid input
    static func calculateSleepScore(
        sleepDuration: TimeInterval,
        timeInBed: TimeInterval
    ) -> Double? {
        guard sleepDuration > 0, timeInBed > 0 else { return nil }

        // Sleep efficiency (percentage of time in bed actually sleeping)
        let efficiency = (sleepDuration / timeInBed) * 100.0

        // Duration score based on ideal sleep (7-9 hours)
        let hoursSlept = sleepDuration / 3600.0
        let durationScore = if hoursSlept >= 7, hoursSlept <= 9 {
            100.0
        } else if hoursSlept >= 6, hoursSlept < 7 {
            80.0
        } else if hoursSlept > 9, hoursSlept <= 10 {
            85.0
        } else if hoursSlept >= 5, hoursSlept < 6 {
            60.0
        } else if hoursSlept > 10 {
            70.0
        } else {
            40.0
        }

        // Combine duration score (60%) and efficiency (40%)
        let finalScore = (durationScore * 0.6) + (efficiency * 0.4)
        return min(100.0, max(0.0, finalScore))
    }

    // MARK: - Source Selection

    /// Selects the preferred data source from available sources.
    /// Priority: Apple Watch > Apple Health > Third-party apps
    /// - Parameter sources: Bundle identifiers of available sources
    /// - Returns: The preferred source identifier, or nil if empty
    static func selectPreferredSource(from sources: [String]) -> String? {
        guard !sources.isEmpty else { return nil }

        return sources.sorted { source1, source2 in
            let isWatch1 = source1.lowercased().contains("watch")
            let isWatch2 = source2.lowercased().contains("watch")
            if isWatch1, !isWatch2 { return true }
            if !isWatch1, isWatch2 { return false }

            // Secondary: prefer Apple's own health app
            let isApple1 = source1.lowercased().contains("apple")
            let isApple2 = source2.lowercased().contains("apple")
            if isApple1, !isApple2 { return true }
            return false
        }.first
    }

    // MARK: - Full Processing Pipeline

    /// Processes raw samples into SleepData for the most recent sleep session.
    /// - Parameter samples: All sleep samples from HealthKit
    /// - Parameter enableLogging: Whether to print debug logs
    /// - Returns: Processed SleepData for the most recent session, or nil
    static func processSleepSamples(
        _ samples: [SleepSampleData],
        enableLogging: Bool = false
    ) -> SleepData? {
        // Identify sleep sessions
        let sessions = self.identifySleepSessions(from: samples)

        if enableLogging {
            print("🛏️ Found \(sessions.count) sleep session(s)")
        }

        // Use the most recent (last) session
        guard let lastSession = sessions.last, !lastSession.isEmpty else {
            if enableLogging {
                print("🛏️ No sleep sessions found")
            }
            return nil
        }

        if enableLogging {
            print("🛏️ Using most recent session with \(lastSession.count) samples")
            for sample in lastSession {
                let durationMinutes = Int(sample.duration / 60)
                print("🛏️   Sample: \(sample.sleepStage), duration: \(durationMinutes)m")
            }
        }

        // Calculate durations
        let (asleepDuration, inBedDuration, start, end) = self.calculateSessionDurations(from: lastSession)

        if enableLogging {
            let asleepHours = asleepDuration / 3600.0
            let inBedHours = inBedDuration / 3600.0
            print("🛏️ Session ASLEEP: \(String(format: "%.1f", asleepHours))h (\(Int(asleepDuration / 60))m)")
            print("🛏️ Session IN-BED: \(String(format: "%.1f", inBedHours))h (\(Int(inBedDuration / 60))m)")
        }

        // Require actual sleep time
        guard asleepDuration > 0 else {
            if enableLogging {
                print("🛏️ No actual sleep found in session")
            }
            return nil
        }

        // Calculate score
        let score = self.calculateSleepScore(sleepDuration: asleepDuration, timeInBed: inBedDuration)

        if enableLogging {
            print("🛏️ Calculated sleep score: \(score ?? 0)")
        }

        return SleepData(
            sleepDuration: asleepDuration,
            timeInBed: inBedDuration,
            sleepStart: start,
            sleepEnd: end,
            sleepScore: score
        )
    }
}
