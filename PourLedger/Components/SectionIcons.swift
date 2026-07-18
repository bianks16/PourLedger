//
//  SectionIcons.swift
//  PourLedger
//
//  Bespoke section marks — each element type reads as its own cross-section
//  (slab bar / L-footing / column square-or-round / I-beam), NOT a generic symbol.
//  Spec §3 iconography.
//

import SwiftUI

/// The section outline path for an element type, drawn in the given rect.
struct SectionGlyph: Shape {
    let type: ElementType

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: rect.width * 0.06, dy: rect.height * 0.06)
        var p = Path()
        switch type {
        case .slab:
            let h = r.height * 0.34
            let y = r.midY - h / 2
            p.addRect(CGRect(x: r.minX, y: y, width: r.width, height: h))

        case .strip:
            // L-footing: stem on the left, foot extends right at the base.
            let x0 = r.minX + r.width * 0.22
            let yTop = r.minY + r.height * 0.12
            let xStemR = x0 + r.width * 0.28
            let yFootTop = r.maxY - r.height * 0.32
            let xFootR = r.maxX - r.width * 0.10
            let yBot = r.maxY - r.height * 0.12
            p.move(to: CGPoint(x: x0, y: yTop))
            p.addLine(to: CGPoint(x: xStemR, y: yTop))
            p.addLine(to: CGPoint(x: xStemR, y: yFootTop))
            p.addLine(to: CGPoint(x: xFootR, y: yFootTop))
            p.addLine(to: CGPoint(x: xFootR, y: yBot))
            p.addLine(to: CGPoint(x: x0, y: yBot))
            p.closeSubpath()

        case .columnRect:
            let s = min(r.width, r.height) * 0.62
            p.addRect(CGRect(x: r.midX - s / 2, y: r.midY - s / 2, width: s, height: s))

        case .columnRound:
            let s = min(r.width, r.height) * 0.66
            p.addEllipse(in: CGRect(x: r.midX - s / 2, y: r.midY - s / 2, width: s, height: s))

        case .beam:
            let cx = r.midX
            let fw = r.width * 0.62, ww = r.width * 0.22, fh = r.height * 0.17
            let top = r.minY + r.height * 0.16, bot = r.maxY - r.height * 0.16
            let left = cx - fw / 2, right = cx + fw / 2
            let wl = cx - ww / 2, wr = cx + ww / 2
            let pts = [
                CGPoint(x: left, y: top), CGPoint(x: right, y: top),
                CGPoint(x: right, y: top + fh), CGPoint(x: wr, y: top + fh),
                CGPoint(x: wr, y: bot - fh), CGPoint(x: right, y: bot - fh),
                CGPoint(x: right, y: bot), CGPoint(x: left, y: bot),
                CGPoint(x: left, y: bot - fh), CGPoint(x: wl, y: bot - fh),
                CGPoint(x: wl, y: top + fh), CGPoint(x: left, y: top + fh)
            ]
            p.addLines(pts)
            p.closeSubpath()

        case .custom:
            let s = min(r.width, r.height) * 0.6
            let rect = CGRect(x: r.midX - s / 2, y: r.midY - s / 2, width: s, height: s)
            p.addRect(rect)
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        return p
    }
}

struct SectionIcon: View {
    let type: ElementType
    var size: CGFloat = 26
    var color: Color = Theme.textPrimary
    var filled: Bool = true

    var body: some View {
        ZStack {
            if filled {
                SectionGlyph(type: type)
                    .fill(color.opacity(0.14))
            }
            SectionGlyph(type: type)
                .stroke(color, style: StrokeStyle(lineWidth: max(1.5, size * 0.075),
                                                  lineJoin: .miter))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
