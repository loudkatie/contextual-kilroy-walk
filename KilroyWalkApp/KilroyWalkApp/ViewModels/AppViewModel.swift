import Foundation
import SwiftUI
import AVFoundation
import UIKit
import Combine

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
    @Published var locationMode: DemoLocationMode = .outside {
        didSet {
            guard oldValue != locationMode else { return }
            applyLocationMode(locationMode, logAction: true)
        }
    }
    @Published private(set) var activeMoment: Moment?
    @Published private(set) var momentDiagnostics: String
    @Published private(set) var locationSummary: String
    @Published private(set) var currentPOILabel: String?
    @Published private(set) var consentState: ConsentState = .idle

    private let kilroyConnector: KilroyDropsConnector
    private let calendarConnector: CalendarConnector
    private let audioService: AudioWhisperService
    private let triggerEngine: TriggerEngine
    private var cancellables: Set<AnyCancellable> = []

    init(
        agent: Agent = Agent(),
        demoLog: DemoLogService = DemoLogService(),
        kilroyConnector: KilroyDropsConnector = KilroyDropsConnector(),
        calendarConnector: CalendarConnector = CalendarConnector(),
        audioService: AudioWhisperService? = nil,
        triggerEngine: TriggerEngine = TriggerEngine()
    ) {
        self.agent = agent
        self.demoLog = demoLog
        self.kilroyConnector = kilroyConnector
        self.calendarConnector = calendarConnector
        let resolvedAudioService = audioService ?? AudioWhisperService()
        self.audioService = resolvedAudioService
        self.triggerEngine = triggerEngine
        self.context = Context(placeId: triggerEngine.zone.id, timestamp: Date())
        self.connectorStatuses = [
            ConnectorStatus(name: kilroyConnector.name, description: kilroyConnector.description, lastSynced: nil, state: .idle),
            ConnectorStatus(name: calendarConnector.name, description: calendarConnector.description, lastSynced: nil, state: .idle)
        ]
        self.audioRouteDescription = resolvedAudioService.currentRouteDescription
        self.activeMoment = nil
        self.momentDiagnostics = "No moment yet"
        self.locationSummary = "Outside zone"
        self.currentPOILabel = nil

        resolvedAudioService.routeDescriptionDidChange = { [weak self] description in
            self?.audioRouteDescription = description
        }

        applyLocationMode(locationMode, logAction: false)

        agent.memoryStore.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reevaluateMoments(reason: "Memory updated", logEvenIfMissing: false)
            }
            .store(in: &cancellables)
    }

    func bootstrap() async {
        await refreshDrops(reason: "Initial sync")
    }

    func triggerArrival() {
        softHapticTap()
        audioService.playWelcome()
        forceLocationMode(.arrival)
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

    func triggerManualMoment(_ manual: ManualMoment) {
        let decision = triggerEngine.manualTrigger(
            manualID: manual.manualID,
            snapshot: agent.memoryStore.snapshot
        )

        switch decision.status {
        case .triggered:
            if let moment = decision.moment {
                activate(moment: moment, reason: manual.displayName, explanation: decision.explanation, eligibility: decision.eligibility)
            }
        case .missingLocation, .outsideZone, .noMatch:
            consentState = decision.consentState
            momentDiagnostics = decision.explanation
            demoLog.append(
                "Manual \(manual.displayName) skipped • eligible=\(decision.eligibility) • \(decision.explanation)",
                category: .info
            )
        }
    }

    func storePermissionToken() {
        let trimmed = permissionTokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        agent.memoryStore.recordPermissionToken(trimmed)
        permissionTokenInput = ""
        demoLog.append("Permission token stored", category: .action)
        reevaluateMoments(reason: "Permission token updated", logEvenIfMissing: false)
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

        do {
            let fetchedDrops = try await connector.fetchDrops(for: context)
            accumulator.append(contentsOf: fetchedDrops)
            setStatus(for: connector.name, state: .ready)
        } catch {
            setStatus(for: connector.name, state: .error(error.localizedDescription))
            errors.append("\(connector.name): \(error.localizedDescription)")
        }
    }

    func forceLocationMode(_ mode: DemoLocationMode) {
        if locationMode == mode {
            applyLocationMode(mode, logAction: true)
        } else {
            locationMode = mode
        }
    }

    private func applyLocationMode(_ mode: DemoLocationMode, logAction: Bool) {
        let zone = triggerEngine.zone
        let coordinate = mode.coordinate(in: zone)
        context.latitude = coordinate?.latitude
        context.longitude = coordinate?.longitude
        context.placeId = mode == .outside ? nil : (coordinate == nil ? nil : zone.id)
        context.timestamp = Date()

        currentPOILabel = mode.poiLabel(in: zone)
        if let poiName = currentPOILabel {
            locationSummary = "\(mode.displayName) – \(poiName)"
        } else {
            locationSummary = mode.displayName
        }

        if logAction {
            demoLog.append("Location mode → \(mode.displayName)", category: .action)
            reevaluateMoments(reason: "Location mode \(mode.displayName)")
        }
    }

    private func reevaluateMoments(reason: String, logEvenIfMissing: Bool = true) {
        let decision = triggerEngine.evaluate(
            context: context,
            snapshot: agent.memoryStore.snapshot
        )

        switch decision.status {
        case .triggered:
            if let moment = decision.moment {
                activate(
                    moment: moment,
                    reason: reason,
                    explanation: decision.explanation,
                    eligibility: decision.eligibility
                )
            }
        case .missingLocation, .outsideZone, .noMatch:
            activeMoment = nil
            consentState = decision.consentState
            momentDiagnostics = decision.explanation
            if logEvenIfMissing {
                demoLog.append(
                    "\(reason): eligible=\(decision.eligibility) • \(decision.explanation)",
                    category: .info
                )
            }
        }
    }

    private func activate(moment: Moment, reason: String, explanation: String, eligibility: Bool) {
        activeMoment = moment
        momentDiagnostics = explanation
        consentState = .awaiting
        triggerEngine.markDelivered(moment)
        demoLog.append(
            "Moment ready (\(moment.title)) via \(reason) • eligible=\(eligibility) • \(explanation)",
            category: .action
        )
        softHapticTap()
        playWhisper(for: moment)
    }

    private func playWhisper(for moment: Moment) {
        switch moment.whisperAudioKey {
        case "psst_welcome_frontier":
            audioService.playWelcome()
        case "psst_drop_here":
            audioService.playDropHere()
        case "psst_want_to_open":
            audioService.playWantToOpen()
        default:
            audioService.playWantToOpen()
        }
    }

    private func softHapticTap() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
    }
}

extension AppViewModel {
    enum DemoLocationMode: String, CaseIterable, Identifiable {
        case outside
        case arrival
        case coffee
        case drop

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .outside:
                return "Outside Zone"
            case .arrival:
                return "Arrival Perimeter"
            case .coffee:
                return "Coffee Nook"
            case .drop:
                return "Drop Corner"
            }
        }

        func coordinate(in zone: ContextualZone) -> ContextualZone.Coordinate? {
            switch self {
            case .outside:
                return ContextualZone.Coordinate(
                    latitude: zone.center.latitude + 0.01,
                    longitude: zone.center.longitude + 0.01
                )
            case .arrival:
                return zone.pois.first(where: { $0.id == "frontier_arrival" })?.coordinate ?? zone.center
            case .coffee:
                return zone.pois.first(where: { $0.id == "frontier_coffee" })?.coordinate ?? zone.center
            case .drop:
                return zone.pois.first(where: { $0.id == "frontier_drop_corner" })?.coordinate ?? zone.center
            }
        }

        func poiLabel(in zone: ContextualZone) -> String? {
            switch self {
            case .outside:
                return nil
            case .arrival:
                return zone.pois.first(where: { $0.id == "frontier_arrival" })?.name
            case .coffee:
                return zone.pois.first(where: { $0.id == "frontier_coffee" })?.name
            case .drop:
                return zone.pois.first(where: { $0.id == "frontier_drop_corner" })?.name
            }
        }
    }

    enum ManualMoment: String, CaseIterable, Identifiable {
        case arrival
        case coffee
        case drop

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .arrival:
                return "Moment 1 – Arrival"
            case .coffee:
                return "Moment 2 – Coffee"
            case .drop:
                return "Moment 3 – Drop"
            }
        }

        var buttonLabel: String {
            "Trigger \(displayName)"
        }

        var manualID: String {
            switch self {
            case .arrival:
                return "moment.arrival"
            case .coffee:
                return "moment.coffee"
            case .drop:
                return "moment.drop"
            }
        }
    }
}
