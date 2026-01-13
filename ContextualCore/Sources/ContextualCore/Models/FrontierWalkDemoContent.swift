import Foundation

public enum FrontierWalkDemoContent {
    public static let zone = ContextualZone(
        id: "frontier-walk-zone",
        displayName: "Frontier Tower Blocks",
        center: .init(latitude: 37.78975, longitude: -122.40055),
        radiusMeters: 260,
        pois: [
            .init(
                id: "frontier_arrival",
                name: "Frontier Tower Entrance",
                coordinate: .init(latitude: 37.78974, longitude: -122.40046),
                radiusMeters: 65,
                kind: .arrival,
                metadata: ["hint": "Market St doors"]
            ),
            .init(
                id: "frontier_coffee",
                name: "Steep + Brew Nook",
                coordinate: .init(latitude: 37.79063, longitude: -122.40182),
                radiusMeters: 55,
                kind: .coffee,
                metadata: ["hint": "quiet side street bench"]
            ),
            .init(
                id: "frontier_drop_corner",
                name: "Sky Lobby Drop",
                coordinate: .init(latitude: 37.79092, longitude: -122.3992),
                radiusMeters: 80,
                kind: .drop,
                metadata: ["hint": "follow the reflective fins"]
            )
        ],
        notes: "Hard-coded lat/long for the Frontier Tower walk demo. Coordinates are approximate for rehearsals."
    )

    public static let orderedMoments: [Moment] = [
        Moment(
            id: "frontier.arrival",
            title: "Welcome to Frontier Tower",
            subtitle: "Market St entrance",
            whisperAudioKey: "psst_welcome_frontier",
            hostLine: "Jeeves: You’re on Frontier’s sidewalk. Want the quick orientation?",
            detail: "Wave hello, grab your badge, and the lobby guide will flag the Kilroy liaison.",
            actions: [
                MomentAction(
                    id: "arrival.start",
                    title: "Start walkthrough",
                    kind: .openCard,
                    style: .primary,
                    payload: "arrival_brief",
                    iconName: "figure.walk.motion"
                ),
                MomentAction(
                    id: "arrival.skip",
                    title: "Not now",
                    kind: .acknowledge,
                    style: .secondary,
                    iconName: "clock"
                )
            ],
            requiresConsent: true,
            gatingToken: nil,
            trigger: .poi("frontier_arrival"),
            manualTriggerID: "moment.arrival",
            priority: 100,
            cooldownSeconds: 120,
            metadata: ["poi": "frontier_arrival"]
        ),
        Moment(
            id: "frontier.coffee",
            title: "Need a quiet nook?",
            subtitle: "Steep + Brew",
            whisperAudioKey: "psst_drop_here",
            hostLine: "Jeeves: There's a calm coffee perch half a block up. Want the pin?",
            detail: "We marked a bench tucked away from Market Street wind. Great for a prep reset.",
            actions: [
                MomentAction(
                    id: "coffee.navigate",
                    title: "Guide me there",
                    kind: .openURL,
                    style: .primary,
                    payload: "maps://?ll=37.79063,-122.40182",
                    iconName: "mappin.and.ellipse"
                ),
                MomentAction(
                    id: "coffee.skip",
                    title: "I’m good",
                    kind: .acknowledge,
                    style: .secondary
                )
            ],
            requiresConsent: true,
            gatingToken: nil,
            trigger: .poi("frontier_coffee"),
            manualTriggerID: "moment.coffee",
            priority: 80,
            cooldownSeconds: 180,
            metadata: ["poi": "frontier_coffee"]
        ),
        Moment(
            id: "frontier.drop",
            title: "Frontier drop unlocked",
            subtitle: "Sky Lobby briefing",
            whisperAudioKey: "psst_want_to_open",
            hostLine: "Jeeves: Kilroy left a media drop upstairs. Want me to open it?",
            detail: "Requires the Arrival token. We’ll keep the link warm for 10 minutes after consent.",
            actions: [
                MomentAction(
                    id: "drop.open",
                    title: "Open drop",
                    kind: .openDrop,
                    style: .primary,
                    payload: "kilroy.frontier.sky"
                ),
                MomentAction(
                    id: "drop.later",
                    title: "Save for later",
                    kind: .acknowledge,
                    style: .subtle
                )
            ],
            requiresConsent: true,
            gatingToken: "arrival",
            trigger: .poi("frontier_drop_corner"),
            manualTriggerID: "moment.drop",
            priority: 90,
            cooldownSeconds: 240,
            metadata: [
                "poi": "frontier_drop_corner",
                "drop_id": "kilroy.frontier.sky"
            ]
        )
    ]
}
