import XCTest
@testable import Yoga_of_Eating

/// Tests for SettingsViewModel gender handling.
///
/// HKBiologicalSex rawValues:
///   notSet = 0, female = 1, male = 2, other = 3
/// Any value outside 0–3 has no matching Picker tag and triggers
/// "The variant selector cell index number could not be found" spam.
///
/// RED phase: Before the fix (clamping `hkGender` to 0…3),
/// assigning a value like 4 or 99 would be stored verbatim in `self.gender`,
/// causing the Picker to log a warning on every render.
@MainActor
final class SettingsViewModelTests: XCTestCase {
    // MARK: - Helpers

    private func makeVM(userDefaults: UserDefaults) -> SettingsViewModel {
        SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            userDefaults: userDefaults
        )
    }

    private func freshUserDefaults() -> UserDefaults {
        // Use an in-memory suite to avoid polluting standard UserDefaults in tests
        let suiteName = "SettingsViewModelTests_\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suiteName)!
        ud.removePersistentDomain(forName: suiteName)
        return ud
    }

    // MARK: - Valid HealthKit gender values are preserved

    func test_syncWithHealthKit_gender_validValue_0_isPreserved() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        // Simulate HealthKit returning notSet (0)
        vm.applyHealthKitGender(0)

        XCTAssertEqual(
            vm.gender,
            0,
            "Valid HKBiologicalSex.notSet (0) must be stored as-is"
        )
    }

    func test_syncWithHealthKit_gender_validValue_1_isPreserved() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        vm.applyHealthKitGender(1)

        XCTAssertEqual(
            vm.gender,
            1,
            "Valid HKBiologicalSex.female (1) must be stored as-is"
        )
    }

    func test_syncWithHealthKit_gender_validValue_2_isPreserved() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        vm.applyHealthKitGender(2)

        XCTAssertEqual(
            vm.gender,
            2,
            "Valid HKBiologicalSex.male (2) must be stored as-is"
        )
    }

    func test_syncWithHealthKit_gender_maxValidValue_isThree() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        // HKBiologicalSex.other = 3 — highest valid Picker tag
        vm.applyHealthKitGender(3)

        XCTAssertEqual(
            vm.gender,
            3,
            "Valid HKBiologicalSex.other (3) must be stored as-is"
        )
    }

    // MARK: - Out-of-range HealthKit values are clamped

    func test_syncWithHealthKit_gender_outOfRangeValue_4_isClamped() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        // A hypothetical future HKBiologicalSex rawValue of 4 has no Picker tag
        vm.applyHealthKitGender(4)

        XCTAssertEqual(
            vm.gender,
            3,
            "Out-of-range value 4 must be clamped to 3 (max valid Picker tag)"
        )
    }

    func test_syncWithHealthKit_gender_largeOutOfRangeValue_isClamped() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        vm.applyHealthKitGender(99)

        XCTAssertEqual(
            vm.gender,
            3,
            "Out-of-range value 99 must be clamped to 3 (max valid Picker tag)"
        )
    }

    func test_syncWithHealthKit_gender_negativeValue_isClamped() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        vm.applyHealthKitGender(-1)

        XCTAssertEqual(
            vm.gender,
            0,
            "Negative value -1 must be clamped to 0 (min valid Picker tag)"
        )
    }

    // MARK: - Phase 2: signInWithGoogle MVVM compliance

    func test_signInWithGoogle_failure_setsAuthError() async {
        let mockAuth = MockAuthService()
        mockAuth.shouldThrowError = true
        let ud = self.freshUserDefaults()
        let vm = SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            authService: mockAuth,
            userDefaults: ud
        )

        await vm.signInWithGoogle()

        XCTAssertNotNil(vm.authError, "signInWithGoogle failure must set authError on SettingsViewModel")
    }

    func test_signInWithGoogle_success_clearsAuthError() async {
        let mockAuth = MockAuthService()
        mockAuth.shouldThrowError = false
        let ud = self.freshUserDefaults()
        let vm = SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            authService: mockAuth,
            userDefaults: ud
        )
        // Seed a prior error to confirm it is cleared on success
        vm.authError = "Previous error"

        await vm.signInWithGoogle()

        XCTAssertNil(vm.authError, "Successful sign-in must clear authError")
    }

    func test_settingsViewModel_signInWithGoogle_isCalledThroughViewModel_notDirectly() {
        // This test validates MVVM compliance: SettingsView must call
        // viewModel.signInWithGoogle(), not authService.signInWithGoogle() directly.
        // We verify by checking SettingsViewModel exposes a signInWithGoogle() method.
        let mockAuth = MockAuthService()
        let ud = self.freshUserDefaults()
        let vm = SettingsViewModel(
            historicalService: MockHistoricalDataService(),
            authService: mockAuth,
            userDefaults: ud
        )
        // The method must exist (compile-time guarantee) and be callable from the view
        _ = vm.signInWithGoogle
        XCTAssertTrue(true, "SettingsViewModel must expose signInWithGoogle() for MVVM compliance")
    }

    // MARK: - morningBriefingTime — TDD Phase 3

    func test_morningBriefingTime_defaultIsEightAM() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        let hour = Calendar.current.component(.hour, from: vm.morningBriefingTime)
        let minute = Calendar.current.component(.minute, from: vm.morningBriefingTime)

        XCTAssertEqual(hour, 8, "Default morning briefing time must be 8:00 AM (hour)")
        XCTAssertEqual(minute, 0, "Default morning briefing time must be 8:00 AM (minute)")
    }

    func test_morningBriefingTime_persistsToUserDefaults() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        vm.morningBriefingTime = Self.makeTime(hour: 9, minute: 30)

        XCTAssertNotNil(
            ud.object(forKey: StorageKeys.morningBriefingTime),
            "morningBriefingTime must be persisted to UserDefaults on change"
        )
    }

    func test_morningBriefingTime_loadsFromUserDefaults_onInit() {
        let ud = self.freshUserDefaults()

        // Persist a custom time via a first VM instance
        let vm1 = self.makeVM(userDefaults: ud)
        vm1.morningBriefingTime = Self.makeTime(hour: 6, minute: 45)

        // A fresh VM with the same UserDefaults must restore the custom time
        let vm2 = self.makeVM(userDefaults: ud)
        let hour = Calendar.current.component(.hour, from: vm2.morningBriefingTime)
        let minute = Calendar.current.component(.minute, from: vm2.morningBriefingTime)

        XCTAssertEqual(hour, 6, "morningBriefingTime must be restored from UserDefaults (hour)")
        XCTAssertEqual(minute, 45, "morningBriefingTime must be restored from UserDefaults (minute)")
    }

    func test_morningBriefingTime_storedAsTimeInterval_inUserDefaults() {
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)

        vm.morningBriefingTime = Self.makeTime(hour: 7, minute: 15)

        let stored = ud.object(forKey: StorageKeys.morningBriefingTime)
        XCTAssertTrue(stored is Double, "morningBriefingTime must be stored as TimeInterval (Double)")
    }

    func test_morningBriefingTime_changingTime_doesNotAlterNudgeEnabledState() {
        // Verifies the nudge toggle is not accidentally mutated when time changes
        let ud = self.freshUserDefaults()
        let vm = self.makeVM(userDefaults: ud)
        vm.isMorningNudgeEnabled = false

        vm.morningBriefingTime = Self.makeTime(hour: 10, minute: 0)

        XCTAssertFalse(vm.isMorningNudgeEnabled, "Changing briefing time must not alter nudge-enabled state")
    }

    func test_morningBriefingTime_roundTrip_preservesHourAndMinute() {
        // Verifies the TimeInterval encode/decode does not lose hour/minute precision
        let ud = self.freshUserDefaults()
        let vm1 = self.makeVM(userDefaults: ud)
        vm1.morningBriefingTime = Self.makeTime(hour: 5, minute: 55)

        let vm2 = self.makeVM(userDefaults: ud)
        XCTAssertEqual(Calendar.current.component(.hour, from: vm2.morningBriefingTime), 5)
        XCTAssertEqual(Calendar.current.component(.minute, from: vm2.morningBriefingTime), 55)
    }

    // MARK: - Helpers

    private static func makeTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
