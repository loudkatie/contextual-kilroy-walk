import Foundation

public struct DemoVenue: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let zone: ContextualZone
    public let moments: [Moment]
    public let notes: String?

    public init(
        id: String,
        name: String,
        zone: ContextualZone,
        moments: [Moment],
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.zone = zone
        self.moments = moments
        self.notes = notes
    }
}
