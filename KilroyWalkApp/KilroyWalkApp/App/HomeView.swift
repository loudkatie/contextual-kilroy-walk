import SwiftUI
import ContextualCore

struct HomeView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                agentCard
                memoryCard
                connectorSection
                demoLogSection
            }
            .padding()
        }
        .navigationTitle("Kilroy Walk")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.triggerFloorEvent() }
                } label: {
                    Label("Sync", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private var agentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Agent ID")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(viewModel.agent.identity.uuid.uuidString)
                .font(.footnote)
                .monospaced()
            Text("Born \(viewModel.agent.bornAt, style: .date) at \(viewModel.agent.bornAt, style: .time)")
                .font(.headline)
            Divider()
            HStack {
                Image(systemName: "waveform.and.magnifyingglass")
                    .foregroundStyle(.secondary)
                Text("Audio Route: \(viewModel.audioRouteDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Memory Summary")
                .font(.headline)
            Text(viewModel.agent.memoryStore.summaryDescription())
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var connectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connector Status")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.connectorStatusList()) { status in
                    ConnectorStatusTile(status: status)
                }
            }
        }
    }

    private var demoLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Demo Log")
                .font(.headline)
            DemoLogListView(entries: viewModel.demoLog.recentEntries())
        }
    }
}
