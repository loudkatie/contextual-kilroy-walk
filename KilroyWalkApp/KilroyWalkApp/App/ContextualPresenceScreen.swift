//
//  ContextualPresenceScreen.swift
//  KilroyWalkApp
//
//  Updated presence experience
//

import SwiftUI
import ContextualCore

struct ContextualPresenceScreen: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var breathing = false
    @State private var haloPulse = false
    @State private var arcSpin = false
    @State private var showToolsSheet = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let safeTop = geo.safeAreaInsets.top
            let orbDiameter = min(size.width, size.height) * 0.70
            let orbOffsetY = size.height * 0.0
            let wordmarkSize = max(16, min(21, size.width * 0.05))

            ZStack {
                AtmosphericBackground()

                SoftMotesField(intensity: 0.18)
                    .blendMode(.screen)
                    .opacity(0.22)

                StardustField(intensity: 0.18)
                    .blendMode(.screen)
                    .opacity(0.22)

                VStack(spacing: 0) {
                    WordmarkHeader(fontSize: wordmarkSize) {
                        showToolsSheet = true
                    }
                    .padding(.top, safeTop + size.height * 0.028)
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer()

                    ZStack {
                        OrbGlow()
                            .frame(width: orbDiameter * 1.6, height: orbDiameter * 1.6)
                            .offset(y: orbDiameter * 0.08)

                        ListeningHalo()
                            .frame(width: orbDiameter * 1.18, height: orbDiameter * 1.18)
                            .opacity(0.35)
                            .scaleEffect(haloPulse ? 1.02 : 0.985)
                            .animation(.easeInOut(duration: 4.6).repeatForever(autoreverses: true), value: haloPulse)

                        StardustArc()
                            .frame(width: orbDiameter * 1.28, height: orbDiameter * 1.28)
                            .rotationEffect(.degrees(arcSpin ? 360 : 0))
                            .animation(.linear(duration: 52).repeatForever(autoreverses: false), value: arcSpin)

                        BreathingOrbView()
                            .frame(width: orbDiameter, height: orbDiameter)
                            .scaleEffect(breathing ? 1.045 : 0.965)
                            .animation(.easeInOut(duration: 7.6).repeatForever(autoreverses: true), value: breathing)
                    }
                    .offset(y: orbOffsetY)
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer()

                    if let moment = viewModel.activeMoment {
                        PresenceMomentCard(moment: moment) { action in
                            viewModel.handleAction(action, for: moment)
                        }
                        .padding(.bottom, size.height * 0.045)
                        .padding(.horizontal, 24)
                    } else {
                        Text("I'm listening, so you don't have to...")
                            .font(.system(size: 15, weight: .light, design: .default))
                            .tracking(0.24)
                            .foregroundStyle(ContextualStyle.graphite.opacity(0.7))
                            .padding(.bottom, size.height * 0.06)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(width: size.width, height: size.height, alignment: .top)
            }
            .frame(width: size.width, height: size.height, alignment: .center)
            .ignoresSafeArea()
            .onAppear {
                breathing = true
                haloPulse = true
                arcSpin = true
            }
            .sheet(isPresented: $showToolsSheet) {
                DemoToolsSheet()
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - Wordmark

private struct WordmarkHeader: View {
    let fontSize: CGFloat
    let onLongPress: () -> Void

    var body: some View {
        let tracking = fontSize * 0.58

        HStack(spacing: 10) {
            HexGlyph()
                .stroke(
                    LinearGradient(
                        colors: [
                            ContextualStyle.graphite.opacity(0.32),
                            ContextualStyle.graphite.opacity(0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: fontSize * 0.50, height: fontSize * 0.50)

            Text("CONTEXTUAL")
                .font(.system(size: fontSize, weight: .light, design: .default))
                .tracking(tracking)
                .foregroundStyle(ContextualStyle.graphite.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 1.0, perform: onLongPress)
    }
}

private struct HexGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        var path = Path()

        for idx in 0..<6 {
            let angle = (Double(idx) * 60.0 - 30.0) * Double.pi / 180.0
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if idx == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Atmosphere

private struct AtmosphericBackground: View {
    var body: some View {
        ZStack {
            ContextualStyle.backgroundGradient

            RadialGradient(
                colors: [
                    Color.white.opacity(0.55),
                    Color.white.opacity(0.0)
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .opacity(0.6)

            SoftClouds()
                .opacity(0.6)
        }
        .ignoresSafeArea()
    }
}

private struct SoftClouds: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.addFilter(.blur(radius: 60))
            let blobs: [(CGPoint, CGFloat, Color)] = [
                (CGPoint(x: size.width * 0.22, y: size.height * 0.20), 220, ContextualStyle.backgroundTop.opacity(0.65)),
                (CGPoint(x: size.width * 0.82, y: size.height * 0.18), 180, Color(red: 0.98, green: 0.94, blue: 0.99).opacity(0.38)),
                (CGPoint(x: size.width * 0.78, y: size.height * 0.72), 260, Color(red: 0.92, green: 0.95, blue: 0.99).opacity(0.35)),
                (CGPoint(x: size.width * 0.20, y: size.height * 0.70), 200, Color(red: 0.96, green: 0.92, blue: 0.98).opacity(0.40))
            ]

            for blob in blobs {
                let rect = CGRect(
                    x: blob.0.x - blob.1 * 0.5,
                    y: blob.0.y - blob.1 * 0.5,
                    width: blob.1,
                    height: blob.1
                )
                ctx.fill(Path(ellipseIn: rect), with: .color(blob.2))
            }
        }
    }
}

private struct OrbGlow: View {
    var body: some View {
        RadialGradient(
            colors: [
                Color.white.opacity(0.65),
                Color.white.opacity(0.18),
                Color.clear
            ],
            center: .center,
            startRadius: 10,
            endRadius: 260
        )
        .blur(radius: 2)
    }
}

private struct StardustField: View {
    let intensity: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let count = Int(180 * intensity)
                for i in 0..<count {
                    let seed = Double(i) * 12.73
                    let x = CGFloat((seed.truncatingRemainder(dividingBy: 997)) / 997) * size.width
                    let y = CGFloat((seed.truncatingRemainder(dividingBy: 991)) / 991) * size.height
                    let twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(time * 0.8 + seed))
                    let radius = CGFloat(0.6 + 1.4 * twinkle)
                    let alpha = 0.12 * twinkle
                    let rect = CGRect(x: x, y: y, width: radius, height: radius)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                }
            }
        }
    }
}

private struct SoftMotesField: View {
    let intensity: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let count = Int(36 * intensity)
                for i in 0..<count {
                    let seed = Double(i) * 31.2
                    let baseX = CGFloat((seed.truncatingRemainder(dividingBy: 941)) / 941) * size.width
                    let baseY = CGFloat((seed.truncatingRemainder(dividingBy: 983)) / 983) * size.height
                    let driftX = CGFloat(sin(time * 0.06 + seed) * 14)
                    let driftY = CGFloat(cos(time * 0.05 + seed) * 12)
                    let radius = CGFloat(8 + (seed.truncatingRemainder(dividingBy: 12)))
                    let shimmer = 0.08 + 0.12 * (0.5 + 0.5 * sin(time * 0.4 + seed))
                    let rect = CGRect(
                        x: baseX + driftX - radius * 0.5,
                        y: baseY + driftY - radius * 0.5,
                        width: radius,
                        height: radius
                    )
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(shimmer)))
                }
            }
        }
    }
}

// MARK: - Orb Cluster

private struct ListeningHalo: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.30),
                            Color.white.opacity(0.06)
                        ],
                        center: .center
                    ),
                    lineWidth: 2.0
                )
                .blur(radius: 0.5)

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 9)
                .blur(radius: 9)
                .opacity(0.55)
        }
    }
}

private struct StardustArc: View {
    private let startFraction = 0.12
    private let endFraction = 0.92

    var body: some View {
        ZStack {
            Circle()
                .trim(from: startFraction, to: endFraction)
                .stroke(
                    LinearGradient(
                        colors: [
                            ContextualStyle.stardust.opacity(0.08),
                            Color.white.opacity(0.65),
                            ContextualStyle.stardust.opacity(0.22)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
                )
                .blur(radius: 0.7)

            SparkleRing(startFraction: startFraction, endFraction: endFraction)
            SparkleRing(startFraction: startFraction + 0.03, endFraction: endFraction - 0.03)
                .opacity(0.45)
        }
        .rotationEffect(.degrees(-90))
    }
}

private struct SparkleRing: View {
    let startFraction: Double
    let endFraction: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                let radius = min(size.width, size.height) * 0.5
                let count = 150

                for i in 0..<count {
                    let t = Double(i) / Double(count - 1)
                    let angle = (startFraction + (endFraction - startFraction) * t) * 2.0 * Double.pi
                    let flicker = 0.35 + 0.65 * (0.5 + 0.5 * sin(time * 1.2 + Double(i)))
                    let sparkleRadius = radius + CGFloat(sin(Double(i)) * 1.2)
                    let x = center.x + CGFloat(cos(angle)) * sparkleRadius
                    let y = center.y + CGFloat(sin(angle)) * sparkleRadius
                    let size = CGFloat(0.7 + 1.6 * flicker)
                    let alpha = 0.32 * flicker
                    let rect = CGRect(x: x - size * 0.5, y: y - size * 0.5, width: size, height: size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                }
            }
        }
        .blendMode(.screen)
    }
}

// MARK: - Moment Card

private struct PresenceMomentCard: View {
    let moment: Moment
    let actionHandler: (MomentAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(moment.title)
                .font(.headline)
                .foregroundStyle(ContextualStyle.graphite)
            Text(moment.hostLine)
                .font(.subheadline)
                .foregroundStyle(ContextualStyle.graphite.opacity(0.7))
            if let detail = moment.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ContextualStyle.graphite.opacity(0.6))
            }
            if let action = moment.actions.first {
                Button(action.title) {
                    actionHandler(action)
                }
                .buttonStyle(.borderedProminent)
                .tint(ContextualStyle.graphite.opacity(0.2))
            }
        }
        .padding(16)
        .frame(maxWidth: 320)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

// MARK: - Tools

private struct DemoToolsSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        TabView {
            NavigationStack {
                DemoControlsView()
            }
            .tabItem {
                Label("Controls", systemImage: "switch.2")
            }

            NavigationStack {
                ScrollView {
                    DemoLogListView(entries: viewModel.demoLog.recentEntries())
                        .padding()
                }
                .navigationTitle("Demo Log")
            }
            .tabItem {
                Label("Demo Log", systemImage: "list.bullet.rectangle")
            }
        }
    }
}
