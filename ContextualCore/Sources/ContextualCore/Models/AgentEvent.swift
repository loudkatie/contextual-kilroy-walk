import Foundation

public struct AgentEvent: Hashable, Codable, Identifiable {
    public enum Kind: String, Codable {
        case location
        case action
        case reaction
        case whisper
        case system
    }

    public let id: UUID
    public let kind: Kind
    public let detail: String?
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        kind: Kind,
        detail: String? = nil,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.detail = detail
        self.timestamp = timestamp
        self.metadata = metadata
    }
}
