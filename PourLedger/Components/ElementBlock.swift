//
//  ElementBlock.swift
//  PourLedger
//
//  A "cast" element block — section glyph, name, mono dimensions, subtotal, chamfer top.
//  Reads as an object poured into the stack, not a rounded row.
//

import SwiftUI

struct ElementBlock: View {
    let element: Element

    private var valid: Bool { element.isValid }

    var body: some View {
        HStack(spacing: 12) {
            SectionIcon(type: element.type, size: 30,
                        color: valid ? Theme.textPrimary : Theme.short)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(element.displayName)
                        .font(.plHeadline(16))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1).truncationMode(.tail)
                    if element.count > 1 {
                        Text("×\(element.count)")
                            .font(.plMetric(13, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                }
                if valid {
                    Text(ElementBlock.dimsSummary(element))
                        .font(.plMetric(12.5, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                } else {
                    StampChip(text: "check dimensions", systemImage: "exclamationmark.triangle.fill", kind: .short)
                }
            }

            Spacer(minLength: 6)

            MonoMetric(value: Fmt.vol2(element.volume), unit: "m³",
                       size: 18, weight: .bold,
                       color: valid ? Theme.textPrimary : Theme.short)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .castSurface(fill: Theme.surfaceElevated)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(valid ? Theme.accent : Theme.short)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 1))
                .padding(.vertical, 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(element.displayName), \(element.type.label), \(Fmt.vol2(element.volume)) cubic metres")
    }

    /// Compact mono dimension line per type (mm for sections/thickness, m for lengths).
    static func dimsSummary(_ e: Element) -> String {
        let d = e.dims
        func m(_ v: Double) -> String { Fmt.vol(v, decimals: 2) }
        func mm(_ v: Double) -> String { Fmt.mm(v) }
        switch e.type {
        case .slab:
            return "\(m(d.l)) × \(m(d.w)) m · \(mm(d.t)) mm"
        case .strip:
            return "\(m(d.l)) m run · \(mm(d.w))×\(mm(d.d)) mm"
        case .columnRect:
            return "\(mm(d.sectionA))×\(mm(d.sectionB)) mm · h \(m(d.h)) m"
        case .columnRound:
            return "⌀\(mm(d.diameter)) mm · h \(m(d.h)) m"
        case .beam:
            return "\(mm(d.sectionA))×\(mm(d.sectionB)) mm · \(m(d.length)) m"
        case .custom:
            return "\(m(d.l)) × \(m(d.w)) × \(m(d.d)) m"
        }
    }
}
