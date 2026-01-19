# AI Integration + Stack Plan (v0 to v1)

Last updated: 2026-01-17

## Goals
- Proactive agent loop with no blank chat UI.
- Reliable triggers (location + identity + time + permissions).
- Lightweight memory that influences next actions.
- Clear separation between iOS demo shell and platform core.

## Proposed stack (minimal, evolvable)

### Client (iOS)
- KilroyWalkApp: presentation layer, haptics, audio, host cards, demo tools.
- ContextualCore (Swift package): agent lifecycle, memory, trigger engine, connector interfaces.
- Local MemoryStore persists preferences + permissions for v0 offline behavior.

### Platform services (server)
- Agent Orchestrator API
  - Receives context snapshots (location, time, identity, connector data).
  - Returns a "Moment" payload with whisper + host card.
- Memory Service
  - User-scoped long-term preferences.
  - Stores reactions (like/ignore/delay) and context tags.
- Connector Gateway
  - Normalizes partner data (calendar, ticketing, retail, etc).
  - Permissioned per user, scope-limited.

### AI layer
- Prompted agent policy with guardrails (no chat, proactive only).
- Agent memory retrieval (simple rules first, vector later).
- Output constrained to a strict schema for UI reliability.

## Phased delivery

### Phase 0 (now)
- Hard-coded Frontier Tower moments in ContextualCore.
- Manual triggers + demo log.
- Local MemoryStore update on like/ignore.

### Phase 0.5 (current)
- Local "AgentPlanner" stub now selects from pre-authored moments.
- Schema enforced via plan output: {momentId, title, whisperAudioId, primaryCTA, secondaryCTA}.

### Phase 1 (server-backed)
- Add a minimal API:
  - POST /context/snapshot -> returns Moment.
  - POST /memory/reaction -> store reaction.
- Backing store: Postgres + JSONB for moments + memory.
- Optional vector store for preference retrieval (when needed).

### Phase 2 (partner-ready)
- Connector auth flows (OAuth, token vault).
- Per-tenant rules, rate limits, and audit logs.
- Partner experience authoring tools (not in v0 demo).

## iOS integration points
- ContextualCore triggers call AgentPlanner (local or server).
- KilroyWalkApp shows host cards and plays whisper audio.
- All user responses update MemoryStore + server memory.

## Security + privacy (baseline)
- Minimum collection: context snapshots only when needed.
- User can pause Contextual at any time.
- Permission tokens required for partner content.
