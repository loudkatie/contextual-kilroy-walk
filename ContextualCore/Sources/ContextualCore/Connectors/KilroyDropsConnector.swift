import Foundation

public final class KilroyDropsConnector: Connector {
    public let name = "KilroyDrops"
    public let description = "Physical arrival experiences"

    private let placeId: String
    private let dateProvider: () -> Date

    public init(placeId: String = "frontier_tower", dateProvider: @escaping () -> Date = Date.init) {
        self.placeId = placeId
        self.dateProvider = dateProvider
    }

    public func fetchDrops(for context: Context) async throws -> [Drop] {
        guard context.placeId == nil || context.placeId == placeId else {
            return []
        }

        let drops = kilroyDrops()
        guard let floorBand = context.floorBand else {
            return drops
        }

        return drops.filter { $0.anchor.floorBand == nil || $0.anchor.floorBand == floorBand }
    }

    private func kilroyDrops() -> [Drop] {
        let timestamp = dateProvider()
        let frontDoor = Drop(
            title: "Welcome to Frontier Tower",
            kind: .text,
            payload: .text("Your walkthrough starts on arrival. Pick up your badge and follow the haptics."),
            anchor: .init(placeId: placeId, floorBand: nil),
            permissionScope: "arrival",
            createdAt: timestamp
        )

        let skyLobby = Drop(
            title: "Sky Lobby Orientation",
            kind: .link,
            payload: .text("kilroy://drops/frontier/sky-lobby"),
            anchor: .init(placeId: placeId, floorBand: "SKY-LOBBY"),
            permissionScope: "sky-pass",
            createdAt: timestamp
        )

        let summit = Drop(
            title: "Summit Floor Briefing",
            kind: .pdf,
            payload: .fileURL(URL(string: "https://kilroy.example.com/files/frontier/summit.pdf")!),
            anchor: .init(placeId: placeId, floorBand: "SUMMIT"),
            permissionScope: "summit-clearance",
            createdAt: timestamp
        )

        return [frontDoor, skyLobby, summit]
    }
}
