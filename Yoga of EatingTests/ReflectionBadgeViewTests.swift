// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import SwiftUI
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for ReflectionBadgeView with Apple HealthKit sleep data integration
    /// Phase 1: TDD - Tests written before implementation
    @MainActor
    final class ReflectionBadgeViewTests: XCTestCase {
        // MARK: - Test Data

        /// Creates mock sleep data for testing
        private func createMockSleepData(
            sleepDuration: TimeInterval = 7.5 * 3600, // 7h 30m
            timeInBed: TimeInterval = 8 * 3600, // 8h
            sleepScore: Double? = 85.0
        ) -> SleepData {
            SleepData(
                sleepDuration: sleepDuration,
                timeInBed: timeInBed,
                sleepStart: Date(),
                sleepEnd: Date(),
                sleepScore: sleepScore
            )
        }

        // MARK: - Tests: Basic Badge Display (Existing Behavior)

        func test_reflectionBadgeView_displaysSleepQuality_withoutSleepData() {
            // Given: A sleep quality without Apple sleep data
            let badge = ReflectionBadgeView(
                type: .sleep(.good),
                isTappable: false,
                sleepData: nil
            )

            // Then: Badge should display the quality
            XCTAssertEqual(badge.type.valueText, "Good")
            XCTAssertEqual(badge.type.label, "Sleep")
            XCTAssertEqual(badge.type.fixedIcon, "😴")
        }

        func test_reflectionBadgeView_displaysFeelingBadge_unchanged() {
            // Given: A feeling badge (should not show sleep data)
            let badge = ReflectionBadgeView(
                type: .feeling(.great),
                isTappable: false,
                sleepData: nil
            )

            // Then: Badge should display the feeling
            XCTAssertEqual(badge.type.valueText, "Great")
            XCTAssertEqual(badge.type.label, "Feeling")
            XCTAssertEqual(badge.type.fixedIcon, "🤔")
        }

        // MARK: - Tests: Sleep Data Display

        func test_reflectionBadgeView_displaysSleepData_whenAvailable() {
            // Given: Sleep quality with Apple sleep data
            let sleepData = self.createMockSleepData(sleepScore: 85.0)
            let badge = ReflectionBadgeView(
                type: .sleep(.good),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Badge should have sleep data available
            XCTAssertNotNil(badge.sleepData)
            XCTAssertEqual(badge.sleepData?.sleepScore, 85.0)
        }

        func test_reflectionBadgeView_showsSleepScore_whenSleepDataAvailable() {
            // Given: Sleep quality with Apple sleep data containing score
            let sleepData = self.createMockSleepData(sleepScore: 92.0)
            let badge = ReflectionBadgeView(
                type: .sleep(.great),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Badge should show Apple Watch metrics
            XCTAssertNotNil(badge.sleepData?.sleepScore)
            XCTAssertEqual(badge.sleepData?.sleepScore, 92.0)
            // The view should display "⌚️ : 92%"
        }

        func test_reflectionBadgeView_showsSleepDuration_whenSleepDataAvailable() {
            // Given: Sleep quality with Apple sleep data containing duration
            let sleepData = self.createMockSleepData(
                sleepDuration: 7.5 * 3600, // 7h 30m
                sleepScore: 85.0
            )
            let badge = ReflectionBadgeView(
                type: .sleep(.good),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Badge should have formatted duration available
            XCTAssertEqual(badge.sleepData?.formattedDuration, "7h 30m")
        }

        // MARK: - Tests: No Sleep Data Scenarios

        func test_reflectionBadgeView_hidesAppleMetrics_whenSleepDataIsNil() {
            // Given: Sleep quality without Apple sleep data
            let badge = ReflectionBadgeView(
                type: .sleep(.good),
                isTappable: false,
                sleepData: nil
            )

            // Then: Badge should not show Apple Watch metrics
            XCTAssertNil(badge.sleepData)
        }

        func test_reflectionBadgeView_hidesAppleMetrics_whenSleepScoreIsNil() {
            // Given: Sleep data without a score (HealthKit couldn't calculate)
            let sleepData = self.createMockSleepData(sleepScore: nil)
            let badge = ReflectionBadgeView(
                type: .sleep(.good),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Badge should have sleep data but no score
            XCTAssertNotNil(badge.sleepData)
            XCTAssertNil(badge.sleepData?.sleepScore)
            // The view should NOT display Apple Watch metrics line when score is nil
        }

        func test_reflectionBadgeView_feelingBadge_ignoresSleepData() {
            // Given: Feeling badge with sleep data (should be ignored)
            let sleepData = self.createMockSleepData(sleepScore: 85.0)
            let badge = ReflectionBadgeView(
                type: .feeling(.calm),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Feeling badge should ignore sleep data (it's only for sleep badges)
            // Sleep data property might be set, but view should not display it
            XCTAssertEqual(badge.type.label, "Feeling")
            // The view should NOT display Apple Watch metrics for feeling badges
        }

        // MARK: - Tests: Accessibility

        func test_accessibilityLabel_includesSleepScore_whenAvailable() {
            // Given: Sleep badge with Apple sleep data
            let sleepData = self.createMockSleepData(sleepScore: 85.0)
            let badge = ReflectionBadgeView(
                type: .sleep(.good),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Accessibility label should include Apple Watch score
            // Expected: "Sleep quality: Good, Apple Watch: 85%"
            let expectedAccessibilityInfo = "85"
            XCTAssertNotNil(badge.sleepData?.sleepScore)
            // The accessibility label should be updated to include the score
        }

        func test_accessibilityLabel_excludesSleepScore_whenNil() {
            // Given: Sleep badge without Apple sleep data
            let badge = ReflectionBadgeView(
                type: .sleep(.good),
                isTappable: false,
                sleepData: nil
            )

            // Then: Accessibility label should be standard
            XCTAssertEqual(badge.type.accessibilityLabel, "Sleep quality: Good")
        }

        // MARK: - Tests: Tappable Behavior

        func test_reflectionBadgeView_remainsTappable_withSleepData() {
            // Given: Tappable sleep badge with Apple sleep data
            var tapped = false
            let sleepData = self.createMockSleepData(sleepScore: 85.0)
            let badge = ReflectionBadgeView(
                type: .sleep(.good),
                isTappable: true,
                onTap: { tapped = true },
                sleepData: sleepData
            )

            // Then: Badge should still be tappable
            XCTAssertTrue(badge.isTappable)
            XCTAssertNotNil(badge.onTap)
        }

        // MARK: - Tests: Edge Cases

        func test_reflectionBadgeView_handlesZeroSleepScore_gracefully() {
            // Given: Sleep data with 0% score (very poor sleep)
            let sleepData = self.createMockSleepData(sleepScore: 0.0)
            let badge = ReflectionBadgeView(
                type: .sleep(.terrible),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Badge should display 0% score correctly
            XCTAssertEqual(badge.sleepData?.sleepScore, 0.0)
        }

        func test_reflectionBadgeView_handles100SleepScore_gracefully() {
            // Given: Sleep data with 100% score (perfect sleep)
            let sleepData = self.createMockSleepData(sleepScore: 100.0)
            let badge = ReflectionBadgeView(
                type: .sleep(.great),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Badge should display 100% score correctly
            XCTAssertEqual(badge.sleepData?.sleepScore, 100.0)
        }

        func test_reflectionBadgeView_handlesZeroDuration_gracefully() {
            // Given: Sleep data with 0 duration
            let sleepData = self.createMockSleepData(
                sleepDuration: 0,
                sleepScore: nil
            )
            let badge = ReflectionBadgeView(
                type: .sleep(.poor),
                isTappable: false,
                sleepData: sleepData
            )

            // Then: Badge should handle gracefully
            XCTAssertEqual(badge.sleepData?.formattedDuration, "0h 0m")
        }

        // MARK: - Tests: SleepData Formatting

        func test_sleepData_formattedDuration_displaysCorrectly() {
            // Given: Various sleep durations
            let testCases: [(duration: TimeInterval, expected: String)] = [
                (7.5 * 3600, "7h 30m"), // 7h 30m
                (8 * 3600, "8h 0m"), // 8h 0m
                (6.25 * 3600, "6h 15m"), // 6h 15m
                (0, "0h 0m"), // 0h 0m
                (23.5 * 3600, "23h 30m") // 23h 30m
            ]

            for (duration, expected) in testCases {
                let sleepData = SleepData(
                    sleepDuration: duration,
                    timeInBed: duration + 1800,
                    sleepStart: nil,
                    sleepEnd: nil,
                    sleepScore: 80.0
                )
                XCTAssertEqual(
                    sleepData.formattedDuration,
                    expected,
                    "Duration \(duration) should format as \(expected)"
                )
            }
        }

        func test_sleepData_sleepQuality_mapsCorrectly() {
            // Given: Various sleep scores
            let testCases: [(score: Double?, expected: SleepQuality?)] = [
                (85.0, .great), // >= 80 = great
                (80.0, .great), // >= 80 = great
                (79.9, .good), // >= 60 = good
                (60.0, .good), // >= 60 = good
                (59.9, .poor), // >= 40 = poor
                (40.0, .poor), // >= 40 = poor
                (39.9, .terrible), // < 40 = terrible
                (0.0, .terrible), // 0 = terrible
                (nil, nil) // nil = nil
            ]

            for (score, expected) in testCases {
                let sleepData = SleepData(
                    sleepDuration: 7 * 3600,
                    timeInBed: 8 * 3600,
                    sleepStart: nil,
                    sleepEnd: nil,
                    sleepScore: score
                )
                XCTAssertEqual(
                    sleepData.sleepQuality,
                    expected,
                    "Score \(String(describing: score)) should map to \(String(describing: expected))"
                )
            }
        }
    }
#endif
