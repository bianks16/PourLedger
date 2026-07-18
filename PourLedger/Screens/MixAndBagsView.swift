//
//  MixAndBagsView.swift
//  PourLedger
//
//  Hand-mix path — bags, weight, water. Truck math hidden. Sheet. Spec §5.4.
//

import SwiftUI

struct MixAndBagsView: View {
    @EnvironmentObject var store: PourStore
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    private var result: PourResult {
        var p = store.current
        p.settings.mode = .handMix
        return LoadPacker.compute(pour: p)
    }

    private var bagYieldLitres: Binding<Double> {
        Binding(get: { store.current.settings.bagYield * 1000 },
                set: { store.current.settings.bagYield = max(0.001, $0 / 1000) })
    }

    var body: some View {
        SheetScaffold(title: "Mix & bags",
                      subtitle: "for a site with no mixer",
                      onClose: { dismiss() }) {
            if result.vReq <= 0 {
                emptyState
            } else {
                heroPanel
                CastPanel(label: "Bag yield") {
                    TickSlider(title: "Per 25 kg bag", value: bagYieldLitres,
                               range: 5...25, step: 0.5, unit: "L/bag",
                               display: { Fmt.int($0) })
                    NoteLine(text: "Yield is the fresh concrete one bag makes; check your bag's label.")
                }
                if result.handMix?.unrealistic == true {
                    NoteLine(text: "This much by hand is unrealistic — order a mixer truck instead.",
                             systemImage: "exclamationmark.triangle")
                }
            }
        }
    }

    private var heroPanel: some View {
        let hm = result.handMix
        return CastPanel(label: "Hand mix") {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                MonoDisplay(value: "\(hm?.bags ?? 0)", unit: "bags", size: 56, color: Theme.accent)
                Spacer()
            }
            HairlineDivider()
            MetricRow(label: "required volume", value: Fmt.vol2(result.vReq), unit: "m³", emphasized: true)
            MetricRow(label: "total weight", value: Fmt.int(hm?.totalWeightKg ?? 0), unit: "kg")
            MetricRow(label: "water (approx, W/C ~0.5)", value: Fmt.int(hm?.waterLitersApprox ?? 0), unit: "L")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            FormworkGraphic().frame(height: 110).padding(.horizontal, 30)
            Text("Add elements").font(.plTitle(20)).foregroundColor(Theme.textPrimary)
            Text("There's nothing to mix yet — add elements to the pour first.")
                .font(.plBody(14)).foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
