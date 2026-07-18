//
//  LoadPacker.swift
//  PourLedger
//
//  SIGNATURE FEATURE. Pure computation — converts net pour volume into a concrete
//  ORDER: full trucks + last partial, shrink/waste allowance, supplier minimum,
//  part-load surcharge, waste economics, and the round-to-full hint. Spec §2 + §7.
//
//  No SwiftUI import — fully unit-testable.
//

import Foundation

struct LoadPackerInput: Equatable {
    var vNet: Double            // already-summed net volume (m³)
    var shrink: Double = 0.02   // s
    var waste: Double = 0.05    // w
    var truckCapacity: Double = 8   // C
    var supplierMin: Double = 3     // M
    var partLoadSurcharge: Double = 0   // P €/m³ of shortfall
    var pricePerM3: Double = 120
    var bagYield: Double = 0.011    // m³ / 25 kg bag
    var mode: PourMode = .readyMix
    var slabThickness: Double = 0   // T (m); 0 → round-to-full hint suppressed
    var currency: String = "€"
}

enum LoadPacker {

    // MARK: Convenience from domain objects

    static func compute(pour: Pour) -> PourResult {
        let s = pour.settings
        let input = LoadPackerInput(
            vNet: pour.netVolume,
            shrink: s.shrinkPct,
            waste: s.wastePct,
            truckCapacity: max(0.1, s.truckCapacity),
            supplierMin: max(0, s.supplierMin),
            partLoadSurcharge: max(0, s.partLoadSurcharge),
            pricePerM3: max(0, s.pricePerM3),
            bagYield: max(0.0001, s.bagYield),
            mode: s.mode,
            slabThickness: Volume.activeSlabThickness(pour.elements)
        )
        return compute(input)
    }

    // MARK: Round UP to nearest 0.1 with float-drift tolerance

    static func ceilToTenth(_ x: Double) -> Double {
        guard x.isFinite, x > 0 else { return 0 }
        let scaled = x * 10.0
        let nearest = scaled.rounded()
        if abs(scaled - nearest) < 1e-6 { return nearest / 10.0 } // essentially on grid
        return scaled.rounded(.up) / 10.0
    }

    // MARK: Core

    static func compute(_ i: LoadPackerInput) -> PourResult {
        let s = i.shrink, w = i.waste
        let C = max(0.1, i.truckCapacity)
        let M = max(0, i.supplierMin)
        let vNet = max(0, i.vNet)

        // 1) V_req — round UP to nearest 0.1
        let vReq = ceilToTenth(vNet * (1 + s + w))
        let highAllowanceFlag = (s + w) > 0.20

        // ---- HAND MIX: hide truck math ----
        if i.mode == .handMix {
            // subtract a tiny epsilon so an exact division (e.g. 1.1/0.011 == 100.000000001)
            // doesn't spill into an extra bag from binary-float drift.
            let bags = vReq > 0 ? max(1, Int(ceil(vReq / max(i.bagYield, 1e-6) - 1e-6))) : 0
            let weight = Double(bags) * 25.0
            let water = Double(bags) * 3.0        // ~3 L add-water per 25 kg bag (approx)
            let hm = HandMixResult(bags: bags, totalWeightKg: weight,
                                   waterLitersApprox: water,
                                   unrealistic: vReq > 2.0)
            let ordered = vReq
            let waste = max(0, vReq - vNet)
            return PourResult(
                vNet: vNet, vReq: vReq, full: 0, partialRemainder: 0,
                trucks: 0, ordered: ordered, waste: waste,
                cost: ordered * i.pricePerM3, wasteCost: waste * i.pricePerM3,
                surchargeAmount: 0,
                isFullLoad: false, isBelowMinimum: false, isTinyUnderload: false,
                usesNumericSummary: false, highAllowanceFlag: highAllowanceFlag,
                roundToFullHint: nil, handMix: hm, billedLabel: nil, mode: .handMix,
                gaugeFills: [],
                gaugeAccessibilityLabel:
                    "\(Fmt.vol1(vReq)) cubic metres, hand mix, \(bags) bags, \(Fmt.int(weight)) kilograms"
            )
        }

        // ---- READY MIX ----
        let full = Int(floor((vReq + 1e-9) / C))
        let r = vReq - Double(full) * C
        let rIsZero = r < 1e-6

        // below minimum takes precedence (a whole job under M)
        let belowMinimum = vReq > 0 && vReq < M - 1e-9

        var trucks: Int
        var ordered: Double
        var isFullLoad = false
        var billedLabel: String? = nil

        if vReq <= 0 {
            trucks = 0
            ordered = 0
        } else if belowMinimum {
            trucks = 1
            ordered = M
            billedLabel = "billed as \(Fmt.vol1(M)) m³ (supplier minimum)"
        } else if rIsZero {
            trucks = full
            ordered = Double(full) * C
            isFullLoad = true
        } else {
            trucks = full + 1
            let lastLoad = max(r, (full == 0 ? M : r))
            ordered = Double(full) * C + lastLoad
        }

        let waste = max(0, ordered - vNet)
        let isTinyUnderload = !rIsZero && !belowMinimum && vReq > 0 && r < 0.5

        // round-to-full hint (needs a slab thickness). The last truck has headroom
        // C - r in ORDERED space, but you pour NET concrete and the allowance (1+s+w)
        // scales it — so the net top-up that lands the order exactly on a full truck is
        // (nextBoundary − ε)/(1+s+w) − vNet. Using that (not the raw C−r) guarantees the
        // "apply → FULL LOAD" promise actually holds.
        var hint: RoundToFullHint? = nil
        if isTinyUnderload, i.slabThickness > 1e-6 {
            let nextBoundary = Double(full + 1) * C
            let targetNet = (nextBoundary - 0.05) / (1 + s + w)
            let addNet = max(0, targetNet - vNet)
            hint = RoundToFullHint(deltaVolume: addNet,
                                   deltaAreaM2: addNet / i.slabThickness,
                                   slabThickness: i.slabThickness)
        }

        let usesNumericSummary = full >= 20

        // cost + surcharge on the shortfall of the last part truck
        var surcharge = 0.0
        if i.partLoadSurcharge > 0 && !rIsZero && vReq > 0 {
            surcharge = i.partLoadSurcharge * max(0, C - r)
        }
        let cost = ordered * i.pricePerM3 + surcharge
        let wasteCost = waste * i.pricePerM3

        let fills = usesNumericSummary
            ? []
            : buildGaugeFills(full: full, r: r, C: C, rIsZero: rIsZero)

        let fullWord = full == 1 ? "full truck" : "full trucks"
        let a11y: String
        if vReq <= 0 {
            a11y = "0 cubic metres, empty formwork, 0 trucks"
        } else {
            a11y = "\(Fmt.vol1(vReq)) cubic metres, \(full) \(fullWord), " +
                   "part load \(Fmt.vol1(rIsZero ? 0 : r)), waste \(Fmt.vol1(waste))"
        }

        return PourResult(
            vNet: vNet, vReq: vReq, full: full,
            partialRemainder: rIsZero ? 0 : r,
            trucks: trucks, ordered: ordered, waste: waste,
            cost: cost, wasteCost: wasteCost, surchargeAmount: surcharge,
            isFullLoad: isFullLoad, isBelowMinimum: belowMinimum,
            isTinyUnderload: isTinyUnderload,
            usesNumericSummary: usesNumericSummary,
            highAllowanceFlag: highAllowanceFlag,
            roundToFullHint: hint, handMix: nil, billedLabel: billedLabel,
            mode: .readyMix, gaugeFills: fills, gaugeAccessibilityLabel: a11y
        )
    }

    private static func buildGaugeFills(full: Int, r: Double, C: Double,
                                        rIsZero: Bool) -> [GaugeFill] {
        var out: [GaugeFill] = []
        out.reserveCapacity(full + 1)
        for _ in 0..<max(0, full) {
            out.append(GaugeFill(fraction: 1.0, colorKind: .hiVis))
        }
        if !rIsZero && r > 0 {
            let frac = min(1.0, r / C)
            let nearlyFull = r >= C - 0.1
            out.append(GaugeFill(fraction: frac, colorKind: nearlyFull ? .hiVis : .rust))
        }
        return out
    }
}
