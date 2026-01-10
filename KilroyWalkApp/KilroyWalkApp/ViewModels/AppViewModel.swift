import Foundation
import SwiftUI
import AVFoundation
import UIKit
import ContextualCore

@MainActor
final class AppViewModel: ObservableObject {
    struct ConnectorStatus: Identifiable {
        enum State: Equatable {
            case idle
            case syncing
            case ready
            case error(String)

            var iconName: String {
                switch self {
                case .idle:
                    return "pause.circle"
                case .syncing:
                    return "arrow.triangle.2.circlepath.circle"
                case .ready:
                    return "checkmark.circle"
                case .error:
                    return "exclamationmark.triangle"
                }
            }

            var tint: Color {
                switch self {
                case .idle:
                    return .secondary
                case .syncing:
                    return .blue
                case .ready:
                    return .green
                case .error:
                    return .red
                }
            }
        }

        let name: String
        let description: String
        var lastSynced: Date?
        var state: State

        var id: String { name }
    }

    let agent: Agent
    let demoLog: DemoLogService

    @Published var context: Context
    @Published var drops: [Drop] = []
    @Published var floorBandInput: String = ""
    @Published var permissionTokenInput: String = ""
    @Published private(set) var connectorStatuses: [ConnectorStatus] = []
    @Published private(set) var audioRouteDescription: String

    private let kilroyConnector: KilroyDropsConnector
    private let calendarConnector: CalendarConnector
    private let audioService: AudioWhisperService

    init(
        agent: Agent = Agent(),
        demoLog: DemoLogService = DemoLogService(),
        kilroyConnector: KilroyDropsConnector = KilroyDropsConnector(),
        calendarConnector: CalendarConnector = CalendarConnector(),
        audioService: AudioWhisperService = AudioWhisperService()
    ) {
        self.agent = agent
        self.demoLog = demoLog
        self.kilroyConnector = kilroyConnector
        self.calendarConnector = calendarConnector
        self.audioService = audioService
        self.context = Context(placeId: "frontier_tower", timestamp: Date())
        self.connectorStatuses = [
            ConnectorStatus(name: kilroyConnector.name, description: kilroyConnector.description, lastSynced: nil, state: .idle),
            ConnectorStatus(name: calendarConnector.name, description: calendarConnector.description, lastSynced: nil, state: .idle)
        ]
        self.audioRouteDescription = audioService.currentRouteDescription

        audioService.routeDescriptionDidChange = { [weak self] description in
            self?.audioRouteDescription = description
        }
    }

    func bootstrap() async {
        await refreshDrops(reason: "Initial sync")
    }

    func triggerArrival() {
        softHapticTap()
        audioService.playWelcome()
        context.placeId = "frontier_tower"
        context.timestamp = Date()
        demoLog.append("Arrival event triggered", category: .action)
        Task {
            await refreshDrops(reason: "Arrival event")
        }
    }

    func setFloorBand() {
        guard !floorBandInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        context.floorBand = floorBandInput.uppercased()
        demoLog.append("Floor band set to \(context.floorBand ?? "n/a")", category: .action)
        Task {
            await refreshDrops(reason: "Floor change")
        }
    }

    func triggerFloorEvent() async {
        await refreshDrops(reason: "Manual floor trigger")
    }

    func storePermissionToken() {
        let trimmed = permissionTokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        agent.memoryStore.recordPermissionToken(trimmed)
        permissionTokenInput = ""
        demoLog.append("Permission token stored", category: .action)
        Task {
            await refreshDrops(reason: "Permission token updated")
        }
    }

    func like(drop: Drop) {
        agent.memoryStore.like(dropID: drop.id)
        demoLog.append("Liked drop: \(drop.title)", category: .action)
    }

    func ignore(drop: Drop) {
        agent.memoryStore.ignore(dropID: drop.id)
        demoLog.append("Ignored drop: \(drop.title)", category: .action)
    }

    func testWhisper() {
        audioService.playWantToOpen()
    }

    func isLiked(drop: Drop) -> Bool {
        agent.memoryStore.snapshot.likedDrops.contains(drop.id)
    }

    func isIgnored(drop: Drop) -> Bool {
        agent.memoryStore.snapshot.ignoredDrops.contains(drop.id)
    }

    func connectorStatusList() -> [ConnectorStatus] {
        connectorStatuses
    }

    private func refreshDrops(reason: String) async {
        var combined: [Drop] = []
        var errors: [String] = []

        await fetchAndRecord(from: kilroyConnector, accumulator: &combined, errors: &errors)
        await fetchAndRecord(from: calendarConnector, accumulator: &combined, errors: &errors)

        let filtered = filterDrops(combined)
        drops = filtered.sorted(by: { $0.createdAt > $1.createdAt })

        if errors.isEmpty {
            demoLog.append("\(reason): \(filtered.count) drops available", category: .info)
        } else {
            demoLog.append("Partial sync (\(filtered.count) drops). Issues: \(errors.joined(separator: ", "))", category: .error)
        }

        if !filtered.isEmpty {
            softHapticTap()
            audioService.playDropHere()
        }
    }

    private func filterDrops(_ drops: [Drop]) -> [Drop] {
        let permissionTokens = agent.memoryStore.snapshot.permissionTokens
        return drops.filter { drop in
            guard let requiredScope = drop.permissionScope else { return true }
            return permissionTokens.contains(requiredScope)
        }
    }

    private func setStatus(for name: String, state: ConnectorStatus.State) {
        guard let index = connectorStatuses.firstIndex(where: { $0.name == name }) else { return }
        connectorStatuses[index].state = state
        if case .ready = state {
            connectorStatuses[index].lastSynced = Date()
        }
    }

    private func fetchAndRecord<C: Connector>(
        from connector: C,
        accumulator: inout [Drop],
        errors: inout [String]
    ) async {
        setStatus(for: connector.name, state: .syncing)
        let result = await Result { try await connector.fetchDrops(for: context) }
        switch result {
        case .success(let drops):
            accumulator.append(contentsOf: drops)
            setStatus(for: connector.name, state: .ready)
        case .failure(let error):
            setStatus(for: connector.name, state: .error(error.localizedDescription))
            errors.append("\(connector.name): \(error.localizedDescription)")
        }
    }

    private func softHapticTap() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
    }
}
