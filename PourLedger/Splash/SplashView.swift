//
//  SplashView.swift
//  PourLedger
//
//  Bespoke niche-motif splash: a cast mixer-cylinder with ruler ticks that fills with
//  hi-vis concrete via a phase-driven sine surface. Seamless loop (~2.0s), on the app's
//  surface color (invisible handoff from the launch screen). NOT a logo scale/fade.
//  CLOUDE.md Splash System.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()
            VStack(spacing: 22) {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let phase = t.truncatingRemainder(dividingBy: 2.0) / 2.0   // 0..1 loop
                    SplashCylinder(phase: phase, reduceMotion: reduceMotion)
                        .frame(width: 118, height: 166)
                        .opacity(reduceMotion ? (0.82 + 0.18 * abs(sin(phase * .pi))) : 1)
                }
                VStack(spacing: 5) {
                    Text("POUR LEDGER")
                        .font(.plStamp(22)).tracking(1.2)
                        .foregroundColor(Theme.textPrimary)
                    Text("order · not just m³")
                        .font(.plCaption(13))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}

private struct SplashCylinder: View {
    let phase: Double
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let rect = CGRect(origin: .zero, size: size)
                let cyl = Path(roundedRect: rect, cornerRadius: Theme.radius)
                ctx.fill(cyl, with: .color(Theme.gaugeTrack))
                ctx.clip(to: cyl)

                let base = reduceMotion ? 0.6 : (0.55 + 0.22 * sin(phase * 2 * .pi))
                let level = max(0.06, min(0.96, base))
                let fillTop = rect.maxY - rect.height * CGFloat(level)

                var wave = Path()
                let amp: CGFloat = reduceMotion ? 0 : 5
                wave.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                wave.addLine(to: CGPoint(x: rect.minX, y: fillTop))
                let steps = 28
                for i in 0...steps {
                    let fx = Double(i) / Double(steps)
                    let x = rect.minX + rect.width * CGFloat(fx)
                    let wy = fillTop + CGFloat(sin(phase * .pi * 4 + fx * .pi * 2)) * amp
                    wave.addLine(to: CGPoint(x: x, y: wy))
                }
                wave.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                wave.closeSubpath()
                ctx.fill(wave, with: .color(Theme.accent))
            }
            TickColumn(count: 10)
                .stroke(Theme.gaugeTick, lineWidth: 1)
                .padding(.vertical, 8)
            RoundedRectangle(cornerRadius: Theme.radius)
                .stroke(Theme.hairline, lineWidth: 1.5)
            ChamferTopEdge(radius: Theme.radius)
                .stroke(Theme.chamfer, lineWidth: 1)
        }
    }
}
