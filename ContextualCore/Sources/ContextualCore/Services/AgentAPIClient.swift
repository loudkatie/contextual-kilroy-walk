import Foundation

public struct AgentPlanRequest: Codable {
    public let contextualID: String
    public let context: Context
    public let memory: MemoryStore.Snapshot
    public let recentEvents: [AgentEvent]
    public let manualID: String?
    public let timestamp: Date

    public init(
        contextualID: String,
        context: Context,
        memory: MemoryStore.Snapshot,
        recentEvents: [AgentEvent],
        manualID: String? = nil,
        timestamp: Date = Date()
    ) {
        self.contextualID = contextualID
        self.context = context
        self.memory = memory
        self.recentEvents = recentEvents
        self.manualID = manualID
        self.timestamp = timestamp
    }
}

public struct AgentPlanResponse: Codable {
    public let status: String
    public let explanation: String
    public let moment: Moment?
    public let plan: AgentPlan?
    public let eligibility: Bool?
    public let consentState: ConsentState?

    public init(
        status: String,
        explanation: String,
        moment: Moment?,
        plan: AgentPlan?,
        eligibility: Bool?,
        consentState: ConsentState?
    ) {
        self.status = status
        self.explanation = explanation
        self.moment = moment
        self.plan = plan
        self.eligibility = eligibility
        self.consentState = consentState
    }
}

public final class AgentAPIClient {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared) {
        self.session = session
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func plan(
        request: AgentPlanRequest,
        baseURL: URL
    ) async throws -> AgentPlanResponse {
        let url = baseURL.appendingPathComponent("agent/plan")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "AgentAPIClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad response: \(body)"])
        }
        return try decoder.decode(AgentPlanResponse.self, from: data)
    }
}
