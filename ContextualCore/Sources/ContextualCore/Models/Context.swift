import Foundation

public struct Context: Codable, Hashable {
    public var placeId: String?
    public var latitude: Double?
    public var longitude: Double?
    public var floorBand: String?
    public var timestamp: Date

    public init(
        placeId: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        floorBand: String? = nil,
        timestamp: Date = Date()
    ) {
        self.placeId = placeId
        self.latitude = latitude
        self.longitude = longitude
        self.floorBand = floorBand
        self.timestamp = timestamp
    }
}
