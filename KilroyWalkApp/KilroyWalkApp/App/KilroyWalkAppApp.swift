import SwiftUI
import ContextualCore

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
