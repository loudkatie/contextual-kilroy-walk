import Foundation

public struct Drop: Identifiable, Hashable, Codable {
    public enum Kind: String, Codable {
        case text
        case link
        case image
        case pdf
    }

    public struct Anchor: Hashable, Codable {
        public let placeId: String
        public let floorBand: String?

        public init(placeId: String, floorBand: String? = nil) {
            self.placeId = placeId
            self.floorBand = floorBand
        }
    }

    public enum Payload: Hashable {
        case text(String)
        case fileURL(URL)
    }

    public let id: UUID
    public let title: String
    public let kind: Kind
    public let payload: Payload
    public let anchor: Anchor
    public let permissionScope: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        kind: Kind,
        payload: Payload,
        anchor: Anchor,
        permissionScope: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.payload = payload
        self.anchor = anchor
        self.permissionScope = permissionScope
        self.createdAt = createdAt
    }
}

extension Drop.Payload: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum PayloadType: String, Codable {
        case text
        case fileURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PayloadType.self, forKey: .type)
        switch type {
        case .text:
            let text = try container.decode(String.self, forKey: .value)
            self = .text(text)
        case .fileURL:
            let urlString = try container.decode(String.self, forKey: .value)
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid URL string")
            }
            self = .fileURL(url)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode(PayloadType.text, forKey: .type)
            try container.encode(text, forKey: .value)
        case .fileURL(let url):
            try container.encode(PayloadType.fileURL, forKey: .type)
            try container.encode(url.absoluteString, forKey: .value)
        }
    }
}
