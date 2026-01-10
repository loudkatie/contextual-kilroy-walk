import SwiftUI
import ContextualCore

struct DropsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        List {
            if viewModel.drops.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "tray")
                    Text("No drops yet")
                        .font(.headline)
                    Text("Trigger arrival or floor events to fetch contextual drops.")
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                ForEach(viewModel.drops) { drop in
                    NavigationLink(value: drop) {
                        dropRow(drop)
                    }
                }
            }
        }
        .navigationDestination(for: Drop.self) { drop in
            DropDetailView(drop: drop)
        }
        .navigationTitle("Drops")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.triggerFloorEvent() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private func dropRow(_ drop: Drop) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(drop.title)
                    .font(.headline)
                Text(drop.anchor.floorBand ?? drop.anchor.placeId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if viewModel.isLiked(drop: drop) {
                Image(systemName: "hand.thumbsup.fill").foregroundStyle(.green)
            } else if viewModel.isIgnored(drop: drop) {
                Image(systemName: "hand.thumbsdown.fill").foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 6)
    }
}
