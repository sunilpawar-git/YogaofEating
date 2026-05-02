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
}
