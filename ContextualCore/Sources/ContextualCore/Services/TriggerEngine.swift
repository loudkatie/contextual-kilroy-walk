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
        public let message: String

        public init(status: Status, moment: Moment?, message: String) {
            self.status = status
            self.moment = moment
            self.message = message
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
            return Decision(status: .missingLocation, moment: nil, message: "No location fix available.")
        }

        guard zone.contains(latitude: latitude, longitude: longitude) else {
            return Decision(
                status: .outsideZone,
                moment: nil,
                message: "Outside \(zone.displayName) zone."
            )
        }

        let poi = zone.poi(containingLatitude: latitude, longitude: longitude)
        let eligible = catalog
            .filter { passesTrigger($0, poi: poi) }
            .filter { passesGating($0, snapshot: snapshot) }
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
                message: diagnostics(for: poi, snapshot: snapshot, now: now)
            )
        }

        let message: String
        if let poi {
            message = "Matched \(poi.name)"
        } else {
            message = "Zone-wide moment available"
        }

        return Decision(status: .triggered, moment: moment, message: message)
    }

    public func manualTrigger(
        manualID: String,
        snapshot: MemoryStore.Snapshot,
        now: Date = Date()
    ) -> Decision {
        guard let moment = catalog.first(where: { $0.manualTriggerID == manualID }) else {
            return Decision(status: .noMatch, moment: nil, message: "No moment wired to \(manualID).")
        }

        guard passesGating(moment, snapshot: snapshot) else {
            let token = moment.gatingToken?.uppercased() ?? "required entitlement"
            return Decision(
                status: .noMatch,
                moment: nil,
                message: "Missing \(token) token."
            )
        }

        guard passesCooldown(moment, now: now) else {
            let remaining = remainingCooldown(for: moment, now: now) ?? moment.cooldownSeconds
            return Decision(
                status: .noMatch,
                moment: nil,
                message: "Cooling down \(Int(remaining))s more."
            )
        }

        return Decision(status: .triggered, moment: moment, message: "Manual trigger ready.")
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

    private func remainingCooldown(for moment: Moment, now: Date) -> TimeInterval? {
        guard let last = lastTriggerDates[moment.id] else { return nil }
        let elapsed = now.timeIntervalSince(last)
        let remaining = moment.cooldownSeconds - elapsed
        return remaining > 0 ? remaining : nil
    }

    private func diagnostics(
        for poi: ContextualZone.PointOfInterest?,
        snapshot: MemoryStore.Snapshot,
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

        let cooling = scoped.filter { !passesCooldown($0, now: now) }
        if !cooling.isEmpty {
            return "Cooling down \(cooling.count) moment(s)."
        }

        return "Moments here require manual trigger."
    }
}
