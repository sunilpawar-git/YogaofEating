#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    // MARK: - CalorieDetailData — new computed properties (TDD: Red phase)

    final class CalorieDetailSheetTests: XCTestCase {
        // MARK: - Helpers

        private func makeDetail(
            consumed: Int = 560,
            tdee: Int? = 2074,
            profileBaseTdee: Int? = 1910,
            basalCalories: Double? = 777,
            activeCalories: Double? = 164
        ) -> CalorieDetailData {
            CalorieDetailData(
                consumed: consumed,
                tdee: tdee,
                profileBaseTdee: profileBaseTdee,
                meals: [],
                basalCalories: basalCalories,
                activeCalories: activeCalories
            )
        }

        // MARK: - totalBurned

        func test_calorieDetailData_totalBurned_sumsBasalAndActive() {
            let detail = self.makeDetail(basalCalories: 777, activeCalories: 164)
            XCTAssertEqual(detail.totalBurned, 941)
        }

        func test_calorieDetailData_totalBurned_nilWhenBasalMissing() {
            let detail = self.makeDetail(basalCalories: nil, activeCalories: 164)
            XCTAssertNil(detail.totalBurned)
        }

        func test_calorieDetailData_totalBurned_nilWhenActiveMissing() {
            let detail = self.makeDetail(basalCalories: 777, activeCalories: nil)
            XCTAssertNil(detail.totalBurned)
        }

        func test_calorieDetailData_totalBurned_nilWhenBothMissing() {
            let detail = self.makeDetail(basalCalories: nil, activeCalories: nil)
            XCTAssertNil(detail.totalBurned)
        }

        func test_calorieDetailData_totalBurned_roundsToNearestInt() {
            let detail = self.makeDetail(basalCalories: 777.6, activeCalories: 163.7)
            XCTAssertEqual(detail.totalBurned, 941) // 777.6 + 163.7 = 941.3 → 941
        }

        // MARK: - hasGoalBreakdown

        func test_calorieDetailData_hasGoalBreakdown_trueWhenProfileAndActiveExist() {
            let detail = self.makeDetail(profileBaseTdee: 1910, activeCalories: 164)
            XCTAssertTrue(detail.hasGoalBreakdown)
        }

        func test_calorieDetailData_hasGoalBreakdown_falseWhenNoProfile() {
            let detail = self.makeDetail(profileBaseTdee: nil, activeCalories: 164)
            XCTAssertFalse(detail.hasGoalBreakdown)
        }

        func test_calorieDetailData_hasGoalBreakdown_falseWhenActiveIsZero() {
            let detail = self.makeDetail(profileBaseTdee: 1910, activeCalories: 0)
            XCTAssertFalse(detail.hasGoalBreakdown, "Zero exercise means no breakdown to show")
        }

        func test_calorieDetailData_hasGoalBreakdown_falseWhenActiveNil() {
            let detail = self.makeDetail(profileBaseTdee: 1910, activeCalories: nil)
            XCTAssertFalse(detail.hasGoalBreakdown)
        }

        func test_calorieDetailData_hasGoalBreakdown_falseWhenBothMissing() {
            let detail = self.makeDetail(profileBaseTdee: nil, activeCalories: nil)
            XCTAssertFalse(detail.hasGoalBreakdown)
        }

        // MARK: - progressFraction

        func test_calorieDetailData_progressFraction_correctRatio() {
            let detail = self.makeDetail(consumed: 560, tdee: 2074)
            XCTAssertEqual(detail.progressFraction, 560.0 / 2074.0, accuracy: 0.001)
        }

        func test_calorieDetailData_progressFraction_zeroWhenTDEENil() {
            let detail = self.makeDetail(consumed: 560, tdee: nil)
            XCTAssertEqual(detail.progressFraction, 0.0, accuracy: 0.001)
        }

        func test_calorieDetailData_progressFraction_clampedAtOneWhenOverGoal() {
            let detail = self.makeDetail(consumed: 3000, tdee: 2000)
            XCTAssertEqual(detail.progressFraction, 1.0, accuracy: 0.001)
        }

        func test_calorieDetailData_progressFraction_zeroWhenConsumedZero() {
            let detail = self.makeDetail(consumed: 0, tdee: 2000)
            XCTAssertEqual(detail.progressFraction, 0.0, accuracy: 0.001)
        }

        // MARK: - progressFillColor (mirrors CaloriePillData.fillColor thresholds)

        func test_calorieDetailData_progressFillColor_onTrackBelow70Percent() {
            // 27% consumed
            let detail = self.makeDetail(consumed: 560, tdee: 2074)
            XCTAssertEqual(detail.progressFillColor, AppTheme.CaloriePill.fillOnTrack)
        }

        func test_calorieDetailData_progressFillColor_approachingAt80Percent() {
            // 80% consumed
            let detail = self.makeDetail(consumed: 1600, tdee: 2000)
            XCTAssertEqual(detail.progressFillColor, AppTheme.CaloriePill.fillApproaching)
        }

        func test_calorieDetailData_progressFillColor_overAt100Percent() {
            // 105% consumed
            let detail = self.makeDetail(consumed: 2100, tdee: 2000)
            XCTAssertEqual(detail.progressFillColor, AppTheme.CaloriePill.fillOver)
        }

        func test_calorieDetailData_progressFillColor_onTrackWhenTDEENil() {
            let detail = self.makeDetail(consumed: 560, tdee: nil)
            XCTAssertEqual(detail.progressFillColor, AppTheme.CaloriePill.fillOnTrack)
        }

        // MARK: - Strings: new keys (compile-time existence check)

        func test_strings_sectionGoalBreakdown_isDefined() {
            XCTAssertFalse(Strings.CaloriePill.sectionGoalBreakdown.isEmpty)
        }

        func test_strings_rowGoalTotal_isDefined() {
            XCTAssertFalse(Strings.CaloriePill.rowGoalTotal.isEmpty)
        }
    }

#endif
