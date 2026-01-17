# Contextual Design + Build Status (handoff)

Last updated: 2026-01-17

## North star (what we're building)
- Contextual is a proactive ambient AI platform. No chat UI. User life comes first.
- Tink = personal, persistent, whisper‑voice agent born at first launch; loyal only to the user.
- Experience should feel like a fairy whisper: opalescent, pastel, light, snow‑globe motes, calm.
- Proactive nudges are haptic on watch + soft ASMR whispers; screen only when needed.

## Visual target
- Reference look is a photographic soap‑bubble orb (soft depth, iridescent film, strong rim glow).
- Wide‑tracked wordmark in very light graphite, small height, centered under the notch.
- Atmosphere is a subtle lavender fog with barely‑there glitter motes.

## Repo + app
- Repo root: `/Users/katiemacair-2025/04_Developer/contextual-hack`
- App target: `KilroyWalkApp/KilroyWalkApp.xcodeproj`
- Local Swift package: `ContextualCore` (models/services/connectors)

## Current state (what works)
- **Presence screen** is live with orb + halo + sparkles.
- **Splash** shows Tink “birth” (spark orbit -> ring -> orb).
- **ASMR audio** now uses preferred mp3s, with m4a fallback.
- **Centered layout** is fixed; orb/wordmark centered and safe‑area aware.
- **Demo tools**: long‑press wordmark opens demo sheet.

## Why it still looks “flat”
SwiftUI gradient layers can approximate the orb, but the reference orb is photographic with
realistic lensing/refraction. We can improve further only by:
- using a rendered orb image sequence (PNG/WebP) and subtle animation,
- or a Metal shader / SceneKit + environment map,
- or a pre‑composed layered asset (rim + film + bloom + highlight).

## Key files touched (design + motion)
- `KilroyWalkApp/KilroyWalkApp/App/ContextualPresenceScreen.swift`
  - Layout, orb sizing, motes/sparkles.
  - Wordmark safe‑area alignment and tracking.
- `KilroyWalkApp/KilroyWalkApp/Design/BreathingOrbView.swift`
  - Multi‑layer orb with bloom, iridescent film, rim glow, specular highlight.
- `KilroyWalkApp/KilroyWalkApp/Design/ContextualStyle.swift`
  - Palette, graphite, background gradient, motion timings, tracking.
- `KilroyWalkApp/KilroyWalkApp/Design/ContextualSplashView.swift`
  - Tink birth animation (spark orbit) + wordmark.
- `KilroyWalkApp/KilroyWalkApp/App/AppRootView.swift`
  - Splash -> presence transition.
- `KilroyWalkApp/KilroyWalkApp/Services/AudioWhisperService.swift`
  - Uses mp3 whispers first, fallback to m4a, then TTS.
- `KilroyWalkApp/KilroyWalkApp.xcodeproj/project.pbxproj`
  - Added mp3s to Resources.

## Audio files in use
Primary (preferred):
- `Resources/Audio/11_psst-welcome.mp3`
- `Resources/Audio/11_psst-somethings-here.mp3`
- `Resources/Audio/11_wanna-open.mp3`

Fallback:
- `Resources/Audio/psst_welcome_frontier.m4a`
- `Resources/Audio/psst_drop_here.m4a`
- `Resources/Audio/psst_want_to_open.m4a`

## Known issues / blockers
- **iPhone device run**: iOS 26.3 cannot mount with Xcode 26.2.
  - Need Xcode 26.3 (not published yet) or use simulator for now.
- **Orb photorealism**: SwiftUI alone still looks “flat.”

## Next steps (recommended)
1) **Orb photorealism via assets**
   - Create a high‑res orb PNG (or 3‑layer set: base + rim + highlight).
   - Use `Image` overlay with gentle breathing scale + opacity shimmer.
   - Optionally animate subtle hue shifts with `Canvas`/shader.

2) **Metal shader approach (best)**
   - Use Metal/SceneKit to render a refractive sphere with env map.
   - Composite it over the lavender gradient.

3) **Wordmark / glyph**
   - Current text tracking is expanded; still tweakable in `ContextualPresenceScreen.swift`.
   - If you want a custom glyph image instead of vector hex, add to Assets and swap.

4) **Sparkle ring**
   - If the ring should be visible in the main presence screen (like ref), increase the
     sparkle density + brightness in `StardustArc`.

## Design references (local)
- `/Users/katiemacair-2025/Desktop/HIDE/Contextual-Assets.zip`
  - `contextual-splash.png`, `contextual-splash2.png`, `contextual-motion-storyboards.png`
- Internal product doc:
  - `/Users/katiemacair-2025/Downloads/Internal_ Contextual Product Doc (Jan 26) (2).pdf`

## Summary of main intent for future Codex sessions
- Make the orb look photographic (not a flat gradient).
- Keep everything minimal, airy, and high‑trust.
- Tink is alive: breathing, whispering, subtle motion, no loud UI.
