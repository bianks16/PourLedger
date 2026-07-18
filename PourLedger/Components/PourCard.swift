//
//  PourCard.swift
//  PourLedger
//
//  A saved pour rendered as a truck-ledger card with an embedded mini LoadGauge glyph.
//  Not a plain list row. Spec §5.5.
//

import SwiftUI

/// Lightweight, non-animated gauge glyph for cards.
struct MiniGauge: View {
    let fills: [GaugeFill]
    let usesNumericSummary: Bool
    let full: Int

    var body: some View {
        if usesNumericSummary {
            HStack(spacing: 5) {
                miniCylinder(fraction: 1, kind: .hiVis)
                MonoMetric(value: "\(full)+", unit: "trucks", size: 13, weight: .bold)
            }
        } else if fills.isEmpty {
            miniCylinder(fraction: 0, kind: .hiVis)
        } else {
            HStack(spacing: 3) {
                ForEach(Array(fills.prefix(12).enumerated()), id: \.offset) { _, f in
                    miniCylinder(fraction: CGFloat(f.fraction), kind: f.colorKind)
                }
            }
        }
    }

    private func miniCylinder(fraction: CGFloat, kind: GaugeColorKind) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2).fill(Theme.gaugeTrack)
            RoundedRectangle(cornerRadius: 2)
                .fill(kind == .hiVis ? Theme.accent : Theme.warning)
                .frame(height: 26 * max(0.02, min(1, fraction)))
            RoundedRectangle(cornerRadius: 2).stroke(Theme.hairline, lineWidth: 0.75)
        }
        .frame(width: 9, height: 26)
    }
}

struct PourCard: View {
    let pour: Pour
    let currency: String

    private var result: PourResult { LoadPacker.compute(pour: pour) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(pour.displaySiteName)
                        .font(.plHeadline(17))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1).truncationMode(.tail)
                    Text(Fmt.date(pour.date))
                        .font(.plCaption(12))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer(minLength: 8)
                MonoMetric(value: Fmt.money0(result.cost, currency: currency),
                           size: 19, weight: .bold, color: Theme.textPrimary)
            }

            HairlineDivider()

            HStack(alignment: .center) {
                MiniGauge(fills: result.gaugeFills,
                          usesNumericSummary: result.usesNumericSummary,
                          full: result.full)
                Spacer(minLength: 8)
                if result.mode == .handMix {
                    StampChip(text: "hand-mix", kind: .neutral)
                } else if result.isFullLoad {
                    StampChip(text: "full load", systemImage: "checkmark", kind: .hiVis)
                } else if result.isBelowMinimum {
                    StampChip(text: "min \(Fmt.vol1(result.ordered)) m³", kind: .rust)
                } else if result.waste > 0.001 {
                    StampChip(text: "waste \(Fmt.vol1(result.waste)) m³", kind: .rust)
                }
                MonoMetric(value: "\(result.mode == .handMix ? result.handMix?.bags ?? 0 : result.trucks)",
                           unit: result.mode == .handMix ? "bags" : "trucks",
                           size: 14, weight: .bold, color: Theme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .castSurface(fill: Theme.surfaceElevated)
        .accessibilityElement(children: .combine)
    }
}
