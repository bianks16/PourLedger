//
//  Pour.swift
//  PourLedger
//
//  Domain model. All dimensions stored canonically in METRES; volumes in m³.
//  Enums stored as rawValue strings so Codable stays trivial + migration-safe.
//

import Foundation

// MARK: - Element type

enum ElementType: String, Codable, CaseIterable, Identifiable {
    case slab
    case strip
    case columnRect
    case columnRound
    case beam
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .slab:        return "Slab"
        case .strip:       return "Strip"
        case .columnRect:  return "Column"
        case .columnRound: return "Column"
        case .beam:        return "Beam"
        case .custom:      return "Other"
        }
    }

    /// Short segment label for the FormworkSegment picker.
    var segmentLabel: String {
        switch self {
        case .slab:        return "Slab"
        case .strip:       return "Strip"
        case .columnRect:  return "Column"
        case .columnRound: return "Column"
        case .beam:        return "Beam"
        case .custom:      return "Other"
        }
    }

    /// The five picker choices (round column is a toggle inside Column).
    static var pickerCases: [ElementType] { [.slab, .strip, .columnRect, .beam, .custom] }
}

// MARK: - Dimensions (metres). Only the fields relevant to the type are used.

struct Dims: Codable, Hashable {
    var l: Double = 0        // length / run-length
    var w: Double = 0        // width
    var t: Double = 0.20     // slab thickness (default 200 mm)
    var d: Double = 0.30     // depth (strip / custom)
    var h: Double = 0        // height (column / — )
    var sectionA: Double = 0.30 // column b / beam b
    var sectionB: Double = 0.30 // column h / beam h
    var diameter: Double = 0.30 // round column ⌀
    var length: Double = 0   // beam length
}

// MARK: - Element

struct Element: Identifiable, Codable, Hashable {
    var id = UUID()
    var typeRaw: String = ElementType.slab.rawValue
    var name: String = ""
    var dims: Dims = Dims()
    var count: Int = 1

    var type: ElementType {
        get { ElementType(rawValue: typeRaw) ?? .slab }
        set { typeRaw = newValue.rawValue }
    }

    /// A fresh element seeded so secondary dims (thickness/section) are pre-filled
    /// but the governing size starts at 0 → subtotal shows 0.00 until the user drags.
    static func new(_ type: ElementType) -> Element {
        var e = Element()
        e.type = type
        e.name = ""
        e.count = 1
        var dm = Dims()
        switch type {
        case .slab:        dm = Dims(l: 0, w: 0, t: 0.20)
        case .strip:       dm = Dims(l: 0, w: 0.30, d: 0.30)
        case .columnRect:  dm = Dims(h: 0, sectionA: 0.30, sectionB: 0.30)
        case .columnRound: dm = Dims(h: 0, diameter: 0.30)
        case .beam:        dm = Dims(sectionA: 0.30, sectionB: 0.50, length: 0)
        case .custom:      dm = Dims(l: 0, w: 0, d: 0.30)
        }
        e.dims = dm
        return e
    }

    var displayName: String { name.isEmpty ? type.label : name }

    /// Net volume in m³ (0 if invalid).
    var volume: Double { Volume.of(self) }

    /// A governing-dimension sanity check for the error state.
    var isValid: Bool { Volume.isValid(self) }
}

// MARK: - Order settings (per-pour, seeded from user defaults)

enum PourMode: String, Codable, CaseIterable, Identifiable {
    case readyMix
    case handMix
    var id: String { rawValue }
    var label: String { self == .readyMix ? "Ready-mix" : "Hand-mix" }
}

struct OrderSettings: Codable, Hashable {
    var shrinkPct: Double = 0.02       // s
    var wastePct: Double = 0.05        // w
    var truckCapacity: Double = 8.0    // C  (m³)
    var supplierMin: Double = 3.0      // M  (m³)
    var partLoadSurcharge: Double = 0  // P  (€/m³ of shortfall)
    var pricePerM3: Double = 120.0     // €/m³
    var bagYield: Double = 0.011       // m³ per 25 kg bag
    var modeRaw: String = PourMode.readyMix.rawValue

    var mode: PourMode {
        get { PourMode(rawValue: modeRaw) ?? .readyMix }
        set { modeRaw = newValue.rawValue }
    }
}

// MARK: - Pour

struct Pour: Identifiable, Codable, Hashable {
    var id = UUID()
    var siteName: String = ""
    var date: Date = Date()
    var elements: [Element] = []
    var settings: OrderSettings = OrderSettings()

    var displaySiteName: String { siteName.isEmpty ? "Untitled pour" : siteName }

    /// Net summed volume across valid elements (m³).
    var netVolume: Double { elements.reduce(0) { $0 + $1.volume } }

    var hasInvalidElement: Bool { elements.contains { !$0.isValid } }
}
