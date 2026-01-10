import Foundation
import Combine

public final class MemoryStore: ObservableObject {
    public struct Snapshot: Codable {
        public var likedDrops: Set<UUID>
        public var ignoredDrops: Set<UUID>
        public var permissionTokens: Set<String>
        public var lastUpdated: Date

        public init(
            likedDrops: Set<UUID> = [],
            ignoredDrops: Set<UUID> = [],
            permissionTokens: Set<String> = [],
            lastUpdated: Date = Date()
        ) {
            self.likedDrops = likedDrops
            self.ignoredDrops = ignoredDrops
            self.permissionTokens = permissionTokens
            self.lastUpdated = lastUpdated
        }
    }

    @Published public private(set) var snapshot: Snapshot

    private let fileURL: URL
    private let decoder = JSONDecoder()
    private let persistenceQueue = DispatchQueue(label: "ContextualCore.MemoryStore")

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? MemoryStore.defaultFileURL()
        if let data = try? Data(contentsOf: self.fileURL),
           let decoded = try? decoder.decode(Snapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = Snapshot()
            persist(snapshot)
        }
    }

    public func like(dropID: UUID) {
        mutate { snapshot in
            snapshot.likedDrops.insert(dropID)
            snapshot.ignoredDrops.remove(dropID)
        }
    }

    public func ignore(dropID: UUID) {
        mutate { snapshot in
            snapshot.ignoredDrops.insert(dropID)
            snapshot.likedDrops.remove(dropID)
        }
    }

    public func clearReaction(for dropID: UUID) {
        mutate { snapshot in
            snapshot.likedDrops.remove(dropID)
            snapshot.ignoredDrops.remove(dropID)
        }
    }

    public func recordPermissionToken(_ token: String) {
        mutate { snapshot in
            snapshot.permissionTokens.insert(token)
        }
    }

    public func summaryDescription() -> String {
        "Likes: \(snapshot.likedDrops.count)  •  Ignores: \(snapshot.ignoredDrops.count)  •  Tokens: \(snapshot.permissionTokens.count)"
    }

    private func mutate(_ mutateBlock: @escaping (inout Snapshot) -> Void) {
        DispatchQueue.main.async {
            mutateBlock(&self.snapshot)
            self.snapshot.lastUpdated = Date()
            self.persist(self.snapshot)
        }
    }

    private func persist(_ snapshot: Snapshot) {
        persistenceQueue.async { [fileURL] in
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(snapshot)
                try data.write(to: fileURL, options: [.atomic])
            } catch {
#if DEBUG
                NSLog("MemoryStore persist error: %@", error.localizedDescription)
#endif
            }
        }
    }

    private static func defaultFileURL() -> URL {
        let fm = FileManager.default
        let directory = fm.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        return directory.appendingPathComponent("ContextualMemoryStore.json")
    }
}
