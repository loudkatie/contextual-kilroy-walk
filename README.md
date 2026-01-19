# Contextual — Kilroy Walk

Codex agent instructions live in `AGENTS.md`. This README tracks the
Frontier Walk demo work so the founders, Thomas, and any drop-in helpers
can stay aligned.

## Product anchor

- Contextual is a proactive spatial AI platform. The user never faces a blank chat box.
- Tink is the personal agent, born at account creation, always championing the user.
- Demo playground: Frontier Tower, 995 Market St, SF (16 floors, altimeter for floor).

## Frontier Walk v0 focus

- **Apple-first, iOS-only** build that feels intentional and ambient —
  no generic chat surfaces.
- Demo is a 2–3 block walk around Frontier Tower in SoMa. The goal is to
  show proactive “Jeeves” host cards that feel magical because they are
  simple and reliable.
- Secondary demo venue: AWS Loft (525 Market, Floor 2) for Llama Lounge.
- Core beats: haptic ping → whisper audio (pre-recorded if possible) →
  guided host card with big button choices. No empty chat screens.
- Moments for this iteration:
  1. Arrival — “Welcome to Frontier Tower”
  2. Coffee / Quiet Spot — friendly nearby interstitial
  3. Drop Moment — gated media surfaced via KilroyDrops

## Docs index

- Product + founder notes: `docs/product/Founders-Notes.md`.
- AI integration + stack plan: `docs/product/AI-Stack-Plan.md`.
- VC demo plan: `docs/product/VC-Demo-Plan.md`.
- Visual north star + palette notes: `docs/design/DesignNotes.md`.
- Build status + known issues: `docs/status/Contextual-Status.md`.
- Reference product doc PDF: `docs/references/Contextual Product Doc (13 Jan 2026).pdf`.
- Internal product doc (Jan 26): `docs/references/Internal_ Contextual Product Doc (Jan 26) (3).pdf`.

## AI demo server

- Local server lives in `server/`.
- Start with: `OPENAI_API_KEY=sk-... node server/index.js`.
- Set the URL in Demo Controls (Agent section) to enable remote planning.

## Design continuity

- Presence UI entrypoint: `KilroyWalkApp/KilroyWalkApp/App/ContextualPresenceScreen.swift`.
- Demo tools: long-press the wordmark to open the controls + demo log sheet.
- Demo controls now include venue selection + POI teleport.

## Reliability + controls

- Always keep manual fallbacks during testing: “Trigger Arrival”,
  “Trigger Moment 1/2/3”, “Set Zone”, “Test Whisper”.
- A Demo Log must record every routing decision (“why triggered / why not”).
- Audio needs to route through the current output (speaker, Bluetooth,
  headphones) without surprises.
- Watch haptics are preferred, but ship an iPhone fallback button flow
  if the watch path becomes risky.

## Branch workflow (Jan 2026)

1. Tag hack-weekend snapshot: `git tag hack-weekend-jan2026 &&
   git push origin hack-weekend-jan2026`.
2. Active work happens on `frontier-walk-v0`
   (`git checkout -b frontier-walk-v0` then `git push -u origin frontier-walk-v0`).
3. Commit milestones stay small and ordered:
   1. `Branch: frontier-walk-v0 scaffolding + docs`
   2. `Add ContextualZone + Moment model`
   3. `Add TriggerEngine + manual triggers`
   4. `Add consent gating + demo log improvements`
   5. `Add host card UI (no empty chat)`
   6. `Add watch haptics + fallback`
   7. `Polish audio whispers + route display`
   8. `Update README demo script`

Keep the simulator build green (`KilroyWalkApp.xcodeproj`, scheme
`KilroyWalkApp`, destination `iPhone 17`). Ask loudly before destructive
commands or dependency upgrades.

## Latest updates
- Multi-venue zones with dense micro-POIs (Frontier Tower + AWS Loft).
- Floor-band gating for vertical spaces.
- Remote AI planner option with local fallback.
