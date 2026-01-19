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
    @Published var agentMode: AgentMode = .local {
        didSet { persistAgentSettings() }
    }
    @Published var agentServerURLInput: String = "" {
        didSet { persistAgentSettings() }
    }
    @Published var locationMode: DemoLocationMode = .outside {
        didSet {
            guard oldValue != locationMode else { return }
            applyLocationMode(locationMode, logAction: true)
        }
    }
    @Published private(set) var activeMoment: Moment?
    @Published private(set) var activePlan: AgentPlan?
    @Published private(set) var momentDiagnostics: String
    @Published private(set) var locationSummary: String
    @Published private(set) var currentPOILabel: String?
    @Published private(set) var consentState: ConsentState = .idle

    private let kilroyConnector: KilroyDropsConnector
    private let calendarConnector: CalendarConnector
    private let audioService: AudioWhisperService
    private let triggerEngine: TriggerEngine
    private let agentPlanner: AgentPlanner
    private let agentAPIClient: AgentAPIClient
    private var cancellables: Set<AnyCancellable> = []
    private var recentEvents: [AgentEvent] = []
    private let maxStoredEvents = 20
    private var planTask: Task<Void, Never>?

    init(
        agent: Agent = Agent(),
        demoLog: DemoLogService = DemoLogService(),
        kilroyConnector: KilroyDropsConnector = KilroyDropsConnector(),
        calendarConnector: CalendarConnector = CalendarConnector(),
        audioService: AudioWhisperService? = nil,
        triggerEngine: TriggerEngine = TriggerEngine(),
        agentPlanner: AgentPlanner = AgentPlanner(),
        agentAPIClient: AgentAPIClient = AgentAPIClient()
    ) {
        self.agent = agent
        self.demoLog = demoLog
        self.kilroyConnector = kilroyConnector
        self.calendarConnector = calendarConnector
        let resolvedAudioService = audioService ?? AudioWhisperService()
        self.audioService = resolvedAudioService
        self.triggerEngine = triggerEngine
        self.agentPlanner = agentPlanner
        self.agentAPIClient = agentAPIClient
        self.context = Context(placeId: triggerEngine.zone.id, timestamp: Date())
        self.connectorStatuses = [
            ConnectorStatus(name: kilroyConnector.name, description: kilroyConnector.description, lastSynced: nil, state: .idle),
            ConnectorStatus(name: calendarConnector.name, description: calendarConnector.description, lastSynced: nil, state: .idle)
        ]
        self.audioRouteDescription = resolvedAudioService.currentRouteDescription
        self.activeMoment = nil
        self.activePlan = nil
        self.momentDiagnostics = "No moment yet"
        self.locationSummary = "Outside zone"
        self.currentPOILabel = nil
        self.agentMode = loadAgentMode()
        self.agentServerURLInput = loadAgentURL()

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
        recordEvent(kind: .action, detail: "arrival_triggered", metadata: ["source": "manual"])
        demoLog.append("Arrival event triggered", category: .action)
        Task {
            await refreshDrops(reason: "Arrival event")
        }
    }

    func setFloorBand() {
        guard !floorBandInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        context.floorBand = floorBandInput.uppercased()
        recordEvent(kind: .location, detail: "floor_band_set", metadata: ["floor": context.floorBand ?? ""])
        demoLog.append("Floor band set to \(context.floorBand ?? "n/a")", category: .action)
        Task {
            await refreshDrops(reason: "Floor change")
        }
    }

    func triggerFloorEvent() async {
        await refreshDrops(reason: "Manual floor trigger")
    }

    func triggerManualMoment(_ manual: ManualMoment) {
        recordEvent(kind: .action, detail: "manual_trigger", metadata: ["id": manual.manualID])
        guard agentMode == .remote, let _ = agentBaseURL() else {
            let decision = agentPlanner.planManual(
                manualID: manual.manualID,
                snapshot: agent.memoryStore.snapshot,
                triggerEngine: triggerEngine
            )

            switch decision.status {
            case .triggered:
                if let moment = decision.moment {
                    activate(
                        moment: moment,
                        plan: decision.plan,
                        reason: manual.displayName,
                        explanation: decision.explanation,
                        eligibility: decision.eligibility
                    )
                }
            case .missingLocation, .outsideZone, .noMatch:
                consentState = decision.consentState
                momentDiagnostics = decision.explanation
                activePlan = nil
                demoLog.append(
                    "Manual \(manual.displayName) skipped • eligible=\(decision.eligibility) • \(decision.explanation)",
                    category: .info
                )
            }
            return
        }

        momentDiagnostics = "Contacting Tink..."
        requestRemotePlan(reason: manual.displayName, manualID: manual.manualID)
    }

    func storePermissionToken() {
        let trimmed = permissionTokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        agent.memoryStore.recordPermissionToken(trimmed)
        recordEvent(kind: .action, detail: "permission_token_added", metadata: ["token": trimmed])
        permissionTokenInput = ""
        demoLog.append("Permission token stored", category: .action)
        reevaluateMoments(reason: "Permission token updated", logEvenIfMissing: false)
        Task {
            await refreshDrops(reason: "Permission token updated")
        }
    }

    func like(drop: Drop) {
        agent.memoryStore.like(dropID: drop.id)
        recordEvent(kind: .reaction, detail: "drop_liked", metadata: ["drop": drop.title])
        demoLog.append("Liked drop: \(drop.title)", category: .action)
    }

    func ignore(drop: Drop) {
        agent.memoryStore.ignore(dropID: drop.id)
        recordEvent(kind: .reaction, detail: "drop_ignored", metadata: ["drop": drop.title])
        demoLog.append("Ignored drop: \(drop.title)", category: .action)
    }

    func testWhisper() {
        audioService.playWantToOpen()
    }

    func handleAction(_ action: MomentAction, for moment: Moment) {
        let actionSummary = "\(action.title) [\(action.kind.rawValue)]"
        switch action.kind {
        case .acknowledge:
            recordEvent(kind: .reaction, detail: "moment_acknowledged", metadata: ["moment": moment.title])
            demoLog.append("Action tapped: \(actionSummary) • moment dismissed", category: .action)
            completeMoment(with: "Moment dismissed by user.", consent: .idle)
        case .openURL:
            guard let payload = action.payload, let url = URL(string: payload) else {
                demoLog.append("Action tapped: \(actionSummary) • invalid URL payload.", category: .error)
                return
            }
            recordEvent(kind: .action, detail: "open_url", metadata: ["url": payload])
            demoLog.append("Action tapped: \(actionSummary) • opening \(payload)", category: .action)
            UIApplication.shared.open(url)
            completeMoment(with: "Opened link: \(payload)", consent: .granted)
        case .openDrop:
            let payload = action.payload ?? "unknown drop"
            recordEvent(kind: .action, detail: "open_drop", metadata: ["drop": payload])
            demoLog.append("Action tapped: \(actionSummary) • route via Drops tab (\(payload))", category: .action)
            completeMoment(with: "Drop requested: \(payload)", consent: .granted)
        case .openCard:
            recordEvent(kind: .action, detail: "open_card", metadata: ["moment": moment.title])
            demoLog.append("Action tapped: \(actionSummary) • no view wired yet.", category: .info)
            completeMoment(with: "Captured intent: \(action.title)", consent: .granted)
        }
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
            recordEvent(kind: .location, detail: "location_mode_changed", metadata: ["mode": mode.displayName])
            demoLog.append("Location mode → \(mode.displayName)", category: .action)
            reevaluateMoments(reason: "Location mode \(mode.displayName)")
        }
    }

    private func reevaluateMoments(reason: String, logEvenIfMissing: Bool = true) {
        if agentMode == .remote, agentBaseURL() != nil {
            momentDiagnostics = "Contacting Tink..."
            requestRemotePlan(reason: reason, manualID: nil)
            return
        }

        let decision = agentPlanner.plan(
            context: context,
            snapshot: agent.memoryStore.snapshot,
            triggerEngine: triggerEngine
        )

        switch decision.status {
        case .triggered:
            if let moment = decision.moment {
                activate(
                    moment: moment,
                    plan: decision.plan,
                    reason: reason,
                    explanation: decision.explanation,
                    eligibility: decision.eligibility
                )
            }
        case .missingLocation, .outsideZone, .noMatch:
            activeMoment = nil
            activePlan = nil
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

    private func activate(moment: Moment, plan: AgentPlan?, reason: String, explanation: String, eligibility: Bool) {
        activeMoment = moment
        activePlan = plan
        momentDiagnostics = explanation
        consentState = .awaiting
        triggerEngine.markDelivered(moment)
        demoLog.append(
            "Moment ready (\(moment.title)) via \(reason) • eligible=\(eligibility) • \(explanation)",
            category: .action
        )
        if let plan {
            let secondary = plan.secondaryAction?.title ?? "none"
            demoLog.append("Plan schema • primary=\(plan.primaryAction.title) • secondary=\(secondary)", category: .info)
        }
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
        recordEvent(kind: .whisper, detail: "whisper_played", metadata: ["key": moment.whisperAudioKey ?? "default"])
    }

    private func softHapticTap() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
    }

    private func completeMoment(with message: String, consent: ConsentState) {
        activeMoment = nil
        consentState = consent
        momentDiagnostics = message
    }

    private func requestRemotePlan(reason: String, manualID: String?) {
        guard let baseURL = agentBaseURL() else {
            demoLog.append("AI server URL missing; using local planner.", category: .error)
            return
        }

        planTask?.cancel()
        let request = AgentPlanRequest(
            contextualID: agent.identity.uuid.uuidString,
            context: context,
            memory: agent.memoryStore.snapshot,
            recentEvents: Array(recentEvents.suffix(maxStoredEvents)),
            manualID: manualID,
            timestamp: Date()
        )

        planTask = Task {
            do {
                let response = try await agentAPIClient.plan(request: request, baseURL: baseURL)
                handleRemoteResponse(response, reason: reason)
            } catch {
                demoLog.append("AI request failed (\(error.localizedDescription)); using local planner.", category: .error)
                let fallback: AgentPlanDecision
                if let manualID {
                    fallback = agentPlanner.planManual(
                        manualID: manualID,
                        snapshot: agent.memoryStore.snapshot,
                        triggerEngine: triggerEngine
                    )
                } else {
                    fallback = agentPlanner.plan(
                        context: context,
                        snapshot: agent.memoryStore.snapshot,
                        triggerEngine: triggerEngine
                    )
                }
                if fallback.status == .triggered, let moment = fallback.moment {
                    activate(
                        moment: moment,
                        plan: fallback.plan,
                        reason: "Local fallback",
                        explanation: fallback.explanation,
                        eligibility: fallback.eligibility
                    )
                } else {
                    activeMoment = nil
                    activePlan = nil
                    consentState = fallback.consentState
                    momentDiagnostics = fallback.explanation
                }
            }
        }
    }

    private func handleRemoteResponse(_ response: AgentPlanResponse, reason: String) {
        let status = response.status.lowercased()
        let eligibility = response.eligibility ?? false
        consentState = response.consentState ?? .idle

        if status == "triggered", let moment = response.moment {
            activate(
                moment: moment,
                plan: response.plan,
                reason: "AI • \(reason)",
                explanation: response.explanation,
                eligibility: eligibility
            )
            return
        }

        activeMoment = nil
        activePlan = nil
        momentDiagnostics = response.explanation
        demoLog.append("AI: \(response.explanation)", category: .info)
    }

    private func recordEvent(kind: AgentEvent.Kind, detail: String?, metadata: [String: String] = [:]) {
        let event = AgentEvent(kind: kind, detail: detail, metadata: metadata)
        recentEvents.append(event)
        if recentEvents.count > maxStoredEvents {
            recentEvents.removeFirst(recentEvents.count - maxStoredEvents)
        }
    }

    private func agentBaseURL() -> URL? {
        let trimmed = agentServerURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    private func persistAgentSettings() {
        UserDefaults.standard.set(agentServerURLInput, forKey: "contextual.agentServerURL")
        UserDefaults.standard.set(agentMode.rawValue, forKey: "contextual.agentMode")
    }

    private func loadAgentURL() -> String {
        UserDefaults.standard.string(forKey: "contextual.agentServerURL") ?? ""
    }

    private func loadAgentMode() -> AgentMode {
        let stored = UserDefaults.standard.string(forKey: "contextual.agentMode")
        return AgentMode(rawValue: stored ?? "") ?? .local
    }
}

extension AppViewModel {
    enum AgentMode: String, CaseIterable, Identifiable {
        case local
        case remote

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .local:
                return "Local Planner"
            case .remote:
                return "AI Server"
            }
        }
    }

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
