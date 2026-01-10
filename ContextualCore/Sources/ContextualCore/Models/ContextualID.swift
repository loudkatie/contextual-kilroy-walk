import Foundation

public struct ContextualID: Identifiable, Hashable, Codable {
    public let uuid: UUID
    public let createdAt: Date

    public var id: UUID { uuid }

    public init(uuid: UUID = UUID(), createdAt: Date = Date()) {
        self.uuid = uuid
        self.createdAt = createdAt
    }
}
