import SwiftUI

@MainActor
struct MainScreenView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var breathingMeals: Set<UUID> = []
    
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // Modern Atmospheric Background
                    backgroundGradient
                        .ignoresSafeArea()
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                // Date Header
                                Text(formattedDate)
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.bold)
                                    .padding(.top, 60)
                                    .padding(.bottom, 40)
                                
                                // Vertical Timeline Context
                                ZStack(alignment: .top) {
                                    // The "Life Line"
                                    Rectangle()
                                        .fill(Color.primary.opacity(0.1))
                                        .frame(width: 2)
                                        .padding(.vertical, 20)
                                    
                                    VStack(spacing: 30) {
                                        ForEach(viewModel.meals) { meal in
                                            JournalBlockView(
                                                meal: meal,
                                                isBreathing: breathingMeals.contains(meal.id),
                                                onUpdate: { newText in
                                                    viewModel.updateMeal(meal.id, description: newText)
                                                }
                                            )
                                            .id(meal.id)
                                        }
                                        
                                        // The Smiley "Add" Button sitting at the bottom of the timeline
                                        smileyAddButton
                                            .padding(.top, 20)
                                            .id("bottom")
                                    }
                                }
                                .padding(.horizontal)
                                
                                Spacer(minLength: 100)
                            }
                        }
                        .onChange(of: viewModel.meals.count) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var smileyAddButton: some View {
        VStack(spacing: 12) {
            SmileyRealityView(state: viewModel.smileyState)
                .frame(width: 140, height: 140)
                .onTapGesture {
                    viewModel.createNewMeal()
                    SensoryService.shared.playNudge(style: .medium)
                }
            
            Text("TAP TO LOG")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .kerning(2)
        }
    }
    
    private var backgroundGradient: some View {
        ZStack {
            Color(UIColor.systemBackground)
            LinearGradient(colors: [
                Color.orange.opacity(0.05),
                Color.purple.opacity(0.05),
                Color.blue.opacity(0.03)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.string(from: Date())
    }
}

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool
    let onUpdate: (String) -> Void
    @State private var text: String
    
    init(meal: Meal, isBreathing: Bool, onUpdate: @escaping (String) -> Void) {
        self.meal = meal
        self.isBreathing = isBreathing
        self.onUpdate = onUpdate
        _text = State(initialValue: meal.description)
    }
    
    var body: some View {
        HStack {
            // Left-aligned block
            VStack(alignment: .leading, spacing: 12) {
                if isBreathing {
                    Text("Breathe...")
                        .font(.system(.subheadline, design: .serif))
                        .italic()
                        .foregroundColor(.secondary)
                } else {
                    TextField("What did you eat?", text: $text, onCommit: {
                        onUpdate(text)
                    })
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .serif))
                }
            }
            .padding(24)
            .frame(maxWidth: 280, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
            }
            
            Spacer()
        }
        .padding(.leading, 30) // Position relative to vertical line
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
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
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Login (Store Details Online)")
                        }
                    }
                }
                
                Section("Personal Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Name", text: $name)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("Height", text: $height)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("Weight", text: $weight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Appearance") {
                    Picker("Theme", selection: $theme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    Picker("Smiley Avatar", selection: $avatar) {
                        Text("Procedural Smiley").tag("Procedural Smiley")
                        Text("Minimalist Blob").tag("Minimalist Blob")
                        Text("Geometric Core").tag("Geometric Core")
                    }
                }
                
                Section("AI & Logic") {
                    Toggle("Smart Smiley (AI Influence)", isOn: $isSmartSmileyEnabled)
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
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MainScreenView()
        .environmentObject(MainViewModel())
}
