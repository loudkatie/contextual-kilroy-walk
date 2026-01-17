import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContextualPresenceScreen()
                .opacity(showSplash ? 0.0 : 1.0)

            if showSplash {
                ContextualSplashView {
                    withAnimation(.easeOut(duration: 0.8)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            }
        }
        .task {
            await viewModel.bootstrap()
        }
    }
}
