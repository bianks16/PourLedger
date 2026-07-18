//
//  EmptyStates.swift
//  PourLedger
//
//  Designed empty compositions built from formwork outlines — NOT a gray icon + text.
//  Spec §5.1 / §5.5.
//

import SwiftUI

/// A single empty-formwork glyph: dashed perimeter, corner form-stakes, ruler ticks.
struct FormworkGraphic: View {
    var accent: Color = Theme.accent
    var lineWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let s = geo.size
            let r = CGRect(x: s.width * 0.10, y: s.height * 0.22,
                           width: s.width * 0.80, height: s.height * 0.56)
            ZStack {
                // dashed formwork perimeter
                Path { p in p.addRect(r) }
                    .stroke(accent,
                            style: StrokeStyle(lineWidth: lineWidth, lineJoin: .miter,
                                               dash: [6, 5]))
                // corner form-stakes
                Path { p in
                    let len = min(s.width, s.height) * 0.12
                    for corner in [CGPoint(x: r.minX, y: r.minY),
                                   CGPoint(x: r.maxX, y: r.minY),
                                   CGPoint(x: r.minX, y: r.maxY),
                                   CGPoint(x: r.maxX, y: r.maxY)] {
                        let dx: CGFloat = corner.x < r.midX ? -len : len
                        let dy: CGFloat = corner.y < r.midY ? -len : len
                        p.move(to: corner)
                        p.addLine(to: CGPoint(x: corner.x + dx * 0.7, y: corner.y + dy * 0.7))
                    }
                }
                .stroke(Theme.hairline, lineWidth: lineWidth)
                // ruler ticks along the top rim
                Path { p in
                    let n = 8
                    for i in 1..<n {
                        let x = r.minX + r.width * CGFloat(i) / CGFloat(n)
                        p.move(to: CGPoint(x: x, y: r.minY))
                        p.addLine(to: CGPoint(x: x, y: r.minY + r.height * 0.12))
                    }
                }
                .stroke(Theme.gaugeTick, lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Pour screen empty state.
struct EmptyPourComposition: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            FormworkGraphic()
                .frame(height: 150)
                .padding(.horizontal, 24)
            VStack(spacing: 8) {
                Text("Empty formwork")
                    .font(.plTitle(22))
                    .foregroundColor(Theme.textPrimary)
                Text("Add an element to start the pour")
                    .font(.plBody(15))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            HiVisButton(title: "Add first element", systemImage: "plus", kind: .solid,
                        fullWidth: false, action: onAdd)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

/// Sites empty state — three formwork outlines in a row.
struct SitesEmptyView: View {
    let onNew: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { i in
                    FormworkGraphic(accent: i == 0 ? Theme.accent : Theme.accentMuted,
                                    lineWidth: 1.6)
                        .frame(height: 74)
                }
            }
            .padding(.horizontal, 8)
            VStack(spacing: 8) {
                Text("No pours yet")
                    .font(.plTitle(22))
                    .foregroundColor(Theme.textPrimary)
                Text("Your saved pours show up here as truck ledgers")
                    .font(.plBody(15))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            HiVisButton(title: "New pour", systemImage: "plus", kind: .solid,
                        fullWidth: false, action: onNew)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}
