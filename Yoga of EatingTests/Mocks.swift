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
    var clearAllDataCalled = false
    var updateReflectionCalled = false
    var lastUpdatedReflection: DailyReflection?
    var lastReflectionDate: Date?

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

    func clearAllData() {
        self.clearAllDataCalled = true
        self.historicalData = HistoricalData()
    }

    func updateReflection(for date: Date, reflection: DailyReflection) {
        self.updateReflectionCalled = true
        self.lastUpdatedReflection = reflection
        self.lastReflectionDate = date

        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withReflection(reflection)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                reflection: reflection
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }
    }

    func updateMorningMindCheck(for date: Date, entries: [MindCheckEntry]) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withMindChecks(morningMindCheck: entries)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                morningMindCheck: entries
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }
    }

    func updateEveningMindCheck(for date: Date, entries: [MindCheckEntry]) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withMindChecks(eveningMindCheck: entries)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                eveningMindCheck: entries
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }
    }

    func updateHighlightData(for date: Date, data: HighlightData) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withHighlightData(data)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                highlightData: data
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }
    }

    func updateReflectData(for date: Date, data: ReflectData) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withReflectData(data)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                reflectData: data
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }
    }

    var updateBriefingCalled = false
    var lastUpdatedBriefing: DailyBriefing?

    func updateBriefing(for date: Date, briefing: DailyBriefing) {
        self.updateBriefingCalled = true
        self.lastUpdatedBriefing = briefing

        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withBriefing(briefing)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                briefing: briefing
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }
    }
}

@MainActor
class MockPersistenceService: PersistenceServiceProtocol {
    var savedData: PersistenceService.AppData?
    var saveCalled = false
    var deleteAllCalled = false

    func load() -> PersistenceService.AppData? {
        nil
    }

    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date, historicalData: HistoricalData) {
        self.saveCalled = true
        self.savedData = PersistenceService.AppData(
            meals: meals,
            smileyState: smileyState,
            lastResetDate: lastResetDate,
            historicalData: historicalData
        )
    }

    func deleteAll() {
        self.deleteAllCalled = true
        self.savedData = nil
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

class MockHealthProfileService: HealthProfileServiceProtocol {
    var mockProfile: UserHealthProfile?

    func calculateBMI(height _: Double, weight _: Double, unitSystem _: UnitSystem) -> Double {
        self.mockProfile?.bmi ?? 0.0
    }

    func getBMICategory(bmi _: Double) -> BMICategory {
        self.mockProfile?.bmiCategory ?? .normal
    }

    func calculateBMR(
        weight _: Double,
        height _: Double,
        age _: Int,
        gender _: Gender,
        unitSystem _: UnitSystem
    ) -> Double {
        self.mockProfile?.bmr ?? 0.0
    }

    func calculateTDEE(bmr _: Double, activityLevel _: Double) -> Double {
        self.mockProfile?.tdee ?? 0.0
    }

    func getSensitivityMultiplier(bmi _: Double, age _: Int) -> Double {
        self.mockProfile?.sensitivityMultiplier ?? 1.0
    }

    func getHealthRiskLevel(bmi _: Double, age _: Int) -> HealthRiskLevel {
        self.mockProfile?.riskLevel ?? .low
    }

    func getUserHealthProfile() -> UserHealthProfile? {
        self.mockProfile
    }
}
