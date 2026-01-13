import SwiftUI
import ContextualCore

struct HostPresenceView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showToolsSheet = false

    private var hasMoment: Bool {
        viewModel.activeMoment != nil
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.blue.opacity(0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                header
                Spacer(minLength: 20)
                bubbleStack
                Spacer(minLength: 20)
                statusFooter
            }
            .padding()
        }
        .sheet(isPresented: $showToolsSheet) {
            HostToolsSheet()
                .environmentObject(viewModel)
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Text("CONTEXTUAL")
                .font(.subheadline.weight(.semibold))
                .kerning(6)
                .foregroundStyle(.secondary)
                .opacity(0.8)
            Spacer()
            Button {
                showToolsSheet = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.semibold))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Demo controls and log")
        }
    }

    private var bubbleStack: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height) * 0.9
            ZStack(alignment: .bottom) {
                PresenceBubbleView(isAwaitingConsent: viewModel.consentState == .awaiting)
                    .frame(width: size, height: size)

                if let moment = viewModel.activeMoment {
                    MomentHostCard(
                        moment: moment,
                        actionHandler: { action in
                            viewModel.handleAction(action, for: moment)
                        }
                    )
                    .padding(.bottom, 24)
                } else {
                    Text("Listening for meaningful places…")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private var statusFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Audio route: \(viewModel.audioRouteDescription)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(viewModel.momentDiagnostics)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PresenceBubbleView: View {
    var isAwaitingConsent: Bool
    @State private var animate = false

    var body: some View {
        let duration = isAwaitingConsent ? 1.3 : 2.4
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.blue.opacity(0.4),
                            Color.indigo.opacity(0.8)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .blur(radius: 2)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .scaleEffect(animate ? 1.08 : 0.94)
                .blur(radius: 1)
        }
        .scaleEffect(animate ? 1.02 : 0.98)
        .shadow(color: .black.opacity(0.4), radius: 20)
        .onAppear {
            animate = true
        }
        .animation(
            .easeInOut(duration: duration).repeatForever(autoreverses: true),
            value: animate
        )
        .animation(
            .easeInOut(duration: duration).repeatForever(autoreverses: true),
            value: isAwaitingConsent
        )
    }
}

private struct MomentHostCard: View {
    let moment: Moment
    let actionHandler: (MomentAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(moment.title)
                .font(.headline)
            Text(moment.hostLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let detail = moment.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 8) {
                ForEach(moment.actions) { action in
                    actionButton(for: action)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func actionButton(for action: MomentAction) -> some View {
        switch action.style {
        case .primary:
            baseButton(for: action)
                .buttonStyle(.borderedProminent)
        case .secondary:
            baseButton(for: action)
                .buttonStyle(.bordered)
        case .subtle:
            baseButton(for: action)
                .buttonStyle(.borderless)
        }
    }

    private func baseButton(for action: MomentAction) -> some View {
        Button {
            actionHandler(action)
        } label: {
            HStack {
                if let icon = action.iconName {
                    Image(systemName: icon)
                }
                Text(action.title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct HostToolsSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        TabView {
            NavigationStack {
                DemoControlsView()
            }
            .tabItem {
                Label("Controls", systemImage: "switch.2")
            }

            NavigationStack {
                ScrollView {
                    DemoLogListView(entries: viewModel.demoLog.recentEntries())
                        .padding()
                }
                .navigationTitle("Demo Log")
            }
            .tabItem {
                Label("Demo Log", systemImage: "list.bullet.rectangle")
            }
        }
    }
}
