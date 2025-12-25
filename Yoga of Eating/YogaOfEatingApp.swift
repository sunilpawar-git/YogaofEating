import SwiftUI

@MainActor
@main
struct YogaOfEatingApp: App {
    // Shared state across the app
    @StateObject private var viewModel = MainViewModel()
    private let notificationManager = NotificationManager()

    init() {
        // Request permissions and schedule daily nudges on startup
        self.notificationManager.requestPermissions()
        self.notificationManager.scheduleMorningNudge()
    }

    var body: some Scene {
        WindowGroup {
            MainScreenView()
                .environmentObject(self.viewModel)
        }
    }
}
