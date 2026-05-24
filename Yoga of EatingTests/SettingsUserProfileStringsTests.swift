import XCTest
@testable import Yoga_of_Eating

/// SSOT coverage for Strings.Settings constants used in UserProfileSettingsView.
///
/// A compile error here means the constant is missing from Strings.swift — the
/// Red phase in the TDD cycle.
@MainActor
final class SettingsUserProfileStringsTests: XCTestCase {
    // MARK: - Navigation

    func test_profileAndHealthTitle_exists() {
        XCTAssertEqual(Strings.Settings.profileAndHealthTitle, "Profile & Health")
    }

    // MARK: - Personal Details section

    func test_personalDetailsSectionHeader_exists() {
        XCTAssertEqual(Strings.Settings.personalDetailsSectionHeader, "Personal Details")
    }

    func test_personalDetailsFooter_exists() {
        XCTAssertEqual(
            Strings.Settings.personalDetailsFooter,
            "This information is used to calculate your health insights and personalize feedback."
        )
    }

    func test_nameLabel_exists() {
        XCTAssertEqual(Strings.Settings.nameLabel, "Name")
    }

    func test_genderPickerLabel_exists() {
        XCTAssertEqual(Strings.Settings.genderPickerLabel, "Gender")
    }

    func test_genderUnspecified_exists() {
        XCTAssertEqual(Strings.Settings.genderUnspecified, "Unspecified")
    }

    func test_genderMale_exists() {
        XCTAssertEqual(Strings.Settings.genderMale, "Male")
    }

    func test_genderFemale_exists() {
        XCTAssertEqual(Strings.Settings.genderFemale, "Female")
    }

    func test_genderOther_exists() {
        XCTAssertEqual(Strings.Settings.genderOther, "Other")
    }

    func test_ageLabel_exists() {
        XCTAssertEqual(Strings.Settings.ageLabel, "Age")
    }

    func test_unitSystemPickerLabel_exists() {
        XCTAssertEqual(Strings.Settings.unitSystemPickerLabel, "Unit System")
    }

    func test_unitMetric_exists() {
        XCTAssertEqual(Strings.Settings.unitMetric, "Metric")
    }

    func test_unitImperial_exists() {
        XCTAssertEqual(Strings.Settings.unitImperial, "Imperial")
    }

    func test_heightLabelMetric_exists() {
        XCTAssertEqual(Strings.Settings.heightLabelMetric, "Height (cm)")
    }

    func test_heightLabelImperial_exists() {
        XCTAssertEqual(Strings.Settings.heightLabelImperial, "Height (ft/in)")
    }

    func test_weightLabelMetric_exists() {
        XCTAssertEqual(Strings.Settings.weightLabelMetric, "Weight (kg)")
    }

    func test_weightLabelImperial_exists() {
        XCTAssertEqual(Strings.Settings.weightLabelImperial, "Weight (lbs)")
    }

    // MARK: - Health Insights section

    func test_healthInsightsSectionHeader_exists() {
        XCTAssertEqual(Strings.Settings.healthInsightsSectionHeader, "Health Insights")
    }

    func test_bmiLabel_exists() {
        XCTAssertEqual(Strings.Settings.bmiLabel, "BMI")
    }

    func test_bmiCategoryLabel_exists() {
        XCTAssertEqual(Strings.Settings.bmiCategoryLabel, "Category")
    }

    func test_dailyEnergyLabel_exists() {
        XCTAssertEqual(Strings.Settings.dailyEnergyLabel, "Daily Energy")
    }

    func test_riskLevelLabel_exists() {
        XCTAssertEqual(Strings.Settings.riskLevelLabel, "Risk Level")
    }

    func test_healthInsightsEmptyState_exists() {
        XCTAssertEqual(
            Strings.Settings.healthInsightsEmptyState,
            "Complete your personal details above to see health insights"
        )
    }

    // MARK: - Privacy section

    func test_showHealthInsightsToggle_exists() {
        XCTAssertEqual(Strings.Settings.showHealthInsightsToggle, "Show Health Insights")
    }

    func test_privacySectionHeader_exists() {
        XCTAssertEqual(Strings.Settings.privacySectionHeader, "Privacy")
    }

    func test_privacyFooter_exists() {
        XCTAssertEqual(
            Strings.Settings.privacyFooter,
            "All health calculations are done on your device. Data never leaves your phone except for encrypted cloud sync."
        )
    }
}
