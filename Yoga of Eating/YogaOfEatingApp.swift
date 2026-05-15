import FirebaseCore
import GoogleSignIn
import OSLog
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

private let appLogger = Logger(subsystem: "com.yogaofeating", category: "App")

// MARK: - Console Output Filters (For Development)

// NOTE: The following warnings are benign UIKit system noise and do NOT affect app functionality:
// - "The variant selector cell index number could not be found" — UIKit keyboard autocorrect/predictive text
// - "Could not find cached accumulator for token=..." — Autocorrect state management
// - "Attempted to update accumulator after completion..." — Text input event synchronization
// These are filtered by the build scheme's OS_ACTIVITY_DT_MODE setting to reduce console clutter.

@MainActor
@main
struct YogaOfEatingApp: App {
    #if canImport(UIKit)
        // Connect App Delegate
        @UIApplicationDelegateAdaptor(AppDelegate.self)
        var delegate: AppDelegate
    #endif

    // Shared state across the app
    @StateObject private var viewModel = MainViewModel(authService: AuthService.shared)
    @Environment(\.scenePhase)
    private var scenePhase

    @AppStorage("app_theme")
    private var theme: Int = 0 // 0: System, 1: Light, 2: Dark

    init() {
        // Skip all initialization if running unit tests to prevent malloc errors
        guard NSClassFromString("XCTestCase") == nil else {
            appLogger.debug("Unit testing mode — skipping Firebase and notification setup")
            return
        }

        appLogger.info("Yoga of Eating app starting")

        // Configure Firebase here in App.init() — this is earlier than AppDelegate.didFinishLaunchingWithOptions
        // and guarantees Firebase is ready before any @StateObject or service singleton accesses it.
        let isCIForFirebase = ProcessInfo.processInfo.environment["CI"] == "true"
        if !isCIForFirebase, FirebaseApp.app() == nil {
            FirebaseApp.configure()
            appLogger.info("Firebase initialized (App.init)")
        }

        // Check if running UI tests and reset data if needed
        if CommandLine.arguments.contains("--uitesting") {
            appLogger.debug("UI Testing mode — clearing all data")

            // Clear UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
                UserDefaults.standard.synchronize()
            }

            // Clear persisted JSON data file
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let dataFileURL = documentsURL.appendingPathComponent("yoga_of_eating_data.json")
                do {
                    try FileManager.default.removeItem(at: dataFileURL)
                    appLogger.debug("Removed persisted data file for UI test run")
                } catch {
                    appLogger
                        .error("Failed to remove persisted data file: \(error.localizedDescription, privacy: .public)")
                }
            }
        }

        // Request permissions and schedule daily nudges on startup.
        // Skipped in CI environments to prevent permission popups causing test flakiness.
        let isCIEnvironment = ProcessInfo.processInfo.environment["CI"] == "true"
        if !isCIEnvironment {
            NotificationManager.shared.requestPermissions()
            NotificationManager.shared.scheduleMorningNudge()
            NotificationManager.shared.scheduleDefaultMealReminders()
            appLogger.info("Notifications configured")
        }
    }

    var body: some Scene {
        WindowGroup {
            if NSClassFromString("XCTestCase") != nil {
                // Show placeholder during unit tests to avoid SwiftUI issues
                Text("Unit Testing...")
            } else {
                RootTabView()
                    .environmentObject(self.viewModel)
                    .preferredColorScheme(self.colorScheme)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            }
        }
        .onChange(of: self.scenePhase) { _, newPhase in
            if newPhase == .active {
                self.viewModel.refreshActivityDataIfNeeded()
            }
        }
    }

    private var colorScheme: ColorScheme? {
        switch self.theme {
        case 1:
            .light
        case 2:
            .dark
        default:
            nil
        }
    }
}

#if canImport(UIKit)
    /// Main App Delegate to handle lifecycle events and library initialization.
    /// Fixes "App Delegate does not conform to UIApplicationDelegate" warnings and ensures
    /// proper GIDSignIn swizzling and callback handling.
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(
            _: UIApplication,
            didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
        ) -> Bool {
            // Skip initialization in test/CI environments
            let isTestEnvironment = NSClassFromString("XCTestCase") != nil
            let isCIEnvironment = ProcessInfo.processInfo.environment["CI"] == "true"

            if !isTestEnvironment, !isCIEnvironment {
                // Firebase is configured in YogaOfEatingApp.init() before this runs.
                // The guard here is a safety net in case of unexpected execution order.
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                    appLogger.info("Firebase initialized (AppDelegate fallback)")
                }

                // Initialize AuthService
                _ = AuthService.shared
                appLogger.info("AuthService initialized (AppDelegate)")
            } else {
                appLogger.debug("Skipping Firebase and AuthService initialization in test/CI environment")
            }

            return true
        }

        // Note: URL handling for Google Sign-In is done via SwiftUI's onOpenURL modifier
        // in WindowGroup, which uses the modern UIScene lifecycle approach.
    }
#endif
