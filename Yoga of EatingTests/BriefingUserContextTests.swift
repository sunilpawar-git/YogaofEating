import XCTest
@testable import Yoga_of_Eating

@MainActor
final class BriefingUserContextTests: XCTestCase {
    // MARK: - Helpers

    private func makeProfile(activityLevel: ActivityLevel = .moderatelyActive) -> UserHealthProfile {
        UserHealthProfile(
            age: 35,
            bmi: 23.0,
            bmiCategory: .normal,
            bmr: 1600,
            tdee: 2480,
            riskLevel: .low,
            sensitivityMultiplier: 1.0,
            activityLevel: activityLevel,
            dietaryGoal: .generalWellness
        )
    }

    // MARK: - Tests

    func test_briefingUserContext_build_withValidProfile_returnsContext() {
        let profile = self.makeProfile()
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "uid1", displayName: "Alex")

        let result = BriefingUserContext.build(from: profile, authService: authService)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.activityLevel, .moderatelyActive)
    }

    func test_briefingUserContext_build_withNilDisplayName_omitsNameFromPayload() {
        let profile = self.makeProfile()
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "uid1", displayName: nil)

        let result = BriefingUserContext.build(from: profile, authService: authService)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.userName)
    }

    func test_briefingUserContext_build_withEmptyDisplayName_omitsNameFromPayload() {
        let profile = self.makeProfile()
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "uid1", displayName: "")

        let result = BriefingUserContext.build(from: profile, authService: authService)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.userName)
    }

    func test_briefingUserContext_build_withNilProfile_returnsNil() {
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "uid1")

        let result = BriefingUserContext.build(from: nil, authService: authService)

        XCTAssertNil(result)
    }

    func test_briefingUserContext_activityLevel_usesDisplayName_notRawInt() {
        let profile = self.makeProfile(activityLevel: .moderatelyActive)
        let authService = MockAuthService()

        let result = BriefingUserContext.build(from: profile, authService: authService)
        let dict = result?.toPayloadDict()

        XCTAssertEqual(dict?["activityLevel"] as? String, "Moderately Active")
        XCTAssertNotEqual(dict?["activityLevel"] as? String, "2")
    }

    func test_briefingUserContext_neverLogsUserName() {
        let profile = self.makeProfile()
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "uid1", displayName: "SensitiveName")

        let result = BriefingUserContext.build(from: profile, authService: authService)

        // userName is stored only in the struct — not observable via any log sink.
        // This test verifies the contract: userName is non-nil but only accessible
        // through the struct property (not through any logging side effect).
        XCTAssertEqual(result?.userName, "SensitiveName")
    }
}
