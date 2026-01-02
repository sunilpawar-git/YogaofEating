import XCTest
@testable import Yoga_of_Eating

@MainActor
final class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    var mockProvider: MockAuthCoreProvider!

    override func setUp() {
        super.setUp()
        self.mockProvider = MockAuthCoreProvider()
        self.authService = AuthService(provider: self.mockProvider)
    }

    override func tearDown() {
        self.authService = nil
        self.mockProvider = nil
        super.tearDown()
    }

    func test_initialState_reflectsProviderUser() {
        // Given
        let expectedUser = MockAuthUser(uid: "initial_uid", displayName: "Initial", email: "initial@example.com")
        self.mockProvider.currentUser = expectedUser

        // When (re-initializing ensures initial state is captured)
        self.authService = AuthService(provider: self.mockProvider)

        // Then
        XCTAssertEqual(self.authService.currentUser?.uid, expectedUser.uid)
    }

    func test_signInWithGoogle_updatesCurrentUser() async throws {
        // When
        try await self.authService.signInWithGoogle()

        // Then
        XCTAssertTrue(self.mockProvider.signInCalled)
        XCTAssertNotNil(self.authService.currentUser)
        XCTAssertEqual(self.authService.currentUser?.uid, "mock_uid")
    }

    func test_signOut_clearsCurrentUser() {
        // Given
        self.mockProvider.simulateStateChange(user: MockAuthUser(uid: "some_uid", displayName: nil, email: nil))
        XCTAssertNotNil(self.authService.currentUser)

        // When
        self.authService.signOut()

        // Then
        XCTAssertTrue(self.mockProvider.signOutCalled)
        XCTAssertNil(self.authService.currentUser)
    }

    func test_authStateChangeListener_updatesCurrentUser() {
        // Given
        XCTAssertNil(self.authService.currentUser)

        // When (Simulate provider notifying about a new user)
        let newUser = MockAuthUser(uid: "new_uid", displayName: "New", email: "new@example.com")
        self.mockProvider.simulateStateChange(user: newUser)

        // Then
        XCTAssertEqual(self.authService.currentUser?.uid, "new_uid")
    }

    func test_initialization_restoresPreviousSession() async {
        // Given
        let provider = MockAuthCoreProvider()

        // When
        _ = AuthService(provider: provider)

        // Then - Wait for the restoration Task to execute
        for _ in 0..<10 {
            if provider.restorePreviousSignInCalled {
                break
            }
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
        }

        XCTAssertTrue(
            provider.restorePreviousSignInCalled,
            "restorePreviousSignIn should have been called during initialization"
        )
    }
}
