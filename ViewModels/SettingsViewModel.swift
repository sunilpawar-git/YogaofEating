import Combine
import Foundation
import HealthKit
import OSLog

private let settingsLogger = Logger(subsystem: "com.yogaofeating", category: "Settings")
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
        didSet { self.userDefaults.set(self.name, forKey: StorageKeys.userName) }
    }

    @Published var height: String {
        didSet { self.userDefaults.set(self.height, forKey: StorageKeys.userHeight) }
    }

    @Published var weight: String {
        didSet { self.userDefaults.set(self.weight, forKey: StorageKeys.userWeight) }
    }

    @Published var gender: Int {
        didSet { self.userDefaults.set(self.gender, forKey: StorageKeys.userGender) }
    }

    @Published var age: String {
        didSet { self.userDefaults.set(self.age, forKey: StorageKeys.userAge) }
    }

    // MARK: - Appearance Published Properties

    @Published var theme: Int {
        didSet { self.userDefaults.set(self.theme, forKey: StorageKeys.appTheme) }
    }

    @Published var unitSystem: Int {
        didSet { self.userDefaults.set(self.unitSystem, forKey: StorageKeys.unitSystem) }
    }

    // MARK: - Notifications Published Properties

    @Published var isMorningNudgeEnabled: Bool {
        didSet {
            self.userDefaults.set(self.isMorningNudgeEnabled, forKey: StorageKeys.morningNudgeEnabled)
            self.handleMorningNudgeChange(self.isMorningNudgeEnabled)
        }
    }

    @Published var areMealRemindersEnabled: Bool {
        didSet {
            self.userDefaults.set(self.areMealRemindersEnabled, forKey: StorageKeys.mealRemindersEnabled)
            if self.areMealRemindersEnabled {
                NotificationManager.shared.scheduleDefaultMealReminders()
            } else {
                NotificationManager.shared.cancelMealReminders()
            }
        }
    }

    // MARK: - Sensory Published Properties

    @Published var areHapticsEnabled: Bool {
        didSet { self.userDefaults.set(self.areHapticsEnabled, forKey: StorageKeys.hapticsEnabled) }
    }

    @Published var isSoundEnabled: Bool {
        didSet { self.userDefaults.set(self.isSoundEnabled, forKey: StorageKeys.soundEnabled) }
    }

    // MARK: - Integrations & Privacy Published Properties

    @Published var isHealthSyncEnabled: Bool {
        didSet {
            self.userDefaults.set(self.isHealthSyncEnabled, forKey: StorageKeys.healthSyncEnabled)
            if self.isHealthSyncEnabled {
                self.syncWithHealthKit()
            }
        }
    }

    // Note: isPersonalizedFeedbackEnabled removed - feature is always on

    @Published var showHealthInsights: Bool {
        didSet { self.userDefaults.set(self.showHealthInsights, forKey: StorageKeys.showHealthInsights) }
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

    // Keys moved to StorageKeys.swift for centralization

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
        self.name = userDefaults.string(forKey: StorageKeys.userName) ?? "User"
        self.height = userDefaults.string(forKey: StorageKeys.userHeight) ?? "175"
        self.weight = userDefaults.string(forKey: StorageKeys.userWeight) ?? "75"
        self.gender = userDefaults.integer(forKey: StorageKeys.userGender)
        self.age = userDefaults.string(forKey: StorageKeys.userAge) ?? "30"
        self.theme = userDefaults.integer(forKey: StorageKeys.appTheme)
        self.unitSystem = userDefaults.integer(forKey: StorageKeys.unitSystem)
        self.isMorningNudgeEnabled = userDefaults.object(forKey: StorageKeys.morningNudgeEnabled) as? Bool ?? true
        self.areMealRemindersEnabled = userDefaults.object(forKey: StorageKeys.mealRemindersEnabled) as? Bool ?? true
        self.areHapticsEnabled = userDefaults.object(forKey: StorageKeys.hapticsEnabled) as? Bool ?? true
        self.isSoundEnabled = userDefaults.object(forKey: StorageKeys.soundEnabled) as? Bool ?? true
        self.isHealthSyncEnabled = userDefaults.bool(forKey: StorageKeys.healthSyncEnabled)
        // Note: isPersonalizedFeedbackEnabled initialization removed - feature is always on
        self.showHealthInsights = userDefaults.bool(forKey: StorageKeys.showHealthInsights)

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

                settingsLogger.info("HealthKit sync successful")
            } catch {
                settingsLogger.error("HealthKit sync failed: \(error.localizedDescription, privacy: .public)")
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
            NotificationManager.shared.cancelMorningNudge()
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
