import SwiftUI

@MainActor
struct MainScreenView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingFlowchart = false
    @State private var activeMealType: MealType? = nil
    @State private var mealInputs: [MealType: String] = [:]
    @State private var breathingMeals: Set<MealType> = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Modern Atmospheric Background
                backgroundGradient
                    .ignoresSafeArea()
                
                // Flowchart Layer (Wired behind Smiley)
                if showingFlowchart {
                    let smileyCenter = CGPoint(x: geo.size.width - 120, y: geo.size.height - 120)
                    
                    ZStack {
                        ForEach(MealType.allCases, id: \.self) { type in
                            let pos = balloonPosition(for: type, in: geo.size)
                            
                            // Wire from Smiley to Balloon (Behind Smiley)
                            // We tie it to the EDGE of the balloon (approx radius 60)
                            let anchorPoint = calculateEdgePoint(from: smileyCenter, to: pos, radius: 60)
                            FlowchartWireView(startPoint: smileyCenter, endPoint: anchorPoint)
                            
                            // Glass Balloon with Inline Input
                            MealBalloonView(
                                type: type,
                                position: pos,
                                input: binding(for: type),
                                isActive: activeMealType == type,
                                isBreathing: breathingMeals.contains(type),
                                existingMeal: viewModel.mealDescription(for: type)
                            ) {
                                startMindfulInput(for: type)
                            } onCommit: {
                                commitMeal(type)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottomTrailing)))
                }
                
                // 3D Smiley in lower bottom corner (Larger coin size)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        SmileyRealityView(state: viewModel.smileyState)
                            .frame(width: 180, height: 180)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showingFlowchart.toggle()
                                    if !showingFlowchart { activeMealType = nil }
                                }
                            }
                            .padding(.bottom, 30)
                            .padding(.trailing, 30)
                    }
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        ZStack {
            Color(UIColor.systemBackground)
            LinearGradient(colors: [
                Color.orange.opacity(0.1),
                Color.purple.opacity(0.1),
                Color.blue.opacity(0.05)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            // Subtle abstract blurs for "premium" feel
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 200, y: 100)
        }
    }
    
    private func calculateEdgePoint(from: CGPoint, to: CGPoint, radius: CGFloat) -> CGPoint {
        let dx = from.x - to.x
        let dy = from.y - to.y
        let len = sqrt(dx*dx + dy*dy)
        if len == 0 { return to }
        return CGPoint(
            x: to.x + (dx/len) * radius,
            y: to.y + (dy/len) * radius
        )
    }
    
    private func balloonPosition(for type: MealType, in size: CGSize) -> CGPoint {
        switch type {
        case .breakfast: return CGPoint(x: size.width * 0.35, y: size.height * 0.22)
        case .lunch: return CGPoint(x: size.width * 0.25, y: size.height * 0.48)
        case .dinner: return CGPoint(x: size.width * 0.4, y: size.height * 0.76)
        }
    }
    
    private func binding(for type: MealType) -> Binding<String> {
        Binding(
            get: { mealInputs[type] ?? "" },
            set: { mealInputs[type] = $0 }
        )
    }
    
    private func startMindfulInput(for type: MealType) {
        activeMealType = type
        breathingMeals.insert(type)
        SensoryService.shared.playNudge(style: .light)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                _ = breathingMeals.remove(type)
            }
        }
    }
    
    private func commitMeal(_ type: MealType) {
        let text = mealInputs[type] ?? ""
        if !text.isEmpty {
            viewModel.addMeal(description: text, type: type)
            withAnimation {
                activeMealType = nil
            }
        }
    }
}

struct MealBalloonView: View {
    let type: MealType
    let position: CGPoint
    @Binding var input: String
    let isActive: Bool
    let isBreathing: Bool
    let existingMeal: String
    let onSelect: () -> Void
    let onCommit: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                if isActive {
                    if isBreathing {
                        Text("Breathe...")
                            .font(.system(.subheadline, design: .serif))
                            .italic()
                            .foregroundColor(.secondary)
                    } else {
                        TextField("What's for \(type.rawValue)?", text: $input, onCommit: onCommit)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.system(.headline, design: .rounded))
                            .fixedSize()
                            .onSubmit(onCommit)
                    }
                } else {
                    Button(action: onSelect) {
                        VStack(spacing: 6) {
                            Text(type.rawValue.uppercased())
                                .kerning(2)
                                .font(.system(.caption, design: .default))
                                .fontWeight(.black)
                                .foregroundColor(Color.primary.opacity(0.6))
                            
                            if !existingMeal.isEmpty {
                                Text(existingMeal)
                                    .font(.system(.body, design: .serif))
                                    .italic()
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.secondary.opacity(0.3))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(28)
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
                    .overlay(Circle().stroke(isActive ? Color.primary.opacity(0.2) : Color.white.opacity(0.4), lineWidth: 1))
            }
            .scaleEffect(isActive ? 1.25 : 1.0)
            .animation(.spring(response: 0.45, dampingFraction: 0.65), value: isActive)
            .position(position)
        }
    }
}

#Preview {
    MainScreenView()
        .environmentObject(MainViewModel())
}
