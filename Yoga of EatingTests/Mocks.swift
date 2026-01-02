import Combine
import FirebaseAuth
import Foundation
@testable import Yoga_of_Eating

/// Mock for AuthService to enable testing without Firebase
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
        let user = MockAuthUser(uid: "mock_uid", displayName: "Mock User", email: "mock@example.com")
        return user
    }

    func signOut() throws {
        self.signOutCalled = true
        if self.shouldThrowError {
            throw NSError(domain: "Auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sign Out Error"])
        }
        self.currentUser = nil
    }

    func addStateDidChangeListener(_ listener: @escaping (AuthUser?) -> Void) -> Any {
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

/// Mock for CloudSyncService
@MainActor
class MockCloudSyncService: CloudSyncServiceProtocol {
    var uploadedSnapshots: [DailySmileySnapshot] = []
    var fetchResult: [DailySmileySnapshot] = []
    var uploadCalled = false
    var fetchCalled = false
    var shouldFail = false

    func upload(snapshot: DailySmileySnapshot, userId _: String) async throws {
        self.uploadCalled = true
        if self.shouldFail {
            throw NSError(domain: "CloudSync", code: 1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        self.uploadedSnapshots.append(snapshot)
    }

    func fetchAll(userId _: String) async throws -> [DailySmileySnapshot] {
        self.fetchCalled = true
        if self.shouldFail {
            throw NSError(domain: "CloudSync", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
        }
        return self.fetchResult
    }
}

@MainActor
class MockHistoricalDataService: HistoricalDataServiceProtocol {
    @Published var historicalData = HistoricalData()
    var archivedMeals: [Meal]?
    var archivedState: SmileyState?
    var archivedDate: Date?

    func archiveCurrentDay(meals: [Meal], state: SmileyState, date: Date) {
        self.archivedMeals = meals
        self.archivedState = state
        self.archivedDate = date
    }

    func getSnapshot(for date: Date) -> DailySmileySnapshot? {
        self.historicalData.snapshot(for: date)
    }

    func getYearSnapshots(year: Int) -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        return self.historicalData.snapshots(in: start...end)
    }

    func saveHistoricalData() {}

    func syncToFirebase() async throws {}
}

@MainActor
class MockPersistenceService: PersistenceServiceProtocol {
    var savedData: PersistenceService.AppData?

    func load() -> PersistenceService.AppData? {
        nil
    }

    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date, historicalData: HistoricalData) {
        self.savedData = PersistenceService.AppData(
            meals: meals,
            smileyState: smileyState,
            lastResetDate: lastResetDate,
            historicalData: historicalData
        )
    }
}

@MainActor
class MockMealLogicService: MealLogicProvider {
    var mockScore: Double = 0.5
    var nextState = SmileyState.neutral

    func calculateHealthScore(for _: String) -> Double {
        self.mockScore
    }

    func calculateHealthScore(for items: [String]) -> Double {
        guard !items.isEmpty else { return 0.5 }
        return self.mockScore
    }

    func calculateNextState(from _: SmileyState, healthScore _: Double) -> SmileyState {
        self.nextState
    }
}
