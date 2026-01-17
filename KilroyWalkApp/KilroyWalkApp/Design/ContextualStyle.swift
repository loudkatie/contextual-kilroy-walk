//
//  ContextualStyle.swift
//  KilroyWalkApp
//
//  Design system v0 — locked for initial build
//

import SwiftUI

enum ContextualStyle {

    // MARK: - Backgrounds

    /// Soft lavender fog used for most surfaces
    static let background = Color(
        red: 0.965,
        green: 0.945,
        blue: 0.985
    )

    static let backgroundTop = Color(
        red: 0.992,
        green: 0.982,
        blue: 0.998
    )

    static let backgroundMid = Color(
        red: 0.962,
        green: 0.944,
        blue: 0.988
    )

    static let backgroundBottom = Color(
        red: 0.926,
        green: 0.914,
        blue: 0.978
    )

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundMid, backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Dark graphite used sparingly (icons, contrast states)
    static let graphite = Color(
        red: 0.70,
        green: 0.70,
        blue: 0.78
    )

    // MARK: - Light & Stardust

    static let haloWhite = Color.white.opacity(0.90)

    static let stardust = Color(
        red: 0.995,
        green: 0.972,
        blue: 0.928
    ).opacity(0.92)

    // MARK: - Orb (iridescent anchors)

    static let orbLilac = Color(red: 0.92, green: 0.88, blue: 0.98)
    static let orbBlue   = Color(red: 0.86, green: 0.92, blue: 0.99)
    static let orbMint   = Color(red: 0.88, green: 0.98, blue: 0.96)
    static let orbPeach  = Color(red: 0.99, green: 0.92, blue: 0.90)
    static let orbHighlight = Color.white.opacity(0.86)
    static let orbEdge = Color.white.opacity(0.74)

    // MARK: - Typography

    /// We standardize size & tracking only. Font family stays system.
    static func wordmarkFont(size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }

    /// Wide, airy tracking — never shouty
    static let wordmarkTracking: CGFloat = 0.48

    // MARK: - Motion (v0 lock)

    /// Orb breathing duration (full inhale + exhale)
    static let breathingDuration: Double = 7.4

    /// Sparkle / trace animation duration
    static let traceDuration: Double = 2.4

    /// Global easing curve
    static let breatheEase: Animation = .easeInOut(duration: breathingDuration)
}
