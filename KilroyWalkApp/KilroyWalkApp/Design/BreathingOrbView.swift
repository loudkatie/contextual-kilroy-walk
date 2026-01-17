//
//  BreathingOrbView.swift
//  KilroyWalkApp
//
//  The living orb
//

import SwiftUI

struct BreathingOrbView: View {

    @State private var isBreathing = false

    var body: some View {
        ZStack {

            // Core orb gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            ContextualStyle.orbLilac,
                            ContextualStyle.orbBlue,
                            ContextualStyle.orbMint,
                            ContextualStyle.orbPeach
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isBreathing ? 1.03 : 0.97)
                .blur(radius: 0.35)
                .animation(
                    ContextualStyle.breatheEase.repeatForever(autoreverses: true),
                    value: isBreathing
                )

            // Depth glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 210
                    )
                )
                .blendMode(.screen)

            // Inner light bloom
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ContextualStyle.orbHighlight,
                            Color.white.opacity(0.0)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 160
                    )
                )
                .blendMode(.screen)

            // Soft spectral sheen
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.60),
                            Color.white.opacity(0.10),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 8,
                        endRadius: 190
                    )
                )
                .blendMode(.screen)
                .opacity(0.88)

            // Iridescent film
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            ContextualStyle.orbLilac.opacity(0.35),
                            ContextualStyle.orbBlue.opacity(0.28),
                            ContextualStyle.orbMint.opacity(0.32),
                            ContextualStyle.orbPeach.opacity(0.30),
                            ContextualStyle.orbLilac.opacity(0.35)
                        ],
                        center: .center
                    )
                )
                .blendMode(.screen)
                .opacity(0.42)

            // Specular highlight
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.65),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(0.65)
                .rotationEffect(.degrees(-18))
                .offset(x: -24, y: -28)
                .blur(radius: 1.6)
                .blendMode(.screen)

            // Lower glow lift
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.26),
                            Color.white.opacity(0.0)
                        ],
                        center: .bottom,
                        startRadius: 12,
                        endRadius: 160
                    )
                )
                .blendMode(.screen)

            // Halo edge
            Circle()
                .stroke(
                    ContextualStyle.orbEdge,
                    lineWidth: 3.4
                )
                .blur(radius: 2.6)
                .scaleEffect(isBreathing ? 1.04 : 0.98)
                .animation(
                    ContextualStyle.breatheEase.repeatForever(autoreverses: true),
                    value: isBreathing
                )

            // Outer rim shimmer
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.20),
                            Color.white.opacity(0.65),
                            Color.white.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .blur(radius: 2.8)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 22, x: 0, y: 10)
        .onAppear {
            isBreathing = true
        }
    }
}
