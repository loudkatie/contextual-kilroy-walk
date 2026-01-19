import Foundation

public struct AgentPlan: Hashable, Codable {
    public let momentID: String
    public let title: String
    public let whisperAudioKey: String?
    public let hostLine: String
    public let detail: String?
    public let primaryAction: MomentAction
    public let secondaryAction: MomentAction?
    public let source: String

    public init(
        momentID: String,
        title: String,
        whisperAudioKey: String?,
        hostLine: String,
        detail: String?,
        primaryAction: MomentAction,
        secondaryAction: MomentAction?,
        source: String
    ) {
        self.momentID = momentID
        self.title = title
        self.whisperAudioKey = whisperAudioKey
        self.hostLine = hostLine
        self.detail = detail
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.source = source
    }
}

public struct AgentPlanDecision {
    public enum Status {
        case triggered
        case missingLocation
        case outsideZone
        case noMatch
    }

    public let status: Status
    public let moment: Moment?
    public let plan: AgentPlan?
    public let explanation: String
    public let consentState: ConsentState
    public let eligibility: Bool

    public init(
        status: Status,
        moment: Moment?,
        plan: AgentPlan?,
        explanation: String,
        consentState: ConsentState = .idle,
        eligibility: Bool
    ) {
        self.status = status
        self.moment = moment
        self.plan = plan
        self.explanation = explanation
        self.consentState = consentState
        self.eligibility = eligibility
    }
}

public final class AgentPlanner {
    public init() {}

    public func plan(
        context: Context,
        snapshot: MemoryStore.Snapshot,
        triggerEngine: TriggerEngine,
        now: Date = Date()
    ) -> AgentPlanDecision {
        let decision = triggerEngine.evaluate(context: context, snapshot: snapshot, now: now)
        return map(decision, source: "auto")
    }

    public func planManual(
        manualID: String,
        snapshot: MemoryStore.Snapshot,
        triggerEngine: TriggerEngine,
        now: Date = Date()
    ) -> AgentPlanDecision {
        let decision = triggerEngine.manualTrigger(manualID: manualID, snapshot: snapshot, now: now)
        return map(decision, source: manualID)
    }

    private func map(_ decision: TriggerEngine.Decision, source: String) -> AgentPlanDecision {
        let status: AgentPlanDecision.Status
        switch decision.status {
        case .triggered:
            status = .triggered
        case .missingLocation:
            status = .missingLocation
        case .outsideZone:
            status = .outsideZone
        case .noMatch:
            status = .noMatch
        }

        guard let moment = decision.moment, decision.status == .triggered else {
            return AgentPlanDecision(
                status: status,
                moment: decision.moment,
                plan: nil,
                explanation: decision.explanation,
                consentState: decision.consentState,
                eligibility: decision.eligibility
            )
        }

        let plan = buildPlan(from: moment, source: source)
        return AgentPlanDecision(
            status: status,
            moment: moment,
            plan: plan,
            explanation: decision.explanation,
            consentState: decision.consentState,
            eligibility: decision.eligibility
        )
    }

    private func buildPlan(from moment: Moment, source: String) -> AgentPlan {
        let (primary, secondary) = selectActions(from: moment.actions)
        return AgentPlan(
            momentID: moment.id,
            title: moment.title,
            whisperAudioKey: moment.whisperAudioKey,
            hostLine: moment.hostLine,
            detail: moment.detail,
            primaryAction: primary,
            secondaryAction: secondary,
            source: source
        )
    }

    private func selectActions(from actions: [MomentAction]) -> (MomentAction, MomentAction?) {
        guard !actions.isEmpty else {
            let fallback = MomentAction(title: "Not now", kind: .acknowledge, style: .secondary)
            return (fallback, nil)
        }

        let sorted = actions.sorted { lhs, rhs in
            styleRank(lhs.style) < styleRank(rhs.style)
        }

        let primary = sorted[0]
        let secondary = sorted.count > 1 ? sorted[1] : nil
        return (primary, secondary)
    }

    private func styleRank(_ style: MomentAction.Style) -> Int {
        switch style {
        case .primary:
            return 0
        case .secondary:
            return 1
        case .subtle:
            return 2
        }
    }
}
