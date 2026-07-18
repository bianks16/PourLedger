//
//  OrderBreakdownView.swift
//  PourLedger
//
//  The full order chain + underload economics + round-to-full (the Signature surface).
//  `OrderContent` is shared by the iPhone sheet and the iPad live column. Spec §5.3 / §8.
//

import SwiftUI

// MARK: - Shared receipt content

struct OrderContent: View {
    @EnvironmentObject var store: PourStore
    @EnvironmentObject var app: AppState
    var onApplied: () -> Void
    var presentMix: () -> Void

    private var result: PourResult { LoadPacker.compute(pour: store.current) }
    private var s: OrderSettings { store.current.settings }

    private func b<T>(_ kp: WritableKeyPath<OrderSettings, T>) -> Binding<T> {
        Binding(get: { store.current.settings[keyPath: kp] },
                set: { store.current.settings[keyPath: kp] = $0 })
    }
    private var modeBinding: Binding<PourMode> {
        Binding(get: { store.current.settings.mode },
                set: { store.current.settings.mode = $0 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !app.hasSeenSupplierSetup { supplierSetupCard }
            FormworkSegment(options: PourMode.allCases, label: { $0.label }, selection: modeBinding)
            if result.mode == .readyMix {
                receiptPanel
                wastePanel
                if let hint = result.roundToFullHint { roundToFullCard(hint) }
            } else {
                handMixPanel
            }
            if result.highAllowanceFlag {
                NoteLine(text: "Shrink + waste is over 20% — unusually high allowance, double-check.",
                         systemImage: "exclamationmark.triangle")
            }
            adjustPanel
            HiVisButton(title: "Mix & bags detail", systemImage: "bag.fill", kind: .ghost) { presentMix() }
        }
    }

    private var supplierSetupCard: some View {
        CastPanel(label: "Set your supplier", fill: Theme.surfaceElevated) {
            Text("Two numbers change the whole order — your mixer's capacity and the plant's minimum charge.")
                .font(.plBody(14)).foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            TickSlider(title: "Truck capacity", value: b(\.truckCapacity),
                       range: 1...12, step: 0.5, unit: "m³", display: { Fmt.vol1($0) })
            TickSlider(title: "Supplier minimum", value: b(\.supplierMin),
                       range: 0...12, step: 0.5, unit: "m³", display: { Fmt.vol1($0) })
            HStack(spacing: 10) {
                HiVisButton(title: "Save supplier", kind: .solid) {
                    app.defTruckCapacity = s.truckCapacity
                    app.defSupplierMin = s.supplierMin
                    app.hasSeenSupplierSetup = true
                    Haptics.selection()
                }
                HiVisButton(title: "Skip", kind: .ghost, fullWidth: false) {
                    app.hasSeenSupplierSetup = true
                }
            }
        }
    }

    private var receiptPanel: some View {
        CastPanel(label: "The order") {
            MetricRow(label: "net poured", value: Fmt.vol2(result.vNet), unit: "m³")
            MetricRow(label: "+ shrink", value: Fmt.pct(s.shrinkPct), valueColor: Theme.textSecondary)
            MetricRow(label: "+ waste", value: Fmt.pct(s.wastePct), valueColor: Theme.textSecondary)
            HairlineDivider()
            MetricRow(label: "required", value: Fmt.vol2(result.vReq), unit: "m³",
                      valueColor: Theme.accent, emphasized: true)
            HairlineDivider()
            if result.full > 0 {
                MetricRow(label: "full ×\(result.full)",
                          value: Fmt.vol2(Double(result.full) * s.truckCapacity), unit: "m³")
            }
            if result.partialRemainder > 0 {
                MetricRow(label: "part ×1", value: Fmt.vol2(result.partialRemainder), unit: "m³",
                          valueColor: result.isTinyUnderload ? Theme.warning : Theme.textPrimary)
            }
            if result.isFullLoad {
                HStack {
                    StampChip(text: "full load", systemImage: "checkmark", kind: .hiVis)
                    Spacer()
                    Text("no part truck").font(.plCaption(12)).foregroundColor(Theme.textSecondary)
                }
            }
            if let billed = result.billedLabel {
                MetricRow(label: "billed minimum", value: Fmt.vol1(result.ordered), unit: "m³",
                          valueColor: Theme.warning)
                NoteLine(text: billed)
            }
            HairlineDivider()
            MetricRow(label: "ordered", value: Fmt.vol2(result.ordered), unit: "m³", emphasized: true)
            if result.hasSurcharge {
                MetricRow(label: "part-load surcharge",
                          value: app.money(result.surchargeAmount), valueColor: Theme.warning)
            }
            MetricRow(label: "cost", value: app.money(result.cost),
                      valueColor: Theme.accent, emphasized: true)
        }
    }

    @ViewBuilder private var wastePanel: some View {
        if result.isFullLoad {
            HStack {
                StampChip(text: "FULL LOAD", systemImage: "checkmark.seal.fill", kind: .hiVis)
                Spacer()
                Text("nothing wasted").font(.plCaption(13)).foregroundColor(Theme.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .castSurface(fill: Theme.surfaceElevated)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    StampChip(text: "waste \(Fmt.vol2(result.waste)) m³", kind: .rust)
                    Spacer()
                    MonoMetric(value: app.money(result.wasteCost), size: 18,
                               weight: .bold, color: Theme.warning)
                }
                Text("concrete you pay for but won't place")
                    .font(.plCaption(12.5)).foregroundColor(Theme.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .castSurface(fill: Theme.surfaceElevated)
        }
    }

    private func roundToFullCard(_ hint: RoundToFullHint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.to.line")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(Theme.accent)
                Text("ROUND TO FULL").font(.plStamp(13)).tracking(0.6)
                    .foregroundColor(Theme.textPrimary)
            }
            Text("Top up the last truck and pay for nothing empty:")
                .font(.plBody(14)).foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 14) {
                MonoMetric(value: "+\(Fmt.vol2(hint.deltaVolume))", unit: "m³",
                           size: 20, weight: .bold, color: Theme.accent)
                Image(systemName: "equal").font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textFaint)
                MonoMetric(value: "+\(Fmt.vol1(hint.deltaAreaM2))", unit: "m²",
                           size: 20, weight: .bold, color: Theme.textPrimary)
            }
            Text("extra slab at \(Fmt.mm(hint.slabThickness)) mm → last truck becomes full")
                .font(.plCaption(12.5)).foregroundColor(Theme.textSecondary)
            HiVisButton(title: "Apply as new block", systemImage: "plus.square.fill", kind: .solid) {
                var e = Element.new(.slab)
                e.name = "Top-up slab"
                e.dims.t = hint.slabThickness
                e.dims.w = 1.0
                e.dims.l = max(0.01, hint.deltaAreaM2)
                withAnimation(Theme.drop) { store.addElement(e) }
                onApplied()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .castSurface(fill: Theme.surfaceElevated, stroke: Theme.accent.opacity(0.5))
    }

    private var handMixPanel: some View {
        let hm = result.handMix
        return CastPanel(label: "Hand mix") {
            HStack(alignment: .firstTextBaseline) {
                MonoDisplay(value: "\(hm?.bags ?? 0)", unit: "bags", size: 44, color: Theme.accent)
                Spacer()
            }
            MetricRow(label: "required", value: Fmt.vol2(result.vReq), unit: "m³")
            MetricRow(label: "total weight", value: Fmt.int(hm?.totalWeightKg ?? 0), unit: "kg")
            MetricRow(label: "water (approx)", value: Fmt.int(hm?.waterLitersApprox ?? 0), unit: "L")
            if hm?.unrealistic == true {
                NoteLine(text: "That's a lot to mix by hand — consider ordering a truck.",
                         systemImage: "exclamationmark.triangle")
            }
        }
    }

    private var adjustPanel: some View {
        CastPanel(label: "Supplier & allowance") {
            TickSlider(title: "Truck capacity", value: b(\.truckCapacity),
                       range: 1...12, step: 0.5, unit: "m³", display: { Fmt.vol1($0) })
            TickSlider(title: "Supplier minimum", value: b(\.supplierMin),
                       range: 0...12, step: 0.5, unit: "m³", display: { Fmt.vol1($0) })
            TickSlider(title: "Shrink", value: b(\.shrinkPct),
                       range: 0...0.15, step: 0.01, unit: "", display: { Fmt.pct($0) })
            TickSlider(title: "Waste", value: b(\.wastePct),
                       range: 0...0.25, step: 0.01, unit: "", display: { Fmt.pct($0) })
            TickSlider(title: "Price", value: b(\.pricePerM3),
                       range: 0...400, step: 5, unit: "/m³",
                       display: { Fmt.money0($0, currency: app.currency) })
            TickSlider(title: "Part-load surcharge", value: b(\.partLoadSurcharge),
                       range: 0...120, step: 5, unit: "/m³",
                       display: { Fmt.money0($0, currency: app.currency) })
        }
    }
}

// MARK: - Empty receipt

struct EmptyReceipt: View {
    var onClose: (() -> Void)?
    var body: some View {
        VStack(spacing: 18) {
            FormworkGraphic().frame(height: 120).padding(.horizontal, 30)
            Text("Add elements first")
                .font(.plTitle(20)).foregroundColor(Theme.textPrimary)
            Text("Build the pour, then the order chain and waste economics show up here.")
                .font(.plBody(14)).foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let onClose {
                HiVisButton(title: "Back to pour", systemImage: "arrow.left", kind: .ghost,
                            fullWidth: false) { onClose() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Sheet

struct OrderBreakdownView: View {
    @EnvironmentObject var store: PourStore
    @Environment(\.dismiss) private var dismiss
    @State private var showMix = false

    private var isEmpty: Bool { store.current.netVolume <= 0 }

    var body: some View {
        SheetScaffold(title: "Order breakdown",
                      subtitle: "net → allowance → trucks → economics",
                      onClose: { dismiss() }) {
            if isEmpty {
                EmptyReceipt(onClose: { dismiss() })
            } else {
                OrderContent(onApplied: { dismiss() }, presentMix: { showMix = true })
            }
        }
        .sheet(isPresented: $showMix) { MixAndBagsView() }
    }
}
