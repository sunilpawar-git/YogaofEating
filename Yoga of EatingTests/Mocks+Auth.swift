import Combine
import FirebaseAuth
import Foundation
@testable import Yoga_of_Eating

// MARK: - MockAuthService

@MainActor
class MockAuthService: AuthServiceProtocol {
    var currentUser: AuthUser?
    var signInCalled = false
    var signOutCalled = false
    var shouldThrowError = false

    func signInWithGoogle() async throws {
        self.signInCalled = true
        if self.shouldThrowError {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"])
        }
    }

    func signOut() {
        self.signOutCalled = true
        self.currentUser = nil
    }
}

struct MockAuthUser: AuthUser {
    var uid: String
    var displayName: String?
    var email: String?
}

@MainActor
class MockAuthCoreProvider: AuthCoreProvider {
    var currentUser: AuthUser?
    var signInCalled = false
    var signOutCalled = false
    var restorePreviousSignInCalled = false
    var shouldThrowError = false
    var listener: ((AuthUser?) -> Void)?

    func signInWithGoogle() async throws -> AuthUser {
        self.signInCalled = true
        if self.shouldThrowError {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"])
        }
        return MockAuthUser(uid: "mock_uid", displayName: "Mock User", email: "mock@example.com")
    }

    func signOut() throws {
        self.signOutCalled = true
        if self.shouldThrowError {
            throw NSError(domain: "Auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sign Out Error"])
        }
        self.currentUser = nil
    }

    func addStateDidChangeListener(_ listener: @escaping (AuthUser?) -> Void) -> Any? {
        self.listener = listener
        return "mock_handle"
    }

    func simulateStateChange(user: AuthUser?) {
        self.currentUser = user
        self.listener?(user)
    }

    func restorePreviousSignIn() async throws -> AuthUser {
        self.restorePreviousSignInCalled = true
        if self.shouldThrowError {
            throw NSError(domain: "Auth", code: 3, userInfo: [NSLocalizedDescriptionKey: "Restore Error"])
        }
        let user = MockAuthUser(uid: "restored_uid", displayName: "Restored User", email: "restored@example.com")
        self.currentUser = user
        self.listener?(user)
        return user
    }
}

// MARK: - MockCloudSyncService

@MainActor
class MockCloudSyncService: CloudSyncServiceProtocol {
    var uploadedSnapshots: [DailySmileySnapshot] = []
    var uploadCalled = false
    var batchUploadedSnapshots: [[DailySmileySnapshot]] = []
    var batchUploadCalled = false
    var shouldFail = false

    func upload(snapshot: DailySmileySnapshot, userId _: String) async throws {
        self.uploadCalled = true
        if self.shouldFail {
            throw NSError(domain: "CloudSync", code: 1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        self.uploadedSnapshots.append(snapshot)
    }

    func uploadBatch(snapshots: [DailySmileySnapshot], userId _: String) async throws {
        self.batchUploadCalled = true
        if self.shouldFail {
            throw NSError(domain: "CloudSync", code: 3, userInfo: [NSLocalizedDescriptionKey: "Batch upload failed"])
        }
        let batchSize = 500
        let chunks = stride(from: 0, to: snapshots.count, by: batchSize).map { startIndex in
            Array(snapshots[startIndex..<min(startIndex + batchSize, snapshots.count)])
        }
        for chunk in chunks {
            self.batchUploadedSnapshots.append(chunk)
        }
    }
}
