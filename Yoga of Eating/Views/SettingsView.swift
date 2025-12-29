import FirebaseAuth
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss)
    var dismiss
    @EnvironmentObject var viewModel: MainViewModel

    @AppStorage("user_name")
    private var name: String = "Sunil"
    @AppStorage("user_height")
    private var height: String = "175"
    @AppStorage("user_weight")
    private var weight: String = "75"
    @AppStorage("user_gender")
    private var gender: Int = 0 // 0: Unspecified, 1: Male, 2: Female, 3: Other
    @AppStorage("user_age")
    private var age: String = "30"
    @AppStorage("app_theme")
    private var theme: Int = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("unit_system")
    private var unitSystem: Int = 0 // 0: Metric, 1: Imperial
    @AppStorage("smart_smiley_enabled")
    private var isSmartSmileyEnabled: Bool = true

    // Notifications
    @AppStorage("morning_nudge_enabled")
    private var isMorningNudgeEnabled: Bool = true
    @AppStorage("meal_reminders_enabled")
    private var areMealRemindersEnabled: Bool = true

    // Sensory
    @AppStorage("haptics_enabled")
    private var areHapticsEnabled: Bool = true
    @AppStorage("sound_enabled")
    private var isSoundEnabled: Bool = true

    // Integrations
    @AppStorage("health_sync_enabled")
    private var isHealthSyncEnabled: Bool = false

    @StateObject private var authService = AuthService.shared
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Cloud Sync") {
                    if let user = authService.currentUser {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.displayName ?? "User")
                                    .font(.headline)
                                Text(user.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Sign Out") {
                                self.authService.signOut()
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Button(action: {
                            Task {
                                try? await self.authService.signInWithGoogle()
                            }
                        }, label: {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Login with Google")
                            }
                        })
                    }
                }

                Section("Personal Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Name", text: self.$name)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }

                    Picker("Gender", selection: self.$gender) {
                        Text("Unspecified").tag(0)
                        Text("Male").tag(1)
                        Text("Female").tag(2)
                        Text("Other").tag(3)
                    }

                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Age", text: self.$age)
                        #if canImport(UIKit)
                            .keyboardType(.numberPad)
                        #endif
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }

                    Picker("Unit System", selection: self.$unitSystem) {
                        Text("Metric").tag(0)
                        Text("Imperial").tag(1)
                    }

                    HStack {
                        Text(self.unitSystem == 0 ? "Height (cm)" : "Height (ft/in)")
                        Spacer()
                        TextField("Height", text: self.$height)
                        #if canImport(UIKit)
                            .keyboardType(.numbersAndPunctuation)
                        #endif
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(self.unitSystem == 0 ? "Weight (kg)" : "Weight (lbs)")
                        Spacer()
                        TextField("Weight", text: self.$weight)
                        #if canImport(UIKit)
                            .keyboardType(.decimalPad)
                        #endif
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: self.$theme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                }

                Section("Notifications") {
                    Toggle("Morning Nudge", isOn: self.$isMorningNudgeEnabled)
                        .onChange(of: self.isMorningNudgeEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.scheduleMorningNudge()
                            } else {
                                // For simplicity, we don't selectively clear,
                                // but in a real app we'd remove specific identifiers.
                                NotificationManager.shared.cancelAllNotifications()
                                if self.areMealRemindersEnabled {
                                    // Reschedule other enabled notifications
                                }
                            }
                        }
                    Toggle("Meal Reminders", isOn: self.$areMealRemindersEnabled)
                }

                Section("Sensory Feedback") {
                    Toggle("Haptic Nudges", isOn: self.$areHapticsEnabled)
                    Toggle("Sound Effects", isOn: self.$isSoundEnabled)
                }

                Section("Integrations") {
                    Toggle("Apple Health (HealthKit)", isOn: self.$isHealthSyncEnabled)
                }

                Section("AI & Logic") {
                    Toggle("Smart Smiley (AI Influence)", isOn: self.$isSmartSmileyEnabled)
                }

                Section("Data Management") {
                    Button(role: .destructive) { self.showingClearConfirmation = true } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                }

                Section {
                    NavigationLink("FAQ & Help") { FAQView() }
                    Link(destination: self.privacyURL) { Label("Privacy Policy", systemImage: "lock.shield") }
                    Link(destination: self.termsURL) { Label("Terms of Service", systemImage: "doc.text") }
                    Button { /* Rate app */ } label: { Label("Rate Yoga of Eating", systemImage: "star") }
                } header: { Text("Support & Legal") } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yoga of Eating v\(self.appVersion) (\(self.appBuild))")
                        Text("© 2025 Sunil")
                    }.padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    #if canImport(UIKit)
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { self.dismiss() }
                        }
                    #elseif canImport(AppKit)
                        ToolbarItem(placement: .automatic) {
                            Button("Done") { self.dismiss() }
                        }
                    #endif
                }
                .alert("Clear All Data?", isPresented: self.$showingClearConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) { self.viewModel.resetDay() }
                } message: {
                    Text("This will delete all your logged meals and reset the Smiley. Cannot be undone.")
                }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var faqURL: URL {
        URL(string: "https://example.com/faq") ?? URL(fileURLWithPath: "")
    }

    private var privacyURL: URL {
        URL(string: "https://example.com/privacy") ?? URL(fileURLWithPath: "")
    }

    private var termsURL: URL {
        URL(string: "https://example.com/terms") ?? URL(fileURLWithPath: "")
    }
}
