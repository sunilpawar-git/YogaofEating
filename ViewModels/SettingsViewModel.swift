import Combine
import Foundation
import HealthKit
#if canImport(UIKit)
    import UIKit
#endif
#if canImport(Network)
    import Network
#endif

/// ViewModel for the Settings screen, owning all user preferences and sync logic.
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - User Profile Published Properties

    @Published var name: String {
        didSet { self.userDefaults.set(self.name, forKey: Keys.name) }
    }

    @Published var height: String {
        didSet { self.userDefaults.set(self.height, forKey: Keys.height) }
    }

    @Published var weight: String {
        didSet { self.userDefaults.set(self.weight, forKey: Keys.weight) }
    }

    @Published var gender: Int {
        didSet { self.userDefaults.set(self.gender, forKey: Keys.gender) }
    }

    @Published var age: String {
        didSet { self.userDefaults.set(self.age, forKey: Keys.age) }
    }

    // MARK: - Appearance Published Properties

    @Published var theme: Int {
        didSet { self.userDefaults.set(self.theme, forKey: Keys.theme) }
    }

    @Published var unitSystem: Int {
        didSet { self.userDefaults.set(self.unitSystem, forKey: Keys.unitSystem) }
    }

    // MARK: - Notifications Published Properties

    @Published var isMorningNudgeEnabled: Bool {
        didSet {
            self.userDefaults.set(self.isMorningNudgeEnabled, forKey: Keys.morningNudge)
            self.handleMorningNudgeChange(self.isMorningNudgeEnabled)
        }
    }

    @Published var areMealRemindersEnabled: Bool {
        didSet { self.userDefaults.set(self.areMealRemindersEnabled, forKey: Keys.mealReminders) }
    }

    // MARK: - Sensory Published Properties

    @Published var areHapticsEnabled: Bool {
        didSet { self.userDefaults.set(self.areHapticsEnabled, forKey: Keys.haptics) }
    }

    @Published var isSoundEnabled: Bool {
        didSet { self.userDefaults.set(self.isSoundEnabled, forKey: Keys.sound) }
    }

    // MARK: - Integrations & Privacy Published Properties

    @Published var isHealthSyncEnabled: Bool {
        didSet {
            self.userDefaults.set(self.isHealthSyncEnabled, forKey: Keys.healthSync)
            if self.isHealthSyncEnabled {
                self.syncWithHealthKit()
            }
        }
    }

    @Published var isPersonalizedFeedbackEnabled: Bool {
        didSet { self.userDefaults.set(self.isPersonalizedFeedbackEnabled, forKey: Keys.personalizedFeedback) }
    }

    @Published var showHealthInsights: Bool {
        didSet { self.userDefaults.set(self.showHealthInsights, forKey: Keys.healthInsights) }
    }

    // MARK: - Cloud Sync Published Properties

    @Published var syncStatus: SyncStatus = .idle

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private let historicalService: any HistoricalDataServiceProtocol
    private var syncTask: Task<Void, Never>?
    private let networkMonitor: NWPathMonitor?
    private var isNetworkAvailable = true

    // MARK: - Constants

    private enum Keys {
        static let name = "user_name"
        static let height = "user_height"
        static let weight = "user_weight"
        static let gender = "user_gender"
        static let age = "user_age"
        static let theme = "app_theme"
        static let unitSystem = "unit_system"
        static let morningNudge = "morning_nudge_enabled"
        static let mealReminders = "meal_reminders_enabled"
        static let haptics = "haptics_enabled"
        static let sound = "sound_enabled"
        static let healthSync = "health_sync_enabled"
        static let personalizedFeedback = "personalized_feedback_enabled"
        static let healthInsights = "show_health_insights"
    }

    private let SYNC_SUCCESS_DISPLAY_DURATION: UInt64 = 2_000_000_000 // 2 seconds
    private let SYNC_ERROR_DISPLAY_DURATION: UInt64 = 3_000_000_000 // 3 seconds
    private let SYNC_MAX_RETRY_ATTEMPTS = 3
    private let SYNC_RETRY_DELAY: UInt64 = 1_000_000_000 // 1 second

    // MARK: - Sync Status Enum

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
    }

    // MARK: - Initialization

    init(
        historicalService: any HistoricalDataServiceProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
        self.historicalService = historicalService

        // Load initial values from UserDefaults
        self.name = userDefaults.string(forKey: Keys.name) ?? "User"
        self.height = userDefaults.string(forKey: Keys.height) ?? "175"
        self.weight = userDefaults.string(forKey: Keys.weight) ?? "75"
        self.gender = userDefaults.integer(forKey: Keys.gender)
        self.age = userDefaults.string(forKey: Keys.age) ?? "30"
        self.theme = userDefaults.integer(forKey: Keys.theme)
        self.unitSystem = userDefaults.integer(forKey: Keys.unitSystem)
        self.isMorningNudgeEnabled = userDefaults.object(forKey: Keys.morningNudge) as? Bool ?? true
        self.areMealRemindersEnabled = userDefaults.object(forKey: Keys.mealReminders) as? Bool ?? true
        self.areHapticsEnabled = userDefaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.isSoundEnabled = userDefaults.object(forKey: Keys.sound) as? Bool ?? true
        self.isHealthSyncEnabled = userDefaults.bool(forKey: Keys.healthSync)
        self.isPersonalizedFeedbackEnabled = userDefaults.object(forKey: Keys.personalizedFeedback) as? Bool ?? true
        self.showHealthInsights = userDefaults.bool(forKey: Keys.healthInsights)

        #if canImport(Network)
            self.networkMonitor = NWPathMonitor()
            self.networkMonitor?.pathUpdateHandler = { path in
                let isAvailable = path.status == .satisfied
                Task { @MainActor [weak self] in
                    self?.isNetworkAvailable = isAvailable
                }
            }
            let queue = DispatchQueue(label: "SettingsNetworkMonitor")
            self.networkMonitor?.start(queue: queue)
        #else
            self.networkMonitor = nil
        #endif
    }

    deinit {
        networkMonitor?.cancel()
    }

    // MARK: - HealthKit Sync

    func syncWithHealthKit() {
        Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()

                let weightUnit: HKUnit = self.unitSystem == 0 ? .gramUnit(with: .kilo) : .pound()
                let heightUnit: HKUnit = self.unitSystem == 0 ? .meterUnit(with: .centi) : .inch()

                if let hkWeight = try await HealthKitService.shared.fetchLatestWeight(unit: weightUnit) {
                    self.weight = String(format: "%.1f", hkWeight)
                }

                if let hkHeight = try await HealthKitService.shared.fetchLatestHeight(unit: heightUnit) {
                    self.height = String(format: "%.1f", hkHeight)
                }

                if let hkAge = try HealthKitService.shared.fetchAge() {
                    self.age = String(hkAge)
                }

                if let hkGender = try HealthKitService.shared.fetchGender() {
                    self.gender = hkGender
                }

                print("✅ HealthKit sync successful")
            } catch {
                print("❌ HealthKit sync failed: \(error.localizedDescription)")
                self.isHealthSyncEnabled = false
            }
        }
    }

    // MARK: - Cloud Sync

    func performCloudSync() {
        self.syncTask?.cancel()
        self.syncTask = Task {
            await self.performSyncWithRetry()
        }
    }

    func cancelCloudSync() {
        self.syncTask?.cancel()
        if self.syncStatus == .syncing {
            self.syncStatus = .idle
        }
    }

    private func performSyncWithRetry(attempt: Int = 1) async {
        guard self.isNetworkAvailable else {
            await self.handleSyncError(
                NSError(
                    domain: "SyncError",
                    code: -1009,
                    userInfo: [
                        NSLocalizedDescriptionKey: "No internet connection. Please check your network and try again."
                    ]
                ),
                shouldRetry: false
            )
            return
        }

        self.syncStatus = .syncing

        do {
            try await self.historicalService.syncToFirebase()
            if !Task.isCancelled {
                await self.handleSyncSuccess()
            }
        } catch {
            if !Task.isCancelled {
                let shouldRetry = attempt < self.SYNC_MAX_RETRY_ATTEMPTS
                await self.handleSyncError(error, shouldRetry: shouldRetry, attempt: attempt)
            }
        }
    }

    private func handleSyncSuccess() async {
        self.syncStatus = .success

        #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        try? await Task.sleep(nanoseconds: self.SYNC_SUCCESS_DISPLAY_DURATION)

        if !Task.isCancelled {
            self.syncStatus = .idle
        }
    }

    private func handleSyncError(_ error: Error, shouldRetry: Bool, attempt: Int = 1) async {
        if shouldRetry {
            self.syncStatus = .error("Sync failed. Retrying... (Attempt \(attempt)/\(self.SYNC_MAX_RETRY_ATTEMPTS))")
            try? await Task.sleep(nanoseconds: self.SYNC_RETRY_DELAY)
            if !Task.isCancelled {
                await self.performSyncWithRetry(attempt: attempt + 1)
            }
        } else {
            self.syncStatus = .error(error.localizedDescription)

            #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif

            try? await Task.sleep(nanoseconds: self.SYNC_ERROR_DISPLAY_DURATION)

            if !Task.isCancelled {
                self.syncStatus = .idle
            }
        }
    }

    // MARK: - Notification Handling

    private func handleMorningNudgeChange(_ enabled: Bool) {
        if enabled {
            NotificationManager.shared.scheduleMorningNudge()
        } else {
            NotificationManager.shared.cancelAllNotifications()
        }
    }

    // MARK: - Sync Status Helpers

    var syncStatusText: String {
        switch self.syncStatus {
        case .idle: "Sync with Cloud"
        case .syncing: "Syncing..."
        case .success: "Synced!"
        case .error: "Sync Failed"
        }
    }

    var syncAccessibilityLabel: String {
        switch self.syncStatus {
        case .idle: "Sync with Cloud button"
        case .syncing: "Syncing data to cloud"
        case .success: "Sync completed successfully"
        case let .error(message): "Sync failed: \(message)"
        }
    }

    var syncAccessibilityHint: String {
        switch self.syncStatus {
        case .idle: "Double tap to sync your data with cloud storage"
        case .syncing: "Sync in progress, please wait"
        case .success: "Sync completed"
        case .error: "Double tap to retry sync"
        }
    }
}
