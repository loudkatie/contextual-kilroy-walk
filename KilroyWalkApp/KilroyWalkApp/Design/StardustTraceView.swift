//
//  StardustTraceView.swift
//  KilroyWalkApp
//
//  Magic trace animation
//

import SwiftUI

struct StardustTraceView: View {

    @State private var animate = false
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.12, to: animate ? 0.92 : 0.12)
                .stroke(
                    LinearGradient(
                        colors: [
                            ContextualStyle.stardust.opacity(0.12),
                            ContextualStyle.stardust.opacity(0.6),
                            ContextualStyle.stardust.opacity(0.16)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 1.4,
                        lineCap: .round
                    )
                )
                .blur(radius: 1)

            SparkleRing()
                .opacity(0.7)
        }
        .rotationEffect(.degrees(-90))
        .rotationEffect(.degrees(spin ? 360 : 0))
        .animation(
            .easeOut(duration: ContextualStyle.traceDuration),
            value: animate
        )
        .animation(
            .linear(duration: 52).repeatForever(autoreverses: false),
            value: spin
        )
        .onAppear {
            animate = true
            spin = true
        }
    }
}

private struct SparkleRing: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                let radius = min(size.width, size.height) * 0.5
                let count = 120

                for i in 0..<count {
                    let t = Double(i) / Double(count - 1)
                    let angle = (0.12 + 0.80 * t) * 2.0 * Double.pi
                    let flicker = 0.35 + 0.65 * (0.5 + 0.5 * sin(time * 1.1 + Double(i)))
                    let sparkleRadius = radius + CGFloat(sin(Double(i)) * 1.2)
                    let x = center.x + CGFloat(cos(angle)) * sparkleRadius
                    let y = center.y + CGFloat(sin(angle)) * sparkleRadius
                    let size = CGFloat(0.6 + 1.4 * flicker)
                    let alpha = 0.24 * flicker
                    let rect = CGRect(x: x - size * 0.5, y: y - size * 0.5, width: size, height: size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                }
            }
        }
        .blendMode(.screen)
    }
}
