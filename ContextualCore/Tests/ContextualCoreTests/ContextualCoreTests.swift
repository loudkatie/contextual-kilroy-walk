import XCTest
@testable import ContextualCore

final class ContextualCoreTests: XCTestCase {
    func testMemoryStorePersistsLikes() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("memory-test.json")
        try? FileManager.default.removeItem(at: tempURL)
        let store = MemoryStore(fileURL: tempURL)
        let dropID = UUID()
        store.like(dropID: dropID)

        // Wait briefly for async persist to finish
        let expectation = XCTestExpectation(description: "Persisted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let rehydrated = MemoryStore(fileURL: tempURL)
        XCTAssertTrue(rehydrated.snapshot.likedDrops.contains(dropID))
    }
}
