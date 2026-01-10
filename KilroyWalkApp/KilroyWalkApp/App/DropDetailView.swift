import SwiftUI
import ContextualCore

struct DropDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let drop: Drop

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(drop.title)
                    .font(.largeTitle.weight(.semibold))
                detailRow(title: "Type", value: drop.kind.rawValue.capitalized)
                detailRow(title: "Anchor", value: anchorDescription)
                if let scope = drop.permissionScope {
                    detailRow(title: "Permission", value: scope.uppercased())
                }
                payloadSection
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Drop Detail")
    }

    private var anchorDescription: String {
        [drop.anchor.placeId, drop.anchor.floorBand].compactMap { $0 }.joined(separator: " • ")
    }

    @ViewBuilder
    private var payloadSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payload")
                .font(.headline)
            switch drop.payload {
            case .text(let text):
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            case .fileURL(let url):
                Link(destination: url) {
                    Label(url.absoluteString, systemImage: "link")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.like(drop: drop)
            } label: {
                Label("Like", systemImage: viewModel.isLiked(drop: drop) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            .buttonStyle(.borderedProminent)

            Button {
                viewModel.ignore(drop: drop)
            } label: {
                Label("Ignore", systemImage: viewModel.isIgnored(drop: drop) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .buttonStyle(.bordered)
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
