import SwiftUI
import ContextualCore

@MainActor
@main
struct KilroyWalkAppApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(viewModel)
        }
    }
}
