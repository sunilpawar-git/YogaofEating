import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: self.$selectedTab) {
            Tab("Highlight", systemImage: "star.fill", value: 0) {
                HighlightView(data: self.viewModel.highlightData)
            }
            Tab("Energise", systemImage: "flame.fill", value: 1) {
                MainScreenView()
            }
            Tab("Reflect", systemImage: "moon.stars.fill", value: 2) {
                ReflectView(data: self.viewModel.reflectData)
            }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(MainViewModel(skipDataLoading: true))
}
