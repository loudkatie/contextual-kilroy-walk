import Foundation

public protocol Connector {
    var name: String { get }
    var description: String { get }

    func fetchDrops(for context: Context) async throws -> [Drop]
}
