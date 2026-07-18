//
//  Volume.swift
//  PourLedger
//
//  Pure per-element volume formulas (m³). No SwiftUI. Spec §7.
//

import Foundation

enum Volume {
    /// Net volume of a single element in m³. Returns 0 if the element is invalid
    /// (a 0/negative governing dimension) so the gauge simply skips it.
    static func of(_ e: Element) -> Double {
        guard isValid(e) else { return 0 }
        let d = e.dims
        let n = Double(max(1, e.count))
        switch e.type {
        case .slab:        return d.l * d.w * d.t
        case .strip:       return d.l * d.w * d.d
        case .columnRect:  return d.sectionA * d.sectionB * d.h * n
        case .columnRound: return .pi * pow(d.diameter / 2, 2) * d.h * n
        case .beam:        return d.sectionA * d.sectionB * d.length * n
        case .custom:      return d.l * d.w * d.d
        }
    }

    /// True if every governing dimension for the element's type is strictly positive.
    static func isValid(_ e: Element) -> Bool {
        let d = e.dims
        if e.count < 1 { return false }
        switch e.type {
        case .slab:        return d.l > 0 && d.w > 0 && d.t > 0
        case .strip:       return d.l > 0 && d.w > 0 && d.d > 0
        case .columnRect:  return d.sectionA > 0 && d.sectionB > 0 && d.h > 0
        case .columnRound: return d.diameter > 0 && d.h > 0
        case .beam:        return d.sectionA > 0 && d.sectionB > 0 && d.length > 0
        case .custom:      return d.l > 0 && d.w > 0 && d.d > 0
        }
    }

    /// Thickness used for the round-to-full hint: the THICKEST slab's `t`.
    /// Deterministic + order-independent. Returns 0 when the pour has no slab.
    static func activeSlabThickness(_ elements: [Element]) -> Double {
        elements
            .filter { $0.type == .slab && $0.isValid }
            .map { $0.dims.t }
            .max() ?? 0
    }
}
