# Contextual Design Notes (Kilroy Walk)

This file captures the visual intent for the Contextual presence screen so the
project can resume cleanly between sessions.

## North star
- Feel like a guardian presence, not an app or chat UI.
- Fullscreen, quiet atmosphere with a single orb and a soft wordmark.
- Slow human breathing, subtle stardust, no attention-seeking motion.

## Core UI (iOS)
- Top wordmark: "CONTEXTUAL" with wide tracking and light graphite tone.
- Center orb: opalescent / iridescent bubble with slow breathing.
- Stardust arc: faint sparkle ring around the orb, slowly rotating.
- Copy line: "I'm listening, so you don't have to..." in graphite.

## Colors
- Background: lavender fog gradient, slightly warmer at top.
- Orb: lilac + blue + mint + peach mix with soft white highlights.
- Text: graphite gray (soft, not black).

## Demo controls
- Demo controls and Demo Log are still required.
- Current access: long-press the wordmark to open the tools sheet.

## Implementation pointers
- Presence UI is `ContextualPresenceScreen`.
- Palette and motion constants are in `ContextualStyle`.
- Orb layers in `BreathingOrbView`.
- Stardust arc + field live in `ContextualPresenceScreen`.
