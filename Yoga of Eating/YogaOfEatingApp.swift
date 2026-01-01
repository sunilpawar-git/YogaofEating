import FirebaseCore
import GoogleSignIn
import SwiftUI

@MainActor
@main
struct YogaOfEatingApp: App {
    // Shared state across the app
    @StateObject private var viewModel = MainViewModel()

    @AppStorage("app_theme")
    private var theme: Int = 0 // 0: System, 1: Light, 2: Dark

    init() {
        // Skip all initialization if running unit tests to prevent malloc errors
        guard NSClassFromString("XCTestCase") == nil else {
            print("🧪 Unit testing mode - skipping Firebase and notification setup")
            return
        }

        // Initialize Firebase
        FirebaseApp.configure()
        print("🔥 Firebase initialized")
        print("📱 Yoga of Eating app starting...")

        // Check if running UI tests and reset data if needed
        if CommandLine.arguments.contains("--uitesting") {
            print("🧪 UI Testing mode - clearing all data")

            // Clear UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
                UserDefaults.standard.synchronize()
            }

            // Clear persisted JSON data file
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let dataFileURL = documentsURL.appendingPathComponent("yoga_of_eating_data.json")
                try? FileManager.default.removeItem(at: dataFileURL)
                print("🧪 Removed persisted data file")
            }
        }

        // Request permissions and schedule daily nudges on startup
        NotificationManager.shared.requestPermissions()
        NotificationManager.shared.scheduleMorningNudge()
        print("🔔 Notifications configured")
    }

    var body: some Scene {
        WindowGroup {
            if NSClassFromString("XCTestCase") != nil {
                // Show placeholder during unit tests to avoid SwiftUI issues
                Text("Unit Testing...")
            } else {
                MainScreenView()
                    .environmentObject(self.viewModel)
                    .preferredColorScheme(self.colorScheme)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
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
