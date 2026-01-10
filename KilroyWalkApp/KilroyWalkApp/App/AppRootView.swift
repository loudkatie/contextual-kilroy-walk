import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                DemoControlsView()
            }
            .tabItem {
                Label("Demo", systemImage: "switch.2")
            }

            NavigationStack {
                DropsView()
            }
            .tabItem {
                Label("Drops", systemImage: "list.bullet.rectangle")
            }
        }
        .task {
            await viewModel.bootstrap()
        }
    }
}
