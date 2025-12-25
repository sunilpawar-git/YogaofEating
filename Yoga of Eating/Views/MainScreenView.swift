import SwiftUI

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
                                ZStack(alignment: .top) {
                                    // The "Life Line"
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
                                .padding(.horizontal)

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
                    .onTapGesture {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: self.$showingSettings) {
                SettingsView()
            }
        }
    }

    private var smileyAddButton: some View {
        VStack(spacing: 12) {
            SmileyRealityView(state: self.viewModel.smileyState)
                .frame(width: 140, height: 140)
                .onTapGesture {
                    self.viewModel.createNewMeal()
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
