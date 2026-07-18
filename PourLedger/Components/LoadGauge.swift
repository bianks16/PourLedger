//
//  LoadGauge.swift
//  PourLedger
//
//  SIGNATURE VISUAL. A row of hard-edged mixer cylinders with ruler ticks that fill
//  viscously with hi-vis concrete. Last partial truck fills to r/C (rust when a real
//  underload, hi-vis when nearly full). >=20 full → numeric summary. FULL LOAD flash +
//  .success haptic on the transition. Reduce Motion → instant fill + static stamp.
//

import SwiftUI

// MARK: - Animatable liquid fill

struct LiquidFill: Shape {
    var fillFraction: CGFloat
    var meniscus: CGFloat = 2

    var animatableData: CGFloat {
        get { fillFraction }
        set { fillFraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let clamped = max(0, min(1, fillFraction))
        let fillHeight = rect.height * clamped
        guard fillHeight > 0.5 else { return p }
        let top = rect.maxY - fillHeight
        let m = min(meniscus, fillHeight / 2)
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: top + m))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: top + m),
                       control: CGPoint(x: rect.midX, y: top - m))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Ruler ticks up the side

struct TickColumn: Shape {
    var count: Int = 8
    func path(in rect: CGRect) -> Path {
        var p = Path()
        for i in 1..<max(2, count) {
            let y = rect.maxY - rect.height * CGFloat(i) / CGFloat(count)
            let isMajor = i % 4 == 0
            let len = rect.width * (isMajor ? 0.34 : 0.18)
            p.move(to: CGPoint(x: rect.maxX - len, y: y))
            p.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return p
    }
}

// MARK: - A single mixer cylinder

struct CylinderView: View {
    let targetFraction: CGFloat
    let colorKind: GaugeColorKind
    var reduceMotion: Bool = false

    private var fillColor: Color {
        colorKind == .hiVis ? Theme.accent : Theme.warning
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: Theme.radius)
                .fill(Theme.gaugeTrack)

            LiquidFill(fillFraction: targetFraction)
                .fill(fillColor)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                .animation(reduceMotion ? nil : Theme.viscous, value: targetFraction)

            TickColumn(count: 8)
                .stroke(Theme.gaugeTick, lineWidth: 1)
                .padding(.vertical, 4)
                .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: Theme.radius)
                .stroke(Theme.hairline, lineWidth: 1)
            ChamferTopEdge().stroke(Theme.chamfer, lineWidth: 1)
        }
    }
}

// MARK: - Numeric summary (>=20 full)

private struct NumericSummaryView: View {
    let full: Int
    let hasPartial: Bool

    var body: some View {
        HStack(spacing: 14) {
            CylinderView(targetFraction: 1, colorKind: .hiVis)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                MonoDisplay(value: "\(full)", unit: "full", size: 40)
                if hasPartial {
                    MonoMetric(value: "+1", unit: "part load", size: 16,
                               weight: .bold, color: Theme.warning)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - The gauge

struct LoadGauge: View {
    let fills: [GaugeFill]
    let usesNumericSummary: Bool
    let full: Int
    let partialRemainder: Double
    let isFullLoad: Bool
    let accessibilityLabel: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrating = false
    @State private var flashTask: Task<Void, Never>?

    private var drawn: [GaugeFill] {
        fills.isEmpty ? [GaugeFill(fraction: 0, colorKind: .hiVis)] : fills
    }

    var body: some View {
        Group {
            if usesNumericSummary {
                NumericSummaryView(full: full, hasPartial: partialRemainder > 0)
            } else {
                GeometryReader { geo in
                    cylinders(in: geo.size)
                }
            }
        }
        .overlay { flashOverlay }
        .onChange(of: isFullLoad) { newValue in
            handleFullLoad(newValue)
        }
        .onDisappear {
            flashTask?.cancel()
            flashTask = nil
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func cylinders(in size: CGSize) -> some View {
        let count = drawn.count
        let spacing: CGFloat = 6
        let maxW: CGFloat = 54
        let raw = (size.width - spacing * CGFloat(max(0, count - 1))) / CGFloat(max(1, count))
        let w = min(maxW, max(8, raw))
        return HStack(spacing: spacing) {
            ForEach(Array(drawn.enumerated()), id: \.offset) { _, f in
                CylinderView(targetFraction: CGFloat(f.fraction),
                             colorKind: f.colorKind,
                             reduceMotion: reduceMotion)
                    .frame(width: w)
                    .transition(reduceMotion
                                ? AnyTransition.opacity
                                : AnyTransition.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder private var flashOverlay: some View {
        if celebrating && !reduceMotion {
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let pulse = 0.5 + 0.5 * sin(t * .pi * 6)
                RoundedRectangle(cornerRadius: Theme.radius)
                    .fill(Theme.accent.opacity(0.30 * pulse))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius)
                            .stroke(Theme.accent.opacity(0.5 + 0.5 * pulse), lineWidth: 2)
                    )
                    .allowsHitTesting(false)
            }
            .transition(.opacity)
        }
    }

    private func handleFullLoad(_ isFull: Bool) {
        guard isFull else { return }
        Haptics.success()
        guard !reduceMotion else { return }
        flashTask?.cancel()
        withAnimation(.easeIn(duration: 0.15)) { celebrating = true }
        flashTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            withAnimation(.easeOut(duration: 0.25)) { celebrating = false }
        }
    }
}
