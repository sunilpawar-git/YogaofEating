import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss)
    var dismiss
    @State private var name: String = "Sunil"
    @State private var height: String = "175"
    @State private var weight: String = "75"
    @State private var avatar: String = "Procedural Smiley"
    @State private var theme: Int = 0 // 0: System, 1: Light, 2: Dark
    @State private var isSmartSmileyEnabled: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Cloud Sync") {
                    Button(action: {}, label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Login (Store Details Online)")
                        }
                    })
                }

                Section("Personal Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Name", text: self.$name)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("Height", text: self.$height)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("Weight", text: self.$weight)
                            .keyboardType(.numberPad)
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
                    Picker("Smiley Avatar", selection: self.$avatar) {
                        Text("Procedural Smiley").tag("Procedural Smiley")
                        Text("Minimalist Blob").tag("Minimalist Blob")
                        Text("Geometric Core").tag("Geometric Core")
                    }
                }

                Section("AI & Logic") {
                    Toggle("Smart Smiley (AI Influence)", isOn: self.$isSmartSmileyEnabled)
                }

                Section {
                    Button("FAQ & Help") {
                        // Open help
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        self.dismiss()
                    }
                }
            }
        }
    }
}
