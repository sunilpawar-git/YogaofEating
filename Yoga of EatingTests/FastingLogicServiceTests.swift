#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class FastingLogicServiceTests: XCTestCase {
        // MARK: - Fasting Period Calculation Tests

        func test_calculateFastingPeriods_emptyMeals_returnsEmpty() {
            let periods = FastingLogicService.calculateFastingPeriods(from: [])
            XCTAssertTrue(periods.isEmpty)
        }

        func test_calculateFastingPeriods_singleMeal_returnsEmpty() {
            let meal = Meal(timestamp: Date(), mealType: .breakfast, items: ["Coffee"])
            let periods = FastingLogicService.calculateFastingPeriods(from: [meal])
            XCTAssertTrue(periods.isEmpty)
        }

        func test_calculateFastingPeriods_twoMeals_returnsOnePeriod() {
            let date1 = Date(timeIntervalSince1970: 1_704_067_200) // 8:00 AM
            let date2 = Date(timeIntervalSince1970: 1_704_110_400) // 8:00 PM (12h later)

            let meal1 = Meal(timestamp: date1, mealType: .breakfast, items: ["Coffee"])
            let meal2 = Meal(timestamp: date2, mealType: .dinner, items: ["Salad"])

            let periods = FastingLogicService.calculateFastingPeriods(from: [meal1, meal2])

            XCTAssertEqual(periods.count, 1)
            XCTAssertEqual(periods.first?.startMealId, meal1.id)
            XCTAssertEqual(periods.first?.endMealId, meal2.id)
        }

        func test_calculateFastingPeriods_multipleMeals_returnsCorrectPeriods() {
            let date1 = Date(timeIntervalSince1970: 1_704_067_200) // 8:00 AM
            let date2 = Date(timeIntervalSince1970: 1_704_081_600) // 12:00 PM (4h)
            let date3 = Date(timeIntervalSince1970: 1_704_110_400) // 8:00 PM (8h)

            let meal1 = Meal(timestamp: date1, mealType: .breakfast, items: ["Coffee"])
            let meal2 = Meal(timestamp: date2, mealType: .lunch, items: ["Salad"])
            let meal3 = Meal(timestamp: date3, mealType: .dinner, items: ["Pasta"])

            let periods = FastingLogicService.calculateFastingPeriods(from: [meal1, meal2, meal3])

            XCTAssertEqual(periods.count, 2)
        }

        func test_calculateFastingPeriods_unsortedMeals_sortsCorrectly() {
            let date1 = Date(timeIntervalSince1970: 1_704_067_200)
            let date2 = Date(timeIntervalSince1970: 1_704_110_400)

            let meal1 = Meal(timestamp: date1, mealType: .breakfast, items: ["Coffee"])
            let meal2 = Meal(timestamp: date2, mealType: .dinner, items: ["Salad"])

            // Pass meals in reverse order
            let periods = FastingLogicService.calculateFastingPeriods(from: [meal2, meal1])

            XCTAssertEqual(periods.count, 1)
            XCTAssertEqual(periods.first?.startMealId, meal1.id) // Earlier meal should be start
            XCTAssertEqual(periods.first?.endMealId, meal2.id)
        }

        // MARK: - FastingPeriod Model Tests

        func test_fastingPeriod_duration_calculatedCorrectly() {
            let start = Date(timeIntervalSince1970: 1_704_067_200)
            let end = Date(timeIntervalSince1970: 1_704_117_600) // 14 hours later

            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: end
            )

            XCTAssertEqual(period.duration, 50400, accuracy: 1) // 14h in seconds
            XCTAssertEqual(period.durationInHours, 14.0, accuracy: 0.01)
        }

        func test_fastingPeriod_formattedDuration_hoursOnly() {
            let start = Date(timeIntervalSince1970: 0)
            let end = Date(timeIntervalSince1970: 50400) // 14h exactly

            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: end
            )

            XCTAssertEqual(period.formattedDuration, "14h")
        }

        func test_fastingPeriod_formattedDuration_withMinutes() {
            let start = Date(timeIntervalSince1970: 0)
            let end = Date(timeIntervalSince1970: 59400) // 16h 30m

            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: end
            )

            XCTAssertEqual(period.formattedDuration, "16h 30m")
        }

        func test_fastingPeriod_formattedDuration_roundsDownMinutes() {
            let start = Date(timeIntervalSince1970: 0)
            let end = Date(timeIntervalSince1970: 52200) // 14h 30m exactly shows minutes

            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: end
            )

            XCTAssertEqual(period.formattedDuration, "14h 30m")
        }

        func test_fastingPeriod_formattedDuration_ignoresSmallMinutes() {
            let start = Date(timeIntervalSince1970: 0)
            let end = Date(timeIntervalSince1970: 51900) // 14h 25m - should show just 14h

            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: end
            )

            XCTAssertEqual(period.formattedDuration, "14h")
        }

        func test_fastingPeriod_isSignificant_true_for12Hours() {
            let start = Date(timeIntervalSince1970: 0)
            let end = Date(timeIntervalSince1970: 43200) // 12h

            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: end
            )

            XCTAssertTrue(period.isSignificant)
        }

        func test_fastingPeriod_isSignificant_false_under12Hours() {
            let start = Date(timeIntervalSince1970: 0)
            let end = Date(timeIntervalSince1970: 39600) // 11h

            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: end
            )

            XCTAssertFalse(period.isSignificant)
        }

        func test_fastingPeriod_glowIntensity_zeroUnder12Hours() {
            let start = Date(timeIntervalSince1970: 0)
            let end = Date(timeIntervalSince1970: 39600) // 11h

            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: end
            )

            XCTAssertEqual(period.glowIntensity, 0.0)
        }

        func test_fastingPeriod_glowIntensity_increasesWithDuration() {
            let start = Date(timeIntervalSince1970: 0)

            let period12h = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: Date(timeIntervalSince1970: 43200) // 12h
            )

            let period16h = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: Date(timeIntervalSince1970: 57600) // 16h
            )

            let period20h = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: Date(timeIntervalSince1970: 72000) // 20h
            )

            XCTAssertGreaterThan(period16h.glowIntensity, period12h.glowIntensity)
            XCTAssertGreaterThan(period20h.glowIntensity, period16h.glowIntensity)
            XCTAssertEqual(period20h.glowIntensity, 1.0) // Max at 20h+
        }

        // MARK: - Spacing Calculation Tests

        func test_calculateSpacing_minimumSpacing() {
            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: Date(timeIntervalSince1970: 0),
                endTime: Date(timeIntervalSince1970: 60) // 1 minute
            )

            let spacing = FastingLogicService.calculateSpacing(for: period)

            XCTAssertGreaterThanOrEqual(spacing, FastingLogicService.minimumSpacing)
        }

        func test_calculateSpacing_increasesWithDuration() {
            let start = Date(timeIntervalSince1970: 0)

            let period1h = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: Date(timeIntervalSince1970: 3600) // 1h
            )

            let period14h = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: start,
                endTime: Date(timeIntervalSince1970: 50400) // 14h
            )

            let spacing1h = FastingLogicService.calculateSpacing(for: period1h)
            let spacing14h = FastingLogicService.calculateSpacing(for: period14h)

            XCTAssertGreaterThan(spacing14h, spacing1h)
        }

        // MARK: - Badge Visibility Tests

        func test_shouldShowBadge_true_for1HourOrMore() {
            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: Date(timeIntervalSince1970: 0),
                endTime: Date(timeIntervalSince1970: 3600) // 1h
            )

            XCTAssertTrue(FastingLogicService.shouldShowBadge(for: period))
        }

        func test_shouldShowBadge_false_underOneHour() {
            let period = FastingPeriod(
                startMealId: UUID(),
                endMealId: UUID(),
                startTime: Date(timeIntervalSince1970: 0),
                endTime: Date(timeIntervalSince1970: 1800) // 30min
            )

            XCTAssertFalse(FastingLogicService.shouldShowBadge(for: period))
        }
    }
#endif

