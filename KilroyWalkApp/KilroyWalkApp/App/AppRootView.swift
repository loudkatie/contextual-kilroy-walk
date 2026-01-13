import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        TabView {
            NavigationStack {
                HostPresenceView()
            }
            .tabItem {
                Label("Presence", systemImage: "sparkles")
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
