import Foundation

public struct MomentAction: Identifiable, Hashable, Codable {
    public enum Kind: String, Codable {
        case openCard
        case openDrop
        case openURL
        case acknowledge
    }

    public enum Style: String, Codable {
        case primary
        case secondary
        case subtle
    }

    public let id: String
    public let title: String
    public let kind: Kind
    public let style: Style
    public let payload: String?
    public let iconName: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        kind: Kind = .openCard,
        style: Style = .primary,
        payload: String? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.style = style
        self.payload = payload
        self.iconName = iconName
    }
}

public struct Moment: Identifiable, Hashable, Codable {
    public enum Trigger: Hashable, Codable {
        case zoneEntry
        case poi(String)
        case manual(String)

        private enum CodingKeys: String, CodingKey {
            case kind
            case value
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(String.self, forKey: .kind)
            let value = try container.decodeIfPresent(String.self, forKey: .value)

            switch kind {
            case "zoneEntry":
                self = .zoneEntry
            case "poi":
                self = .poi(value ?? "")
            case "manual":
                self = .manual(value ?? "")
            default:
                self = .manual(value ?? kind)
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .zoneEntry:
                try container.encode("zoneEntry", forKey: .kind)
            case .poi(let poiID):
                try container.encode("poi", forKey: .kind)
                try container.encode(poiID, forKey: .value)
            case .manual(let manualID):
                try container.encode("manual", forKey: .kind)
                try container.encode(manualID, forKey: .value)
            }
        }
    }

    public let id: String
    public let title: String
    public let subtitle: String?
    public let whisperAudioKey: String?
    public let hostLine: String
    public let detail: String?
    public let actions: [MomentAction]
    public let requiresConsent: Bool
    public let gatingToken: String?
    public let trigger: Trigger
    public let manualTriggerID: String?
    public let priority: Int
    public let cooldownSeconds: TimeInterval
    public let metadata: [String: String]?

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        whisperAudioKey: String? = nil,
        hostLine: String,
        detail: String? = nil,
        actions: [MomentAction],
        requiresConsent: Bool = true,
        gatingToken: String? = nil,
        trigger: Trigger,
        manualTriggerID: String? = nil,
        priority: Int = 0,
        cooldownSeconds: TimeInterval = 60,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.whisperAudioKey = whisperAudioKey
        self.hostLine = hostLine
        self.detail = detail
        self.actions = actions
        self.requiresConsent = requiresConsent
        self.gatingToken = gatingToken
        self.trigger = trigger
        self.manualTriggerID = manualTriggerID
        self.priority = priority
        self.cooldownSeconds = cooldownSeconds
        self.metadata = metadata
    }
}
