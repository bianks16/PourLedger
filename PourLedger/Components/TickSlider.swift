//
//  TickSlider.swift
//  PourLedger
//
//  Bespoke ruler slider — a ticked track with a hi-vis fill + caret, dragged to set a
//  value. Used for supplier adjusters (shrink / waste / capacity / minimum / price).
//

import SwiftUI

struct TickSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 0.1
    var unit: String = ""
    var display: (Double) -> String
    var tickCount: Int = 16

    @State private var lastStepIndex: Int = .min

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / span)
    }

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Text(title.uppercased())
                    .font(.plStamp(12)).tracking(0.6)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                MonoMetric(value: display(value), unit: unit, size: 16,
                           weight: .bold, color: Theme.textPrimary)
            }
            GeometryReader { geo in
                let w = geo.size.width
                let thumbX = max(0, min(w, w * fraction))
                ZStack(alignment: .leading) {
                    // track
                    Rectangle().fill(Theme.surfaceDeep)
                    // ticks
                    Canvas { ctx, size in
                        for i in 0...tickCount {
                            let x = size.width * CGFloat(i) / CGFloat(tickCount)
                            let major = i % 4 == 0
                            let h = size.height * (major ? 0.6 : 0.34)
                            var p = Path()
                            p.move(to: CGPoint(x: x, y: size.height))
                            p.addLine(to: CGPoint(x: x, y: size.height - h))
                            ctx.stroke(p, with: .color(Theme.gaugeTick), lineWidth: major ? 1.4 : 1)
                        }
                    }
                    // hi-vis fill up to thumb
                    Rectangle()
                        .fill(Theme.accent.opacity(0.28))
                        .frame(width: thumbX)
                    // caret
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 3)
                        .offset(x: thumbX - 1.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusSmall).stroke(Theme.hairline, lineWidth: 1))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let f = max(0, min(1, g.location.x / max(1, w)))
                            let span = range.upperBound - range.lowerBound
                            var v = range.lowerBound + Double(f) * span
                            v = (v / step).rounded() * step
                            v = min(range.upperBound, max(range.lowerBound, v))
                            value = v
                            let idx = Int((v / step).rounded())
                            if idx != lastStepIndex { lastStepIndex = idx; Haptics.selection() }
                        }
                )
            }
            .frame(height: 30)
        }
    }
}
