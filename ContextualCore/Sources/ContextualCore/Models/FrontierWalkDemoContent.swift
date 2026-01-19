import Foundation

public enum FrontierWalkDemoContent {
    public static let frontierZone = ContextualZone(
        id: "frontier-walk-zone",
        displayName: "Frontier Tower",
        center: .init(latitude: 37.78975, longitude: -122.40055),
        radiusMeters: 260,
        pois: [
            .init(
                id: "frontier_arrival",
                name: "Frontier Tower Entrance",
                coordinate: .init(latitude: 37.78974, longitude: -122.40046),
                radiusMeters: 3.0,
                kind: .arrival,
                metadata: ["hint": "Market St doors", "floorBand": "FT-LOBBY"]
            ),
            .init(
                id: "frontier_lobby_desk",
                name: "Lobby Check-In Desk",
                coordinate: .init(latitude: 37.78977, longitude: -122.40051),
                radiusMeters: 1.2,
                kind: .custom,
                metadata: ["hint": "badge desk", "floorBand": "FT-LOBBY"]
            ),
            .init(
                id: "frontier_elevator_bank",
                name: "Elevator Bank",
                coordinate: .init(latitude: 37.78979, longitude: -122.40058),
                radiusMeters: 1.2,
                kind: .custom,
                metadata: ["hint": "left elevators", "floorBand": "FT-LOBBY"]
            ),
            .init(
                id: "frontier_coffee",
                name: "Steep + Brew Nook",
                coordinate: .init(latitude: 37.79063, longitude: -122.40182),
                radiusMeters: 2.5,
                kind: .coffee,
                metadata: ["hint": "quiet side street bench", "floorBand": "FT-2"]
            ),
            .init(
                id: "frontier_kitchen",
                name: "Member Kitchen",
                coordinate: .init(latitude: 37.78986, longitude: -122.40044),
                radiusMeters: 1.2,
                kind: .custom,
                metadata: ["hint": "espresso machine", "floorBand": "FT-5"]
            ),
            .init(
                id: "frontier_podcast",
                name: "Podcast Nook",
                coordinate: .init(latitude: 37.78988, longitude: -122.40062),
                radiusMeters: 1.2,
                kind: .custom,
                metadata: ["hint": "soundproof corner", "floorBand": "FT-5"]
            ),
            .init(
                id: "frontier_drop_corner",
                name: "Sky Lobby Drop",
                coordinate: .init(latitude: 37.79092, longitude: -122.3992),
                radiusMeters: 2.5,
                kind: .drop,
                metadata: ["hint": "follow the reflective fins", "floorBand": "FT-12"]
            ),
            .init(
                id: "frontier_rooftop",
                name: "Skyline View",
                coordinate: .init(latitude: 37.78971, longitude: -122.4007),
                radiusMeters: 1.2,
                kind: .custom,
                metadata: ["hint": "north corner", "floorBand": "FT-16"]
            )
        ],
        notes: "Hard-coded lat/long for Frontier Tower demo. Micro-radii are ~4 ft."
    )

    public static let awsLoftZone = ContextualZone(
        id: "aws-loft-zone",
        displayName: "AWS Loft (525 Market)",
        center: .init(latitude: 37.7905075, longitude: -122.3991580),
        radiusMeters: 160,
        pois: [
            .init(
                id: "aws_front_door",
                name: "AWS Loft Front Door",
                coordinate: .init(latitude: 37.79048, longitude: -122.39919),
                radiusMeters: 3.0,
                kind: .arrival,
                metadata: ["hint": "Market St entry", "floorBand": "AWS-1"]
            ),
            .init(
                id: "aws_lobby_checkin",
                name: "Building Lobby Check-In",
                coordinate: .init(latitude: 37.79053, longitude: -122.39914),
                radiusMeters: 1.2,
                kind: .custom,
                metadata: ["hint": "security desk", "floorBand": "AWS-1"]
            ),
            .init(
                id: "aws_elevator",
                name: "Elevator Bank",
                coordinate: .init(latitude: 37.79055, longitude: -122.3992),
                radiusMeters: 1.2,
                kind: .custom,
                metadata: ["hint": "right elevators", "floorBand": "AWS-1"]
            ),
            .init(
                id: "aws_loft_entry",
                name: "AWS Loft Entry",
                coordinate: .init(latitude: 37.7906, longitude: -122.39912),
                radiusMeters: 2.0,
                kind: .drop,
                metadata: ["hint": "loft doors", "floorBand": "AWS-2"]
            ),
            .init(
                id: "aws_stage",
                name: "Llama Lounge Stage",
                coordinate: .init(latitude: 37.79062, longitude: -122.39906),
                radiusMeters: 1.2,
                kind: .custom,
                metadata: ["hint": "demo stage", "floorBand": "AWS-2"]
            ),
            .init(
                id: "aws_window_lounge",
                name: "Window Lounge",
                coordinate: .init(latitude: 37.79057, longitude: -122.39901),
                radiusMeters: 1.2,
                kind: .coffee,
                metadata: ["hint": "sunset corner", "floorBand": "AWS-2"]
            )
        ],
        notes: "AWS Loft at 525 Market St. Loft floor is 2nd floor."
    )

    public static let frontierMoments: [Moment] = [
        Moment(
            id: "frontier.arrival",
            title: "Welcome to Frontier Tower",
            subtitle: "Market St entrance",
            whisperAudioKey: "psst_welcome_frontier",
            hostLine: "Tink: You are at Frontier. Want the quick orientation?",
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
            metadata: ["poi": "frontier_arrival", "floorBand": "FT-LOBBY"]
        ),
        Moment(
            id: "frontier.lobby",
            title: "Frontier check-in is ready",
            subtitle: "Lobby desk",
            whisperAudioKey: "psst_drop_here",
            hostLine: "Tink: I can prefill your badge. Want me to check you in?",
            detail: "One tap and the desk will know you are here.",
            actions: [
                MomentAction(
                    id: "lobby.checkin",
                    title: "Check me in",
                    kind: .openCard,
                    style: .primary,
                    payload: "frontier_checkin",
                    iconName: "person.badge.plus"
                ),
                MomentAction(
                    id: "lobby.skip",
                    title: "Later",
                    kind: .acknowledge,
                    style: .secondary
                )
            ],
            requiresConsent: true,
            gatingToken: "frontier",
            trigger: .poi("frontier_lobby_desk"),
            manualTriggerID: nil,
            priority: 70,
            cooldownSeconds: 240,
            metadata: ["poi": "frontier_lobby_desk", "floorBand": "FT-LOBBY"]
        ),
        Moment(
            id: "frontier.coffee",
            title: "Need a quiet nook?",
            subtitle: "Steep + Brew",
            whisperAudioKey: "psst_drop_here",
            hostLine: "Tink: There is a calm coffee perch nearby. Want the pin?",
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
                    title: "I am good",
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
            metadata: ["poi": "frontier_coffee", "floorBand": "FT-2"]
        ),
        Moment(
            id: "frontier.drop",
            title: "Frontier drop unlocked",
            subtitle: "Sky Lobby briefing",
            whisperAudioKey: "psst_want_to_open",
            hostLine: "Tink: Kilroy left a media drop upstairs. Want me to open it?",
            detail: "Requires the Arrival token. We will keep the link warm for 10 minutes after consent.",
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
                "drop_id": "kilroy.frontier.sky",
                "floorBand": "FT-12"
            ]
        ),
        Moment(
            id: "frontier.podcast",
            title: "Podcast studio is open",
            subtitle: "Floor 5",
            whisperAudioKey: "psst_want_to_open",
            hostLine: "Tink: The podcast nook is free for 20 minutes. Want me to hold it?",
            detail: "One tap reserves the quiet space.",
            actions: [
                MomentAction(
                    id: "podcast.reserve",
                    title: "Reserve it",
                    kind: .openCard,
                    style: .primary,
                    payload: "frontier_podcast_hold"
                ),
                MomentAction(
                    id: "podcast.skip",
                    title: "Not now",
                    kind: .acknowledge,
                    style: .secondary
                )
            ],
            requiresConsent: true,
            gatingToken: "frontier",
            trigger: .poi("frontier_podcast"),
            manualTriggerID: nil,
            priority: 60,
            cooldownSeconds: 300,
            metadata: ["poi": "frontier_podcast", "floorBand": "FT-5"]
        ),
        Moment(
            id: "frontier.skyline",
            title: "Skyline easter egg",
            subtitle: "Top floor",
            whisperAudioKey: "psst_want_to_open",
            hostLine: "Tink: If you look up, the skyline is insane right now.",
            detail: "Tink only speaks here if the sunset is glowing.",
            actions: [
                MomentAction(
                    id: "skyline.look",
                    title: "I see it",
                    kind: .acknowledge,
                    style: .primary
                ),
                MomentAction(
                    id: "skyline.skip",
                    title: "Later",
                    kind: .acknowledge,
                    style: .subtle
                )
            ],
            requiresConsent: true,
            gatingToken: nil,
            trigger: .poi("frontier_rooftop"),
            manualTriggerID: nil,
            priority: 50,
            cooldownSeconds: 300,
            metadata: ["poi": "frontier_rooftop", "floorBand": "FT-16"]
        )
    ]

    public static let awsLoftMoments: [Moment] = [
        Moment(
            id: "aws.arrival",
            title: "Welcome to Llama Lounge",
            subtitle: "AWS Loft entrance",
            whisperAudioKey: "psst_welcome_frontier",
            hostLine: "Tink: You are at the AWS Loft. Want the fastest check-in path?",
            detail: "I can steer you past the lobby queue if your Luma token is ready.",
            actions: [
                MomentAction(
                    id: "aws.arrival.checkin",
                    title: "Get me in",
                    kind: .openCard,
                    style: .primary,
                    payload: "aws_loft_checkin"
                ),
                MomentAction(
                    id: "aws.arrival.skip",
                    title: "Not yet",
                    kind: .acknowledge,
                    style: .secondary
                )
            ],
            requiresConsent: true,
            gatingToken: nil,
            trigger: .poi("aws_front_door"),
            manualTriggerID: "moment.arrival",
            priority: 100,
            cooldownSeconds: 120,
            metadata: ["poi": "aws_front_door", "floorBand": "AWS-1"]
        ),
        Moment(
            id: "aws.lobby",
            title: "Lobby check-in ready",
            subtitle: "525 Market",
            whisperAudioKey: "psst_drop_here",
            hostLine: "Tink: I can hand the desk your Luma pass. Want me to?",
            detail: "Requires LUMA token for the event.",
            actions: [
                MomentAction(
                    id: "aws.lobby.send",
                    title: "Send pass",
                    kind: .openCard,
                    style: .primary,
                    payload: "luma_pass"
                ),
                MomentAction(
                    id: "aws.lobby.skip",
                    title: "Later",
                    kind: .acknowledge,
                    style: .secondary
                )
            ],
            requiresConsent: true,
            gatingToken: "luma",
            trigger: .poi("aws_lobby_checkin"),
            manualTriggerID: "moment.coffee",
            priority: 85,
            cooldownSeconds: 180,
            metadata: ["poi": "aws_lobby_checkin", "floorBand": "AWS-1"]
        ),
        Moment(
            id: "aws.loft",
            title: "Loft floor unlocked",
            subtitle: "2nd floor",
            whisperAudioKey: "psst_want_to_open",
            hostLine: "Tink: The Loft is live. Want a quick map of the vibe?",
            detail: "Requires AMAZON token for member access.",
            actions: [
                MomentAction(
                    id: "aws.loft.map",
                    title: "Show me",
                    kind: .openCard,
                    style: .primary,
                    payload: "aws_loft_map"
                ),
                MomentAction(
                    id: "aws.loft.skip",
                    title: "Not now",
                    kind: .acknowledge,
                    style: .secondary
                )
            ],
            requiresConsent: true,
            gatingToken: "amazon",
            trigger: .poi("aws_loft_entry"),
            manualTriggerID: "moment.drop",
            priority: 90,
            cooldownSeconds: 240,
            metadata: ["poi": "aws_loft_entry", "floorBand": "AWS-2"]
        ),
        Moment(
            id: "aws.stage",
            title: "Stage moment",
            subtitle: "Llama Lounge",
            whisperAudioKey: "psst_want_to_open",
            hostLine: "Tink: The stage is open. Want to peek at the next demo slot?",
            detail: "Only surfaced when you are near the stage.",
            actions: [
                MomentAction(
                    id: "aws.stage.peek",
                    title: "Peek",
                    kind: .openCard,
                    style: .primary,
                    payload: "aws_stage_lineup"
                ),
                MomentAction(
                    id: "aws.stage.skip",
                    title: "Later",
                    kind: .acknowledge,
                    style: .secondary
                )
            ],
            requiresConsent: true,
            gatingToken: nil,
            trigger: .poi("aws_stage"),
            manualTriggerID: nil,
            priority: 60,
            cooldownSeconds: 180,
            metadata: ["poi": "aws_stage", "floorBand": "AWS-2"]
        ),
        Moment(
            id: "aws.window",
            title: "Window lounge easter egg",
            subtitle: "Loft corner",
            whisperAudioKey: "psst_drop_here",
            hostLine: "Tink: The window lounge is open and quiet if you need a reset.",
            detail: "A small calm zone away from the crowd.",
            actions: [
                MomentAction(
                    id: "aws.window.mark",
                    title: "Mark it",
                    kind: .openCard,
                    style: .primary,
                    payload: "aws_window_lounge"
                ),
                MomentAction(
                    id: "aws.window.skip",
                    title: "Skip",
                    kind: .acknowledge,
                    style: .subtle
                )
            ],
            requiresConsent: true,
            gatingToken: nil,
            trigger: .poi("aws_window_lounge"),
            manualTriggerID: nil,
            priority: 50,
            cooldownSeconds: 180,
            metadata: ["poi": "aws_window_lounge", "floorBand": "AWS-2"]
        )
    ]

    public static let venues: [DemoVenue] = [
        DemoVenue(
            id: "frontier",
            name: "Frontier Tower",
            zone: frontierZone,
            moments: frontierMoments,
            notes: "Members' tower, 16 floors, dense easter eggs."
        ),
        DemoVenue(
            id: "aws-loft",
            name: "AWS Loft (525 Market, Floor 2)",
            zone: awsLoftZone,
            moments: awsLoftMoments,
            notes: "Llama Lounge demo space."
        )
    ]

    public static let zone = frontierZone
    public static let orderedMoments = frontierMoments

    public static func venue(id: String) -> DemoVenue? {
        venues.first { $0.id == id }
    }
}
