import SwiftUI
#if canImport(AppKit)
    import AppKit
#endif

@MainActor
struct MainScreenView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var breathingMeals: Set<UUID> = []

    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                ZStack {
                    // Modern Atmospheric Background
                    self.backgroundGradient
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        ScrollViewReader { proxy in
                            VStack(spacing: 0) {
                                // Date Header
                                Text(self.formattedDate)
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.bold)
                                    .padding(.top, 60)
                                    .padding(.bottom, 40)

                                // Vertical Timeline Context
                                ZStack(alignment: .center) {
                                    // The "Life Line" - centered
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.primary.opacity(0.1), .primary.opacity(0.05)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 2)
                                        .padding(.top, 20)
                                        .frame(maxHeight: .infinity)

                                    VStack(spacing: 30) {
                                        ForEach(self.viewModel.meals) { meal in
                                            JournalBlockView(
                                                meal: meal,
                                                isBreathing: self.breathingMeals.contains(meal.id),
                                                onUpdate: { mealType, newItems in
                                                    self.viewModel.updateMeal(
                                                        meal.id,
                                                        mealType: mealType,
                                                        items: newItems
                                                    )
                                                },
                                                onDelete: {
                                                    withAnimation(.spring()) {
                                                        self.viewModel.deleteMeal(meal.id)
                                                    }
                                                }
                                            )
                                            .id(meal.id)
                                        }

                                        // The Smiley "Add" Button sitting at the bottom of the timeline
                                        self.smileyAddButton
                                            .padding(.top, 20)
                                            .id("bottom")
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                Spacer(minLength: 100)
                            }
                            .onChange(of: self.viewModel.meals.count) { _, _ in
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    #if canImport(UIKit)
                        .onTapGesture {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        }
                    #endif
                }
            }
            .toolbar {
                #if canImport(UIKit)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            self.showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .accessibilityIdentifier("settings-button")
                    }

                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            // Dismiss keyboard by resigning first responder
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("keyboard-done-button")
                    }
                #elseif canImport(AppKit)
                    ToolbarItem(placement: .automatic) {
                        Button {
                            self.showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .accessibilityIdentifier("settings-button")
                    }
                #endif
            }
            .sheet(isPresented: self.$showingSettings) {
                SettingsView()
            }
        }
    }

    private var smileyAddButton: some View {
        Button(action: {
            self.viewModel.createNewMeal()
            SensoryService.shared.playNudge(style: .medium)
        }) {
            VStack(spacing: 16) {
                SmileyView(state: self.viewModel.smileyState)
                    .frame(width: 120, height: 120)

                Text("TAP TO LOG")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .kerning(2)
            }
            .frame(minHeight: 160)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add-meal-button")
        .accessibilityLabel("Add Meal")
    }

    private var backgroundGradient: some View {
        ZStack {
            #if canImport(AppKit)
                Color(NSColor.controlBackgroundColor)
            #else
                Color(uiColor: .systemBackground)
            #endif
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.05),
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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

#Preview {
    MainScreenView()
        .environmentObject(MainViewModel())
}
