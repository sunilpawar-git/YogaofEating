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
        // Initialize Firebase
        FirebaseApp.configure()
        print("🔥 Firebase initialized")
        print("📱 Yoga of Eating app starting...")

        // Request permissions and schedule daily nudges on startup
        NotificationManager.shared.requestPermissions()
        NotificationManager.shared.scheduleMorningNudge()
        print("🔔 Notifications configured")
    }

    var body: some Scene {
        WindowGroup {
            MainScreenView()
                .environmentObject(self.viewModel)
                .preferredColorScheme(self.colorScheme)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
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
