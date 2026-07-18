//
//  Formatters.swift
//  PourLedger
//
//  Number / volume / money formatting. Everything measurable is rendered through
//  MonoMetric, which leans on these.
//

import Foundation

enum Fmt {
    /// Volume in m³ to N decimals, trimmed of noise (12.30 -> "12.3", 12.00 -> "12").
    static func vol(_ v: Double, decimals: Int = 2) -> String {
        let rounded = (v * pow(10, Double(decimals))).rounded() / pow(10, Double(decimals))
        return trimmed(rounded, maxDecimals: decimals)
    }

    /// Fixed 1-decimal for receipt columns (keeps mono columns aligned).
    static func vol1(_ v: Double) -> String {
        String(format: "%.1f", v)
    }

    static func vol2(_ v: Double) -> String {
        String(format: "%.2f", v)
    }

    /// Whole number, grouped.
    static func int(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "\(Int(v))"
    }

    static func money(_ v: Double, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        let n = f.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v)
        return "\(currency)\(n)"
    }

    static func money0(_ v: Double, currency: String) -> String {
        "\(currency)\(int(v))"
    }

    static func pct(_ fraction: Double) -> String {
        "\(trimmed(fraction * 100, maxDecimals: 1))%"
    }

    /// Millimetres from a metres value (0.2 -> "200").
    static func mm(_ metres: Double) -> String {
        int(metres * 1000)
    }

    private static func trimmed(_ v: Double, maxDecimals: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = maxDecimals
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    static func date(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f.string(from: d)
    }
}
