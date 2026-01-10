import SwiftUI
import ContextualCore

struct DemoLogListView: View {
    let entries: [DemoLogEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entries) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(color(for: entry.category))
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.message)
                            .font(.subheadline)
                        Text(entry.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Divider()
            }
        }
    }

    private func color(for category: DemoLogEvent.Category) -> Color {
        switch category {
        case .info:
            return .blue
        case .action:
            return .green
        case .error:
            return .red
        }
    }
}
