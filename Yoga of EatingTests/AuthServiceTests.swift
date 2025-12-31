#if canImport(XCTest)
    import XCTest

    // NOTE: AuthService tests are disabled because they require Firebase to be configured.
    //
    // The AuthService class accesses Firebase Auth and Google Sign-In SDKs, which cannot
    // be safely initialized in a unit test environment without the full Firebase setup.
    //
    // To test AuthService functionality, use:
    // 1. Integration tests with Firebase Emulator Suite
    // 2. UI tests that run with the full app context
    // 3. Manual testing in development builds
    //
    // The following tests would be implemented if Firebase mocking was available:
    // - test_signOut_clearsCurrentUser()
    // - test_initialState_withNilUser_hasNoCurrentUser()
    // - test_signInWithGoogle_throwsError_whenClientIDMissing()
    // - test_signInWithGoogle_updatesCurrentUser_onSuccess()

    final class AuthServiceTests: XCTestCase {
        func test_placeholder() {
            // This is a placeholder test to ensure the test target compiles.
            // Actual AuthService testing requires Firebase integration.
            XCTAssertTrue(true, "AuthService tests are skipped - Firebase not available in test environment")
        }
    }
#endif
