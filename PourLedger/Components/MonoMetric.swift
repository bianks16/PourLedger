//
//  MonoMetric.swift
//  PourLedger
//
//  Every measurable number renders through here — monospaced, unit-suffixed,
//  ruler-aligned. No bare Text numbers anywhere in the app (spec §10.3).
//

import SwiftUI

/// Inline metric: value (mono) + optional unit suffix.
struct MonoMetric: View {
    let value: String
    var unit: String? = nil
    var size: CGFloat = 17
    var weight: Font.Weight = .semibold
    var color: Color = Theme.textPrimary
    var unitColor: Color = Theme.textSecondary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(value)
                .font(.plMetric(size, weight: weight))
                .foregroundColor(color)
            if let unit {
                Text(unit)
                    .font(.plCaption(max(11, size * 0.62)))
                    .foregroundColor(unitColor)
            }
        }
    }
}

/// Big compressed-black monospaced readout (numeric summaries / hero counts).
struct MonoDisplay: View {
    let value: String
    var unit: String? = nil
    var size: CGFloat = 56
    var color: Color = Theme.textPrimary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(value)
                .font(.system(size: size, weight: .black).width(.compressed).monospacedDigit())
                .tracking(-0.5)
                .foregroundColor(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if let unit {
                Text(unit)
                    .font(.plMetric(max(15, size * 0.30), weight: .heavy))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

/// Receipt-style aligned row: label left, mono value (+unit) right.
struct MetricRow: View {
    let label: String
    let value: String
    var unit: String? = nil
    var valueColor: Color = Theme.textPrimary
    var labelColor: Color = Theme.textSecondary
    var emphasized: Bool = false
    var leadingSymbol: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let leadingSymbol {
                Image(systemName: leadingSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(labelColor)
            }
            Text(label)
                .font(emphasized ? .plHeadline(15) : .plBody(15))
                .foregroundColor(labelColor)
            Spacer(minLength: 8)
            MonoMetric(value: value, unit: unit,
                       size: emphasized ? 19 : 16,
                       weight: emphasized ? .bold : .semibold,
                       color: valueColor)
        }
        .accessibilityElement(children: .combine)
    }
}
