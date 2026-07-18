//
//  PourResult.swift
//  PourLedger
//
//  Output of the Load Packer engine. No SwiftUI — plain values the UI reads.
//

import Foundation

enum GaugeColorKind: String, Equatable {
    case hiVis   // full or nearly-full truck
    case rust    // meaningful underload on the last truck
}

/// One mixer cylinder's display state.
struct GaugeFill: Equatable {
    let fraction: Double        // 0...1
    let colorKind: GaugeColorKind
}

/// "Top up the last truck" actionable hint.
struct RoundToFullHint: Equatable {
    let deltaVolume: Double      // C - r, m³ to fill the last truck
    let deltaAreaM2: Double      // deltaVolume / T
    let slabThickness: Double    // T used (thickest slab)
}

/// Hand-mix path result.
struct HandMixResult: Equatable {
    let bags: Int
    let totalWeightKg: Double
    let waterLitersApprox: Double
    let unrealistic: Bool        // "unrealistic by hand — order a truck"
}

struct PourResult: Equatable {
    // core volumes
    let vNet: Double
    let vReq: Double
    let full: Int
    let partialRemainder: Double   // r (0 on exact full load)
    let trucks: Int
    let ordered: Double            // what the plant bills you for
    let waste: Double              // ordered - vNet (paid, not placed)

    // money
    let cost: Double
    let wasteCost: Double
    let surchargeAmount: Double
    var hasSurcharge: Bool { surchargeAmount > 0 }

    // states / flags
    let isFullLoad: Bool
    let isBelowMinimum: Bool
    let isTinyUnderload: Bool
    let usesNumericSummary: Bool   // full >= 20 → don't draw 20+ cylinders
    let highAllowanceFlag: Bool    // s + w > 20%

    // hints & mode
    let roundToFullHint: RoundToFullHint?
    let handMix: HandMixResult?
    let billedLabel: String?
    let mode: PourMode

    // display
    let gaugeFills: [GaugeFill]
    let gaugeAccessibilityLabel: String

    var isEmpty: Bool { vNet <= 0 }
}
