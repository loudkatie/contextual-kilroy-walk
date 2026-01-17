//
//  ContextualSplashView.swift
//  KilroyWalkApp
//
//  Splash experience
//

import SwiftUI

struct ContextualSplashView: View {
    var onComplete: (() -> Void)? = nil

    @State private var phase: Double = 0.0
    @State private var revealOrb = false
    @State private var revealTrace = false
    @State private var revealWordmark = false

    var body: some View {
        ZStack {
            ContextualStyle.backgroundGradient
                .ignoresSafeArea()

            SoftMotesField(intensity: 0.35)
                .blendMode(.screen)
                .opacity(0.55)

            VStack(spacing: 56) {
                Text("CONTEXTUAL")
                    .font(ContextualStyle.wordmarkFont(size: 18))
                    .tracking(ContextualStyle.wordmarkTracking)
                    .foregroundStyle(ContextualStyle.graphite.opacity(0.52))
                    .opacity(revealWordmark ? 1.0 : 0.0)

                ZStack {
                    TinkBirthOrbit(phase: phase)
                        .frame(width: 300, height: 300)

                    StardustTraceView()
                        .frame(width: 300, height: 300)
                        .opacity(revealTrace ? 0.7 : 0.0)

                    BreathingOrbView()
                        .frame(width: 270, height: 270)
                        .opacity(revealOrb ? 1.0 : 0.0)
                        .scaleEffect(revealOrb ? 1.0 : 0.92)
                }
            }
        }
        .onAppear {
            revealWordmark = true
            withAnimation(.easeInOut(duration: 4.2)) {
                phase = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    revealTrace = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    revealOrb = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.6) {
                onComplete?()
            }
        }
    }
}

private struct TinkBirthOrbit: View {
    let phase: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                let minRadius = min(size.width, size.height) * 0.08
                let maxRadius = min(size.width, size.height) * 0.46
                let eased = phase * phase * (3 - 2 * phase)
                let radius = minRadius + (maxRadius - minRadius) * eased
                let speed = 0.6 + 2.6 * phase
                let angle = time * speed * 2.0 * Double.pi
                let wobble = 0.12 * sin(time * 1.8) + 0.08 * cos(time * 2.4)
                let orbitRadius = radius * (1.0 + wobble * 0.2)

                for i in 0..<18 {
                    let offset = Double(i) * 0.12
                    let sparkleAngle = angle - offset
                    let sparkleRadius = orbitRadius - CGFloat(i) * 0.9
                    let x = center.x + CGFloat(cos(sparkleAngle)) * sparkleRadius
                    let y = center.y + CGFloat(sin(sparkleAngle)) * sparkleRadius
                    let size = CGFloat(2.6 - Double(i) * 0.08) * (0.6 + 0.6 * phase)
                    let alpha = max(0.05, 0.28 - Double(i) * 0.012) * (0.5 + 0.6 * phase)
                    let rect = CGRect(x: x - size * 0.5, y: y - size * 0.5, width: size, height: size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                }
            }
        }
        .blendMode(.screen)
    }
}

private struct SoftMotesField: View {
    let intensity: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let count = Int(50 * intensity)
                for i in 0..<count {
                    let seed = Double(i) * 21.7
                    let baseX = CGFloat((seed.truncatingRemainder(dividingBy: 997)) / 997) * size.width
                    let baseY = CGFloat((seed.truncatingRemainder(dividingBy: 991)) / 991) * size.height
                    let driftX = CGFloat(sin(time * 0.08 + seed) * 10)
                    let driftY = CGFloat(cos(time * 0.06 + seed) * 12)
                    let radius = CGFloat(6 + (seed.truncatingRemainder(dividingBy: 9)))
                    let alpha = 0.06 + 0.12 * (0.5 + 0.5 * sin(time * 0.4 + seed))
                    let rect = CGRect(
                        x: baseX + driftX - radius * 0.5,
                        y: baseY + driftY - radius * 0.5,
                        width: radius,
                        height: radius
                    )
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                }
            }
        }
    }
}
