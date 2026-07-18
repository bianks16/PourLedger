//
//  Theme.swift
//  PourLedger
//
//  Design system tokens — "concrete grey & hi-vis chartreuse".
//  Mood: wet, weighed, structural. No inline colors/fonts in screens — tokens only.
//

import SwiftUI

// MARK: - Hex + dynamic color helpers

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let a, r, g, b: UInt64
        switch s.count {
        case 8: // AARRGGBB
            a = (value & 0xFF00_0000) >> 24
            r = (value & 0x00FF_0000) >> 16
            g = (value & 0x0000_FF00) >> 8
            b = value & 0x0000_00FF
        default: // RRGGBB
            a = 255
            r = (value & 0xFF0000) >> 16
            g = (value & 0x00FF00) >> 8
            b = value & 0x0000FF
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    static func dynamic(light: String, dark: String) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension Color {
    init(hex: String) { self.init(UIColor(hex: hex)) }
    static func dyn(light: String, dark: String) -> Color {
        Color(UIColor.dynamic(light: light, dark: dark))
    }
}

// MARK: - Semantic palette (spec §3 table)

enum Theme {
    // Backgrounds — matte concrete, light-first
    static let surface        = Color.dyn(light: "#E7E8E4", dark: "#1B1C18")
    static let surfaceElevated = Color.dyn(light: "#F3F4F0", dark: "#24261F")
    static let surfaceDeep     = Color.dyn(light: "#DCDDD8", dark: "#141510")

    // Accent — hi-vis chartreuse (helmet / hi-vis vest). positive == accent (NO green).
    static let accent      = Color.dyn(light: "#8FA81E", dark: "#C0DE3A")
    static let accentMuted = Color.dyn(light: "#C7D98A", dark: "#6E7A2E")
    static let accentInk   = Color.dyn(light: "#22270A", dark: "#1B1C18") // text ON accent fills

    // Text
    static let textPrimary   = Color.dyn(light: "#1F211C", dark: "#F1F2EC")
    static let textSecondary = Color.dyn(light: "#5C5F58", dark: "#9A9C92")
    static let textFaint     = Color.dyn(light: "#8B8E85", dark: "#6A6D63")

    // Status — rust (rebar rust = overpay/underload) + short (not enough)
    static let warning = Color.dyn(light: "#C4551F", dark: "#E07A45")
    static let short   = Color.dyn(light: "#C0392B", dark: "#E5544B")
    static let positive = Color.dyn(light: "#8FA81E", dark: "#C0DE3A") // == accent

    // Structure — hairline elevation, no shadows
    static let hairline = Color.dyn(light: "#C6C8C0", dark: "#3A3D34")
    static let divider  = Color.dyn(light: "#D4D6CE", dark: "#2C2F27")
    static let chamfer  = Color.dyn(light: "#FAFBF7", dark: "#34372E") // 1px lit top edge

    // Gauge cylinder specifics (ruler motif)
    static let gaugeTrack = Color.dyn(light: "#D6D8D0", dark: "#2A2C25")
    static let gaugeTick  = Color.dyn(light: "#9A9C92", dark: "#7C8072") // dark ticks a touch brighter

    // MARK: Shape
    static let radius: CGFloat = 4        // cast-block radius
    static let radiusSmall: CGFloat = 3
    static let hairlineWidth: CGFloat = 1

    // MARK: Motion — "grabbing mix: fast then thick"
    static let drop    = Animation.spring(response: 0.35, dampingFraction: 0.82) // block drop-settle
    static let viscous = Animation.spring(response: 0.5,  dampingFraction: 0.9)  // gauge liquid rise
    static let press   = Animation.spring(response: 0.28, dampingFraction: 0.72) // button sink
    static let morph   = Animation.easeInOut(duration: 0.2)                      // section icon crossfade
    static let slide   = Animation.spring(response: 0.32, dampingFraction: 0.85) // field slide on type change
}

// MARK: - Typography (SF compressed-black display + monospaced metrics)

extension Font {
    /// Hero readout — stamped-mark feel. Apply `.tracking(-0.5)` on the Text.
    static func plDisplay(_ size: CGFloat = 56) -> Font {
        .system(size: size, weight: .black).width(.compressed)
    }
    static func plTitle(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold)
    }
    static func plHeadline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold)
    }
    static func plBody(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular)
    }
    static func plCaption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium)
    }
    /// All measurable numbers — monospaced, ruler-aligned.
    static func plMetric(_ size: CGFloat = 17, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
    }
    /// Compressed-black monospaced metric for big numeric summaries.
    static func plMetricHeavy(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .heavy).width(.compressed).monospacedDigit()
    }
    /// Stamp / label — condensed uppercase caps feel.
    static func plStamp(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .black).width(.compressed)
    }
}
