#if canImport(XCTest)
    import Combine
    import XCTest
    @testable import Yoga_of_Eating

    /// Integration tests for the activity-level → TDEE → calorie-pill pipeline.
    ///
    /// RED tests (failing before Phase 3 implementation):
    ///   - test_activityLevel_change_firesMainViewModelObjectWillChange
    ///     (objectWillChange not wired to AppNotification yet)
    ///
    /// GREEN tests (data pipeline was already correct — verifying no regression):
    ///   - test_activityLevel_change_updatesCaloriePillTDEE
    ///   - test_allActivityLevels_produceTDEEInCorrectOrder
    ///   - test_activityLevel_change_updatesCalorieDetailBaseTDEE
    @MainActor
    final class ActivityLevelIntegrationTests: XCTestCase {
        // MARK: - Helpers

        private func freshUserDefaults() -> UserDefaults {
            let suite = "ActivityLevelIntegration_\(UUID().uuidString)"
            let ud = UserDefaults(suiteName: suite)!
            ud.removePersistentDomain(forName: suite)
            return ud
        }

        /// Seeds a complete, valid health profile into the given UserDefaults.
        private func seedProfile(_ ud: UserDefaults, activityLevel: ActivityLevel) {
            ud.set("173", forKey: StorageKeys.userHeight)
            ud.set("71", forKey: StorageKeys.userWeight)
            ud.set("41", forKey: StorageKeys.userAge)
            ud.set(1, forKey: StorageKeys.userGender) // male
            ud.set(0, forKey: StorageKeys.unitSystem) // metric
            ud.set(activityLevel.rawValue, forKey: StorageKeys.userActivityLevel)
        }

        private func makeMainVM(userDefaults ud: UserDefaults) -> MainViewModel {
            MainViewModel(
                healthProfileService: HealthProfileService(userDefaults: ud),
                skipDataLoading: true
            )
        }

        private func makeSettingsVM(userDefaults ud: UserDefaults) -> SettingsViewModel {
            SettingsViewModel(
                historicalService: MockHistoricalDataService(),
                userDefaults: ud
            )
        }

        // MARK: - TDEE Pipeline Tests

        func test_activityLevel_change_updatesCaloriePillTDEE() {
            // Given: both VMs share UserDefaults, profile seeded as sedentary
            let ud = self.freshUserDefaults()
            self.seedProfile(ud, activityLevel: .sedentary)
            let mainVM = self.makeMainVM(userDefaults: ud)
            let settingsVM = self.makeSettingsVM(userDefaults: ud)

            let sedentaryTDEE = mainVM.caloriePillData.tdee

            // When: user selects moderately active (1.55 vs 1.2 multiplier)
            settingsVM.activityLevel = .moderatelyActive

            let updatedTDEE = mainVM.caloriePillData.tdee

            // Then
            XCTAssertNotNil(sedentaryTDEE, "Sedentary TDEE must be non-nil with a complete profile")
            XCTAssertNotNil(updatedTDEE, "Updated TDEE must be non-nil with a complete profile")
            if let old = sedentaryTDEE, let new = updatedTDEE {
                XCTAssertGreaterThan(new, old, "Moderately active TDEE must exceed sedentary TDEE")
            }
        }

        func test_activityLevel_change_updatesCalorieDetailBaseTDEE() {
            let ud = self.freshUserDefaults()
            self.seedProfile(ud, activityLevel: .sedentary)
            let mainVM = self.makeMainVM(userDefaults: ud)
            let settingsVM = self.makeSettingsVM(userDefaults: ud)

            let sedentaryBase = mainVM.calorieDetailData.profileBaseTdee
            settingsVM.activityLevel = .veryActive
            let veryActiveBase = mainVM.calorieDetailData.profileBaseTdee

            XCTAssertNotNil(sedentaryBase)
            XCTAssertNotNil(veryActiveBase)
            if let old = sedentaryBase, let new = veryActiveBase {
                XCTAssertGreaterThan(new, old, "Very active base TDEE must exceed sedentary base TDEE")
            }
        }

        func test_allActivityLevels_produceTDEEInStrictlyIncreasingOrder() {
            // Verifies ActivityLevel.multiplier ordering matches real computed TDEE
            let ud = self.freshUserDefaults()
            let tdees: [Int] = ActivityLevel.allCases.compactMap { level in
                self.seedProfile(ud, activityLevel: level)
                return self.makeMainVM(userDefaults: ud).caloriePillData.tdee
            }

            XCTAssertEqual(tdees.count, ActivityLevel.allCases.count, "All activity levels must produce a non-nil TDEE")
            for index in 1..<tdees.count {
                XCTAssertGreaterThan(
                    tdees[index],
                    tdees[index - 1],
                    "TDEE for \(ActivityLevel.allCases[index]) must exceed \(ActivityLevel.allCases[index - 1])"
                )
            }
        }

        func test_activityLevel_revertToSedentary_restoresOriginalTDEE() {
            let ud = self.freshUserDefaults()
            self.seedProfile(ud, activityLevel: .sedentary)
            let mainVM = self.makeMainVM(userDefaults: ud)
            let settingsVM = self.makeSettingsVM(userDefaults: ud)

            let originalTDEE = mainVM.caloriePillData.tdee
            settingsVM.activityLevel = .veryActive
            settingsVM.activityLevel = .sedentary
            let revertedTDEE = mainVM.caloriePillData.tdee

            XCTAssertEqual(originalTDEE, revertedTDEE, "Reverting to sedentary must restore the original TDEE")
        }

        // MARK: - Reactivity (objectWillChange) Test — RED until notification wired

        func test_activityLevel_change_firesMainViewModelObjectWillChange() {
            // Given
            let ud = self.freshUserDefaults()
            self.seedProfile(ud, activityLevel: .sedentary)
            let mainVM = self.makeMainVM(userDefaults: ud)
            let settingsVM = self.makeSettingsVM(userDefaults: ud)

            var willChangeCount = 0
            var cancellables = Set<AnyCancellable>()
            mainVM.objectWillChange
                .sink { _ in willChangeCount += 1 }
                .store(in: &cancellables)

            // When
            settingsVM.activityLevel = .lightlyActive

            // Then: objectWillChange must have fired so SwiftUI re-renders the calorie pill
            XCTAssertGreaterThan(
                willChangeCount,
                0,
                "MainViewModel.objectWillChange must fire when activity level changes so SwiftUI re-renders"
            )
        }

        // MARK: - AppNotification SSOT Test

        func test_appNotification_healthProfileDidChange_constantExists() {
            // Compile-time guarantee: the constant must exist in AppNotification
            let name = AppNotification.healthProfileDidChange
            XCTAssertFalse(name.rawValue.isEmpty, "healthProfileDidChange notification name must be non-empty")
        }
    }
#endif
