// swiftlint:disable force_unwrapping
import XCTest
@testable import Yoga_of_Eating

/// Tests for SleepDataProcessor - TDD tests for sleep session detection and processing
final class SleepDataProcessorTests: XCTestCase {
    // MARK: - Sleep Session Detection Tests

    func test_identifySleepSessions_separatesSessionsByTwoHourGap() {
        // Given: Samples with a 3-hour gap in the middle
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())

        // Session 1: 10 PM - 2 AM (4 hours)
        let session1Start = calendar.date(byAdding: .hour, value: -26, to: baseDate)! // 10 PM yesterday
        let session1End = calendar.date(byAdding: .hour, value: -22, to: baseDate)! // 2 AM today

        // Gap: 2 AM - 5 AM (3 hours) - should split sessions

        // Session 2: 5 AM - 7 AM (2 hours)
        let session2Start = calendar.date(byAdding: .hour, value: -19, to: baseDate)! // 5 AM
        let session2End = calendar.date(byAdding: .hour, value: -17, to: baseDate)! // 7 AM

        let samples: [SleepSampleData] = [
            SleepSampleData(startDate: session1Start, endDate: session1End, sleepStage: .asleepCore),
            SleepSampleData(startDate: session2Start, endDate: session2End, sleepStage: .asleepCore)
        ]

        // When
        let sessions = SleepDataProcessor.identifySleepSessions(from: samples)

        // Then: Should have 2 sessions
        XCTAssertEqual(sessions.count, 2)
    }

    func test_identifySleepSessions_combinesSamplesWithSmallGaps() {
        // Given: Samples with only 30-minute gaps
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())

        let start1 = calendar.date(byAdding: .hour, value: -8, to: baseDate)!
        let end1 = calendar.date(byAdding: .hour, value: -6, to: baseDate)!
        let start2 = calendar.date(byAdding: .minute, value: -330, to: baseDate)! // 30 min gap
        let end2 = calendar.date(byAdding: .hour, value: -4, to: baseDate)!

        let samples: [SleepSampleData] = [
            SleepSampleData(startDate: start1, endDate: end1, sleepStage: .asleepCore),
            SleepSampleData(startDate: start2, endDate: end2, sleepStage: .asleepDeep)
        ]

        // When
        let sessions = SleepDataProcessor.identifySleepSessions(from: samples)

        // Then: Should have 1 session (gap < 2 hours)
        XCTAssertEqual(sessions.count, 1)
    }

    func test_identifySleepSessions_returnsEmptyForNoSamples() {
        // Given: No samples
        let samples: [SleepSampleData] = []

        // When
        let sessions = SleepDataProcessor.identifySleepSessions(from: samples)

        // Then
        XCTAssertTrue(sessions.isEmpty)
    }

    // MARK: - Sleep Duration Calculation Tests

    func test_calculateSessionDurations_countsOnlyAsleepTime() {
        // Given: Session with mixed sleep stages
        let calendar = Calendar.current
        let baseDate = Date()

        let samples: [SleepSampleData] = [
            SleepSampleData(
                startDate: calendar.date(byAdding: .hour, value: -8, to: baseDate)!,
                endDate: calendar.date(byAdding: .hour, value: -6, to: baseDate)!,
                sleepStage: .asleepCore
            ), // 2h asleep
            SleepSampleData(
                startDate: calendar.date(byAdding: .hour, value: -6, to: baseDate)!,
                endDate: calendar.date(byAdding: .hour, value: -5, to: baseDate)!,
                sleepStage: .awake
            ), // 1h awake
            SleepSampleData(
                startDate: calendar.date(byAdding: .hour, value: -5, to: baseDate)!,
                endDate: calendar.date(byAdding: .hour, value: -3, to: baseDate)!,
                sleepStage: .asleepDeep
            ) // 2h asleep
        ]

        // When
        let durations = SleepDataProcessor.calculateSessionDurations(from: samples)

        // Then
        XCTAssertEqual(durations.asleepDuration, 4 * 3600, accuracy: 1) // 4 hours asleep
        XCTAssertEqual(durations.inBedDuration, 5 * 3600, accuracy: 1) // 5 hours total in bed
    }

    func test_calculateSessionDurations_handlesREMAndDeepSleep() {
        // Given: Various sleep stages
        let calendar = Calendar.current
        let baseDate = Date()

        let samples: [SleepSampleData] = [
            SleepSampleData(
                startDate: calendar.date(byAdding: .minute, value: -180, to: baseDate)!,
                endDate: calendar.date(byAdding: .minute, value: -120, to: baseDate)!,
                sleepStage: .asleepCore
            ), // 60m
            SleepSampleData(
                startDate: calendar.date(byAdding: .minute, value: -120, to: baseDate)!,
                endDate: calendar.date(byAdding: .minute, value: -90, to: baseDate)!,
                sleepStage: .asleepREM
            ), // 30m
            SleepSampleData(
                startDate: calendar.date(byAdding: .minute, value: -90, to: baseDate)!,
                endDate: calendar.date(byAdding: .minute, value: -60, to: baseDate)!,
                sleepStage: .asleepDeep
            ) // 30m
        ]

        // When
        let durations = SleepDataProcessor.calculateSessionDurations(from: samples)

        // Then: All sleep stages count as asleep
        XCTAssertEqual(durations.asleepDuration, 120 * 60, accuracy: 1) // 120 minutes
    }

    // MARK: - Sleep Score Calculation Tests

    func test_calculateSleepScore_returns100ForIdealSleep() {
        // Given: 8 hours of sleep, 100% efficiency
        let asleepDuration: TimeInterval = 8 * 3600
        let inBedDuration: TimeInterval = 8 * 3600

        // When
        let score = SleepDataProcessor.calculateSleepScore(
            sleepDuration: asleepDuration,
            timeInBed: inBedDuration
        )

        // Then: Should be 100 (ideal duration + perfect efficiency)
        XCTAssertNotNil(score)
        XCTAssertEqual(score!, 100.0, accuracy: 0.1)
    }

    func test_calculateSleepScore_penalizesShortSleep() {
        // Given: Only 4 hours of sleep
        let asleepDuration: TimeInterval = 4 * 3600
        let inBedDuration: TimeInterval = 4 * 3600

        // When
        let score = SleepDataProcessor.calculateSleepScore(
            sleepDuration: asleepDuration,
            timeInBed: inBedDuration
        )

        // Then: Should be low (< 70 due to short duration)
        XCTAssertNotNil(score)
        XCTAssertLessThan(score!, 70)
    }

    func test_calculateSleepScore_penalizesLowEfficiency() {
        // Given: 7 hours asleep but 10 hours in bed (70% efficiency)
        let asleepDuration: TimeInterval = 7 * 3600
        let inBedDuration: TimeInterval = 10 * 3600

        // When
        let score = SleepDataProcessor.calculateSleepScore(
            sleepDuration: asleepDuration,
            timeInBed: inBedDuration
        )

        // Then: Should be moderate (efficiency drags it down)
        XCTAssertNotNil(score)
        XCTAssertLessThan(score!, 90)
        XCTAssertGreaterThan(score!, 50)
    }

    func test_calculateSleepScore_returnsNilForZeroDuration() {
        // Given: No sleep
        let score = SleepDataProcessor.calculateSleepScore(
            sleepDuration: 0,
            timeInBed: 8 * 3600
        )

        // Then
        XCTAssertNil(score)
    }

    // MARK: - Source Priority Tests

    func test_selectPreferredSource_prefersAppleWatch() {
        // Given
        let sources = [
            "com.thirdparty.sleepapp",
            "com.apple.health.7B5081F3-2FF7-4C55-9B0D-B17726172BA9",
            "com.tantsissa.AutoSleep"
        ]

        // When
        let preferred = SleepDataProcessor.selectPreferredSource(from: sources)

        // Then: Apple health source should be preferred
        XCTAssertTrue(preferred?.contains("apple") ?? false)
    }

    func test_selectPreferredSource_returnsNilForEmptySources() {
        // Given
        let sources: [String] = []

        // When
        let preferred = SleepDataProcessor.selectPreferredSource(from: sources)

        // Then
        XCTAssertNil(preferred)
    }
}

// MARK: - SleepData Model Tests

final class SleepDataModelTests: XCTestCase {
    func test_sleepQuality_mapsScoreCorrectly() {
        // Great: 80+
        let great = SleepData(sleepDuration: 0, timeInBed: 0, sleepStart: nil, sleepEnd: nil, sleepScore: 85)
        XCTAssertEqual(great.sleepQuality, .great)

        // Good: 60-79
        let good = SleepData(sleepDuration: 0, timeInBed: 0, sleepStart: nil, sleepEnd: nil, sleepScore: 65)
        XCTAssertEqual(good.sleepQuality, .good)

        // Poor: 40-59
        let poor = SleepData(sleepDuration: 0, timeInBed: 0, sleepStart: nil, sleepEnd: nil, sleepScore: 50)
        XCTAssertEqual(poor.sleepQuality, .poor)

        // Terrible: < 40
        let terrible = SleepData(sleepDuration: 0, timeInBed: 0, sleepStart: nil, sleepEnd: nil, sleepScore: 30)
        XCTAssertEqual(terrible.sleepQuality, .terrible)
    }

    func test_formattedDuration_formatsCorrectly() {
        let sleepData = SleepData(
            sleepDuration: 7.5 * 3600, // 7h 30m
            timeInBed: 8 * 3600,
            sleepStart: nil,
            sleepEnd: nil,
            sleepScore: 85
        )

        XCTAssertEqual(sleepData.formattedDuration, "7h 30m")
    }

    func test_efficiency_calculatesCorrectly() {
        let sleepData = SleepData(
            sleepDuration: 7 * 3600, // 7 hours
            timeInBed: 8 * 3600, // 8 hours
            sleepStart: nil,
            sleepEnd: nil,
            sleepScore: nil
        )

        XCTAssertEqual(sleepData.efficiency, 87.5, accuracy: 0.1)
    }

    func test_efficiency_returnsZeroForZeroTimeInBed() {
        let sleepData = SleepData(
            sleepDuration: 0,
            timeInBed: 0,
            sleepStart: nil,
            sleepEnd: nil,
            sleepScore: nil
        )

        XCTAssertEqual(sleepData.efficiency, 0)
    }
}
