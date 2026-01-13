import Foundation

public struct ContextualZone: Identifiable, Hashable, Codable {
    public struct Coordinate: Hashable, Codable {
        public let latitude: Double
        public let longitude: Double

        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }

        func distanceMeters(to other: Coordinate) -> Double {
            let earthRadius = 6_371_000.0
            let dLat = (other.latitude - latitude).degreesToRadians
            let dLon = (other.longitude - longitude).degreesToRadians

            let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(latitude.degreesToRadians)
            * cos(other.latitude.degreesToRadians)
            * sin(dLon / 2) * sin(dLon / 2)

            let c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return earthRadius * c
        }
    }

    public struct PointOfInterest: Identifiable, Hashable, Codable {
        public enum Kind: String, Codable {
            case arrival
            case coffee
            case drop
            case custom
        }

        public let id: String
        public let name: String
        public let coordinate: Coordinate
        public let radiusMeters: Double
        public let kind: Kind
        public let metadata: [String: String]?

        public init(
            id: String,
            name: String,
            coordinate: Coordinate,
            radiusMeters: Double,
            kind: Kind = .custom,
            metadata: [String: String]? = nil
        ) {
            self.id = id
            self.name = name
            self.coordinate = coordinate
            self.radiusMeters = radiusMeters
            self.kind = kind
            self.metadata = metadata
        }

        public func contains(latitude: Double, longitude: Double) -> Bool {
            let location = Coordinate(latitude: latitude, longitude: longitude)
            return coordinate.distanceMeters(to: location) <= radiusMeters
        }
    }

    public let id: String
    public let displayName: String
    public let center: Coordinate
    public let radiusMeters: Double
    public let pois: [PointOfInterest]
    public let notes: String?

    public init(
        id: String,
        displayName: String,
        center: Coordinate,
        radiusMeters: Double,
        pois: [PointOfInterest],
        notes: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.center = center
        self.radiusMeters = radiusMeters
        self.pois = pois
        self.notes = notes
    }

    public func contains(latitude: Double, longitude: Double) -> Bool {
        let location = Coordinate(latitude: latitude, longitude: longitude)
        return center.distanceMeters(to: location) <= radiusMeters
    }

    public func contains(context: Context) -> Bool {
        guard let latitude = context.latitude, let longitude = context.longitude else {
            return false
        }
        return contains(latitude: latitude, longitude: longitude)
    }

    public func isInsideZone(latitude: Double?, longitude: Double?) -> Bool {
        guard let latitude, let longitude else {
            return false
        }
        return contains(latitude: latitude, longitude: longitude)
    }

    public func poi(containingLatitude latitude: Double, longitude: Double) -> PointOfInterest? {
        pois.first { $0.contains(latitude: latitude, longitude: longitude) }
    }

    public func nearestPOI(
        latitude: Double,
        longitude: Double,
        maxDistance: Double? = nil
    ) -> PointOfInterest? {
        let location = Coordinate(latitude: latitude, longitude: longitude)
        return pois
            .map { poi in (poi, poi.coordinate.distanceMeters(to: location)) }
            .filter { maxDistance == nil || $0.1 <= maxDistance! }
            .sorted { $0.1 < $1.1 }
            .first?
            .0
    }
}

private extension Double {
    var degreesToRadians: Double {
        self * .pi / 180
    }
}
