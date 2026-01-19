import Foundation

public final class TriggerEngine {
    public struct Decision {
        public enum Status {
            case triggered
            case missingLocation
            case outsideZone
            case noMatch
        }

        public let status: Status
        public let moment: Moment?
        public let explanation: String
        public let consentState: ConsentState
        public let eligibility: Bool

        public init(
            status: Status,
            moment: Moment?,
            explanation: String,
            consentState: ConsentState = .idle,
            eligibility: Bool
        ) {
            self.status = status
            self.moment = moment
            self.explanation = explanation
            self.consentState = consentState
            self.eligibility = eligibility
        }
    }

    public let zone: ContextualZone
    public let catalog: [Moment]

    private var lastTriggerDates: [String: Date] = [:]

    public init(
        zone: ContextualZone = FrontierWalkDemoContent.zone,
        moments: [Moment] = FrontierWalkDemoContent.orderedMoments
    ) {
        self.zone = zone
        self.catalog = moments
    }

    public func evaluate(
        context: Context,
        snapshot: MemoryStore.Snapshot,
        now: Date = Date()
    ) -> Decision {
        guard let latitude = context.latitude, let longitude = context.longitude else {
            return Decision(
                status: .missingLocation,
                moment: nil,
                explanation: "No location fix available.",
                consentState: .idle,
                eligibility: false
            )
        }

        guard zone.contains(latitude: latitude, longitude: longitude) else {
            return Decision(
                status: .outsideZone,
                moment: nil,
                explanation: "Outside \(zone.displayName) zone.",
                consentState: .idle,
                eligibility: false
            )
        }

        let poi = zone.poi(containingLatitude: latitude, longitude: longitude)
        let eligible = catalog
            .filter { passesTrigger($0, poi: poi) }
            .filter { passesGating($0, snapshot: snapshot) }
            .filter { passesFloorBand($0, context: context) }
            .filter { passesCooldown($0, now: now) }
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.id < rhs.id
                }
                return lhs.priority > rhs.priority
            }

        guard let moment = eligible.first else {
            return Decision(
                status: .noMatch,
                moment: nil,
                explanation: diagnostics(for: poi, snapshot: snapshot, context: context, now: now),
                consentState: .idle,
                eligibility: false
            )
        }

        let message: String
        if let poi {
            message = "Matched \(poi.name)"
        } else {
            message = "Zone-wide moment available"
        }

        return Decision(
            status: .triggered,
            moment: moment,
            explanation: message,
            consentState: .awaiting,
            eligibility: true
        )
    }

    public func manualTrigger(
        manualID: String,
        snapshot: MemoryStore.Snapshot,
        now: Date = Date()
    ) -> Decision {
        guard let moment = catalog.first(where: { $0.manualTriggerID == manualID }) else {
            return Decision(
                status: .noMatch,
                moment: nil,
                explanation: "No moment wired to \(manualID).",
                consentState: .idle,
                eligibility: false
            )
        }

        guard passesGating(moment, snapshot: snapshot) else {
            let token = moment.gatingToken?.uppercased() ?? "required entitlement"
            return Decision(
                status: .noMatch,
                moment: nil,
                explanation: "Missing \(token) token.",
                consentState: .idle,
                eligibility: false
            )
        }

        guard passesCooldown(moment, now: now) else {
            let remaining = remainingCooldown(for: moment, now: now) ?? moment.cooldownSeconds
            return Decision(
                status: .noMatch,
                moment: nil,
                explanation: "Cooling down \(Int(remaining))s more.",
                consentState: .coolingDown,
                eligibility: false
            )
        }

        return Decision(
            status: .triggered,
            moment: moment,
            explanation: "Manual trigger ready.",
            consentState: .awaiting,
            eligibility: true
        )
    }

    public func markDelivered(_ moment: Moment, at date: Date = Date()) {
        lastTriggerDates[moment.id] = date
    }

    private func passesTrigger(
        _ moment: Moment,
        poi: ContextualZone.PointOfInterest?
    ) -> Bool {
        switch moment.trigger {
        case .zoneEntry:
            return true
        case .poi(let poiID):
            return poi?.id == poiID
        case .manual:
            return false
        }
    }

    private func passesGating(_ moment: Moment, snapshot: MemoryStore.Snapshot) -> Bool {
        guard let token = moment.gatingToken else { return true }
        return snapshot.permissionTokens.contains(token)
    }

    private func passesCooldown(_ moment: Moment, now: Date) -> Bool {
        guard let last = lastTriggerDates[moment.id] else { return true }
        return now.timeIntervalSince(last) >= moment.cooldownSeconds
    }

    private func passesFloorBand(_ moment: Moment, context: Context) -> Bool {
        guard let required = moment.metadata?["floorBand"]?.lowercased() else { return true }
        guard let current = context.floorBand?.lowercased() else { return false }
        return current == required
    }

    private func remainingCooldown(for moment: Moment, now: Date) -> TimeInterval? {
        guard let last = lastTriggerDates[moment.id] else { return nil }
        let elapsed = now.timeIntervalSince(last)
        let remaining = moment.cooldownSeconds - elapsed
        return remaining > 0 ? remaining : nil
    }

    private func diagnostics(
        for poi: ContextualZone.PointOfInterest?,
        snapshot: MemoryStore.Snapshot,
        context: Context,
        now: Date
    ) -> String {
        let scoped = catalog.filter { passesTrigger($0, poi: poi) }
        guard !scoped.isEmpty else {
            return poi == nil ? "No zone moments configured." : "No scripted moment for \(poi?.name ?? "POI")."
        }

        let gated = scoped.filter { !passesGating($0, snapshot: snapshot) }
        if !gated.isEmpty {
            let tokens = gated
                .compactMap { $0.gatingToken?.uppercased() }
                .joined(separator: ", ")
            return "Waiting on tokens: \(tokens)"
        }

        let floorBlocked = scoped.filter { !passesFloorBand($0, context: context) }
        if !floorBlocked.isEmpty {
            return "Wrong floor for \(floorBlocked.count) moment(s)."
        }

        let cooling = scoped.filter { !passesCooldown($0, now: now) }
        if !cooling.isEmpty {
            return "Cooling down \(cooling.count) moment(s)."
        }

        return "Moments here require manual trigger."
    }
}
