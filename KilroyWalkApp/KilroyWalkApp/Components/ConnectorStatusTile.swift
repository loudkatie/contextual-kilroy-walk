import SwiftUI

struct ConnectorStatusTile: View {
    let status: AppViewModel.ConnectorStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: status.state.iconName)
                    .foregroundStyle(status.state.tint)
                Text(status.name)
                    .font(.headline)
            }
            Text(status.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let lastSynced = status.lastSynced {
                Text("Updated \(lastSynced, style: .relative)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
