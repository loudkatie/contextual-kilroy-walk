import Foundation
import Combine

public struct DemoLogEvent: Identifiable, Codable, Hashable {
    public enum Category: String, Codable {
        case info
        case action
        case error
    }

    public let id: UUID
    public let timestamp: Date
    public let message: String
    public let category: Category

    public init(id: UUID = UUID(), timestamp: Date = Date(), message: String, category: Category = .info) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
        self.category = category
    }
}

public final class DemoLogService: ObservableObject {
    @Published public private(set) var events: [DemoLogEvent] = []
    private let maxStoredEvents = 200

    public init() {}

    public func append(_ message: String, category: DemoLogEvent.Category = .info) {
        let event = DemoLogEvent(message: message, category: category)
        DispatchQueue.main.async {
            self.events.append(event)
            if self.events.count > self.maxStoredEvents {
                self.events.removeFirst(self.events.count - self.maxStoredEvents)
            }
        }
    }

    public func recentEntries(limit: Int = 50) -> [DemoLogEvent] {
        Array(events.suffix(limit)).reversed()
    }
}
