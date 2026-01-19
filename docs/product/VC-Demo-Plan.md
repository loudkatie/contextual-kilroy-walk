# VC Demo Plan (Llama Lounge - This Week)

Last updated: 2026-01-17

## Goal
- Ship a believable, proactive Tink loop on iPhone with minimal cost.
- Demonstrate: place + identity + behavior -> whisper -> host card.

## Demo beats (Frontier Tower)
1. Arrival: welcome whisper + host card.
2. Coffee/quiet spot: contextual nudge.
3. Drop moment: permission-gated content.

## AI plan (budget ~$50)
- Use ChatGPT API with one thread per user.
- Use tool calling or JSON schema for strict response shape.
- Keep prompts short; send behavior deltas only.
- Demo server lives in `server/` with file-based memory.

## Scope cuts (keep it demo-safe)
- No full auth; use device ID for Contextual ID.
- Memory is a lightweight store (thread_id + last 20 events).
- No real partner connectors; stub data only.

## Success criteria
- Haptic + whisper plays reliably.
- No empty chat screens.
- Tink response feels personal and consistent across sessions.
