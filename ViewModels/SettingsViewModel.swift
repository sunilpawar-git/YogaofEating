import Combine
import Foundation
import HealthKit
#if canImport(UIKit)
    import UIKit
#endif
#if canImport(Network)
    import Network
#endif

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
        didSet { self.userDefaults.set(self.areMealRemindersEnabled, forKey: StorageKeys.mealRemindersEnabled) }
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

    @Published var showHealthInsights: Bool {
        didSet { self.userDefaults.set(self.showHealthInsights, forKey: StorageKeys.showHealthInsights) }
    }

    @Published var isMindfulWriteEnabled: Bool {
        didSet {
            self.userDefaults.set(
                self.isMindfulWriteEnabled,
                forKey: StorageKeys.healthKitMindfulWriteEnabled
            )
        }
    }

    @Published var isRadialHomeEnabled: Bool {
        didSet {
            self.userDefaults.set(
                self.isRadialHomeEnabled,
                forKey: StorageKeys.useRadialHome
            )
        }
    }

    // MARK: - Cloud Sync Published Properties

    @Published var syncStatus: SyncStatus = .idle

    // MARK: - Properties

    private let userDefaults: UserDefaults
    let historicalService: any HistoricalDataServiceProtocol
    var syncTask: Task<Void, Never>?
    private let networkMonitor: NWPathMonitor?
    var isNetworkAvailable = true

    // MARK: - Constants

    let SYNC_SUCCESS_DISPLAY_DURATION: UInt64 = 2_000_000_000
    let SYNC_ERROR_DISPLAY_DURATION: UInt64 = 3_000_000_000
    let SYNC_MAX_RETRY_ATTEMPTS = 3
    let SYNC_RETRY_DELAY: UInt64 = 1_000_000_000

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
        self.showHealthInsights = userDefaults.bool(forKey: StorageKeys.showHealthInsights)
        self.isMindfulWriteEnabled = userDefaults.bool(forKey: StorageKeys.healthKitMindfulWriteEnabled)
        self.isRadialHomeEnabled = userDefaults.bool(forKey: StorageKeys.useRadialHome)

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
}
