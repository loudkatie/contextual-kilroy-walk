//
//  ContextualGlyph.swift
//  KilroyWalkApp
//
//  Standalone glyph rendering
//

import SwiftUI

enum ContextualGlyph {

    enum Style {
        case listeningHalo
        case stardustArc
    }

    static func view(
        style: Style,
        size: CGFloat
    ) -> some View {
        ZStack {
            switch style {

            case .listeningHalo:
                Circle()
                    .stroke(
                        ContextualStyle.haloWhite,
                        lineWidth: size * 0.06
                    )
                    .blur(radius: 0.6)

            case .stardustArc:
                Circle()
                    .trim(from: 0.08, to: 0.88)
                    .stroke(
                        ContextualStyle.stardust,
                        style: StrokeStyle(
                            lineWidth: size * 0.05,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 0.8)
            }
        }
        .frame(width: size, height: size)
    }
}
