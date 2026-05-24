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

    /// User-configured time for the morning briefing notification.
    /// Stored as a `TimeInterval` in UserDefaults. Hour and minute components are used;
    /// the date portion is ignored when scheduling.
    @Published var morningBriefingTime: Date {
        didSet {
            self.userDefaults.set(
                self.morningBriefingTime.timeIntervalSinceReferenceDate,
                forKey: StorageKeys.morningBriefingTime
            )
            // Guard: do not schedule during init (isFullyInitialized = false).
            // Post-init: reschedule only if the nudge is enabled.
            guard self.isFullyInitialized, self.isMorningNudgeEnabled else { return }
            self.notificationScheduler.scheduleMorningNudge(at: self.morningBriefingTime)
        }
    }

    @Published var areMealRemindersEnabled: Bool {
        didSet {
            self.userDefaults.set(self.areMealRemindersEnabled, forKey: StorageKeys.mealRemindersEnabled)
            if self.areMealRemindersEnabled {
                self.notificationScheduler.scheduleDefaultMealReminders()
            } else {
                self.notificationScheduler.cancelMealReminders()
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

    // MARK: - Cloud Restore Published Properties

    @Published var restoreStatus: RestoreStatus = .idle

    // MARK: - Auth Published Properties

    /// Non-nil when a sign-in attempt fails. Cleared on successful sign-in.
    /// Surfaces errors from `signInWithGoogle()` to the UI without exposing internal details.
    @Published var authError: String?

    // MARK: - Internal Properties (accessible to SettingsViewModel+Sync.swift extension)

    let userDefaults: UserDefaults
    let historicalService: any HistoricalDataServiceProtocol
    let authService: any AuthServiceProtocol
    let notificationScheduler: any NotificationScheduling
    let healthKitProvider: any HealthKitBodyMetricsProviding
    var syncTask: Task<Void, Never>?
    var restoreTask: Task<Void, Never>?
    let networkMonitor: NWPathMonitor?
    var isNetworkAvailable = true

    // MARK: - Constants

    // Keys moved to StorageKeys.swift for centralization

    let syncSuccessDisplayDuration = TimingConstants.syncSuccessDisplayNanoseconds
    let syncErrorDisplayDuration = TimingConstants.syncErrorDisplayNanoseconds

    /// Prevents property observers from triggering notification-scheduling side effects
    /// during two-phase initialization. Set to `true` at the end of `init`.
    private var isFullyInitialized = false

    // MARK: - Sync Status Enum

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
    }

    // MARK: - Restore Status Enum

    enum RestoreStatus: Equatable {
        case idle
        case restoring
        case success
        case error(String)
    }

    // MARK: - Initialization

    init(
        historicalService: any HistoricalDataServiceProtocol,
        authService: (any AuthServiceProtocol)? = nil,
        userDefaults: UserDefaults = .standard,
        notificationScheduler: any NotificationScheduling = NotificationManager.shared,
        healthKitProvider: any HealthKitBodyMetricsProviding = HealthKitService.shared
    ) {
        self.userDefaults = userDefaults
        self.historicalService = historicalService
        self.authService = authService ?? AuthService.shared
        self.notificationScheduler = notificationScheduler
        self.healthKitProvider = healthKitProvider

        // Load initial values from UserDefaults
        self.name = userDefaults.string(forKey: StorageKeys.userName) ?? "User"
        self.height = userDefaults.string(forKey: StorageKeys.userHeight) ?? "175"
        self.weight = userDefaults.string(forKey: StorageKeys.userWeight) ?? "75"
        self.gender = userDefaults.integer(forKey: StorageKeys.userGender)
        self.age = userDefaults.string(forKey: StorageKeys.userAge) ?? "30"
        self.theme = userDefaults.integer(forKey: StorageKeys.appTheme)
        self.unitSystem = userDefaults.integer(forKey: StorageKeys.unitSystem)
        // morningBriefingTime must be set BEFORE isMorningNudgeEnabled so that
        // handleMorningNudgeChange (triggered by isMorningNudgeEnabled.didSet) can
        // safely reference self.morningBriefingTime.
        let storedInterval = userDefaults.object(forKey: StorageKeys.morningBriefingTime) as? Double
        if let interval = storedInterval {
            self.morningBriefingTime = Date(timeIntervalSinceReferenceDate: interval)
        } else {
            var defaultComponents = DateComponents()
            defaultComponents.hour = 8
            defaultComponents.minute = 0
            self.morningBriefingTime = Calendar.current.date(from: defaultComponents) ?? Date()
        }
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
                // Untracked @MainActor hop: one-shot property update, no result or cancellation needed.
                Task { @MainActor [weak self] in
                    self?.isNetworkAvailable = isAvailable
                }
            }
            let queue = DispatchQueue(label: "SettingsNetworkMonitor")
            self.networkMonitor?.start(queue: queue)
        #else
            self.networkMonitor = nil
        #endif
        self.isFullyInitialized = true
    }

    deinit {
        networkMonitor?.cancel()
    }

    // MARK: - Notification Handling

    func handleMorningNudgeChange(_ enabled: Bool) {
        if enabled {
            self.notificationScheduler.scheduleMorningNudge(at: self.morningBriefingTime)
        } else {
            self.notificationScheduler.cancelMorningNudge()
        }
    }
}
