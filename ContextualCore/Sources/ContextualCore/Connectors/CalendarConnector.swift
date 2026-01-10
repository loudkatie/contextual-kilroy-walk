import Foundation

public final class CalendarConnector: Connector {
    public let name = "Calendar"
    public let description = "Mock calendar feed"

    private let dateProvider: () -> Date

    public init(dateProvider: @escaping () -> Date = Date.init) {
        self.dateProvider = dateProvider
    }

    public func fetchDrops(for context: Context) async throws -> [Drop] {
        let now = dateProvider()
        let drop = Drop(
            title: "Upcoming walkthrough",
            kind: .text,
            payload: .text("Aru blocked 30 min on your calendar to rehearse the walk."),
            anchor: .init(placeId: context.placeId ?? "frontier_tower", floorBand: context.floorBand),
            permissionScope: nil,
            createdAt: now
        )
        return [drop]
    }
}
