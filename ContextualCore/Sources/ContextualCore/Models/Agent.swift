import Foundation
import Combine

public final class Agent: ObservableObject {
    public let identity: ContextualID
    public let bornAt: Date
    public let memoryStore: MemoryStore

    public init(identity: ContextualID = ContextualID(), bornAt: Date = Date(), memoryStore: MemoryStore = MemoryStore()) {
        self.identity = identity
        self.bornAt = bornAt
        self.memoryStore = memoryStore
    }
}
