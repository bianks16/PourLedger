//
//  DimInput.swift
//  PourLedger
//
//  A dimension is entered by dragging a tick-ruler (the app's ruler motif) OR typed
//  directly. Not a plain stepper/field. Binds to canonical METRES; displays m or mm.
//

import SwiftUI

enum DimUnit {
    case m, mm
    var suffix: String { self == .m ? "m" : "mm" }
    func toDisplay(_ meters: Double) -> Double { self == .m ? meters : meters * 1000 }
    func toMeters(_ disp: Double) -> Double { self == .m ? disp : disp / 1000 }
}

struct DimInput: View {
    let title: String
    @Binding var meters: Double
    var unit: DimUnit = .m
    var displayRange: ClosedRange<Double> = 0...30   // in display units
    var ticksStep: Double = 0.1                       // display units per minor tick
    var majorEvery: Int = 10
    var decimals: Int = 2

    @State private var text: String = ""
    @FocusState private var focused: Bool
    @State private var dragStart: Double? = nil
    @State private var lastMajor: Int = .min
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pxPerTick: CGFloat = 11

    private var displayValue: Double { unit.toDisplay(meters) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title.uppercased())
                    .font(.plStamp(12)).tracking(0.6)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    TextField("0", text: $text)
                        .font(.plMetric(20, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .keyboardType(decimals > 0 ? .decimalPad : .numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 44, maxWidth: 96)
                        .fixedSize()
                        .focused($focused)
                        .onChange(of: text) { newVal in
                            guard focused else { return }
                            if let d = parse(newVal) {
                                meters = unit.toMeters(clampDisplay(d))
                            }
                        }
                    Text(unit.suffix)
                        .font(.plCaption(13))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            ruler
        }
        .padding(12)
        .castSurface(fill: Theme.surface)
        .onAppear { syncText() }
        .onChange(of: meters) { _ in if !focused { syncText() } }
        .onChange(of: focused) { f in if !f { syncText() } }
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityValue("\(Fmt.vol(displayValue, decimals: decimals)) \(unit.suffix)")
        .accessibilityAdjustableAction { direction in
            let d = ticksStep * (direction == .increment ? 1 : -1)
            meters = unit.toMeters(clampDisplay(displayValue + d))
            syncText()
        }
    }

    private var ruler: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let mid = w / 2
            ZStack {
                Canvas { ctx, size in
                    let v = displayValue
                    let firstTick = (displayRange.lowerBound / ticksStep).rounded(.down)
                    let lastTick = (displayRange.upperBound / ticksStep).rounded(.up)
                    var i = Int(firstTick)
                    let end = Int(lastTick)
                    while i <= end {
                        let tv = Double(i) * ticksStep
                        let x = mid + CGFloat((tv - v) / ticksStep) * pxPerTick
                        if x >= -2 && x <= size.width + 2 {
                            let isMajor = i % majorEvery == 0
                            let h = size.height * (isMajor ? 0.62 : 0.34)
                            var line = Path()
                            line.move(to: CGPoint(x: x, y: size.height))
                            line.addLine(to: CGPoint(x: x, y: size.height - h))
                            ctx.stroke(line, with: .color(Theme.gaugeTick),
                                       lineWidth: isMajor ? 1.5 : 1)
                        }
                        i += 1
                    }
                }
                // center caret
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 2.5)
                    .frame(maxHeight: .infinity)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if dragStart == nil { dragStart = displayValue }
                        let base = dragStart ?? displayValue
                        let deltaTicks = Double(-value.translation.width / pxPerTick)
                        let newDisp = clampDisplay(base + deltaTicks * ticksStep)
                        meters = unit.toMeters(newDisp)
                        fireTickHaptic(newDisp)
                        if !focused { syncText() }
                    }
                    .onEnded { _ in dragStart = nil }
            )
        }
        .frame(height: 44)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSmall).stroke(Theme.hairline, lineWidth: 1))
        .background(Theme.surfaceDeep)
    }

    private func fireTickHaptic(_ disp: Double) {
        let major = Int((disp / (ticksStep * Double(majorEvery))).rounded())
        if major != lastMajor {
            lastMajor = major
            Haptics.selection()
        }
    }

    private func clampDisplay(_ d: Double) -> Double {
        min(displayRange.upperBound, max(displayRange.lowerBound, d))
    }

    private func parse(_ s: String) -> Double? {
        let cleaned = s.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    private func syncText() {
        text = Fmt.vol(displayValue, decimals: decimals)
    }
}
