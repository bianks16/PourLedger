//
//  Components.swift
//  PourLedger
//
//  Cast-block surfaces, buttons, segmented control, stamp chips. Hairline elevation,
//  4pt radius, 1px chamfer top edge. No drop shadows, no capsules. Spec §3 / §6.
//

import SwiftUI

// MARK: - Chamfer edge + cast surface

/// The 1px lit "formwork" edge along the top of a cast block.
struct ChamferTopEdge: Shape {
    var radius: CGFloat = Theme.radius
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset: CGFloat = 0.75
        p.move(to: CGPoint(x: rect.minX + radius, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY + inset))
        return p
    }
}

struct CastSurface: ViewModifier {
    var fill: Color = Theme.surfaceElevated
    var radius: CGFloat = Theme.radius
    var stroke: Color = Theme.hairline
    var chamfer: Bool = true

    func body(content: Content) -> some View {
        content.background(
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(fill)
                if chamfer {
                    ChamferTopEdge(radius: radius).stroke(Theme.chamfer, lineWidth: 1)
                }
                RoundedRectangle(cornerRadius: radius).stroke(stroke, lineWidth: Theme.hairlineWidth)
            }
        )
    }
}

extension View {
    func castSurface(fill: Color = Theme.surfaceElevated,
                     radius: CGFloat = Theme.radius,
                     stroke: Color = Theme.hairline,
                     chamfer: Bool = true) -> some View {
        modifier(CastSurface(fill: fill, radius: radius, stroke: stroke, chamfer: chamfer))
    }
}

// MARK: - Press feedback (sinks into fresh concrete)

struct PressSink: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Theme.press, value: configuration.isPressed)
    }
}

// MARK: - Hi-vis CTA button

struct HiVisButton: View {
    enum Kind { case solid, ghost, danger }
    let title: String
    var systemImage: String? = nil
    var kind: Kind = .solid
    var fullWidth: Bool = true
    var enabled: Bool = true
    let action: () -> Void

    private var fg: Color {
        switch kind {
        case .solid:  return Theme.accentInk
        case .ghost:  return Theme.accent
        case .danger: return Color.dyn(light: "#FBF3F0", dark: "#1B1C18")
        }
    }
    private var bg: Color {
        switch kind {
        case .solid:  return Theme.accent
        case .ghost:  return Theme.surfaceElevated
        case .danger: return Theme.short
        }
    }
    private var border: Color {
        switch kind {
        case .solid:  return Theme.accent
        case .ghost:  return Theme.hairline
        case .danger: return Theme.short
        }
    }

    var body: some View {
        Button(action: { if enabled { action() } }) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 15, weight: .bold))
                }
                Text(title.uppercased())
                    .font(.plStamp(15)).tracking(0.5)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .foregroundColor(fg)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.radius).fill(bg)
                    if kind != .ghost {
                        ChamferTopEdge().stroke(Color.white.opacity(0.18), lineWidth: 1)
                    }
                    RoundedRectangle(cornerRadius: Theme.radius).stroke(border, lineWidth: 1)
                }
            )
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(PressSink())
        .disabled(!enabled)
    }
}

// MARK: - Formwork segmented control (hard rectangles, no capsules)

struct FormworkSegment<T: Hashable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T
    var icon: ((T) -> AnyView)? = nil
    var onChange: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                let selected = opt == selection
                Button {
                    if !selected {
                        Haptics.selection()
                        withAnimation(Theme.slide) { selection = opt }
                        onChange?()
                    }
                } label: {
                    VStack(spacing: 5) {
                        if let icon {
                            icon(opt)
                        }
                        Text(label(opt))
                            .font(.plStamp(12)).tracking(0.3)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(selected ? Theme.accentInk : Theme.textSecondary)
                    .background(selected ? Theme.accent : Theme.surfaceElevated)
                    .overlay(alignment: .leading) {
                        if idx != 0 {
                            Rectangle().fill(Theme.hairline).frame(width: 1)
                        }
                    }
                }
                .buttonStyle(PressSink(scale: 0.96))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.hairline, lineWidth: 1))
        .overlay(ChamferTopEdge().stroke(Theme.chamfer, lineWidth: 1))
    }
}

// MARK: - Stamp chips (waste / FULL LOAD / labels)

struct StampChip: View {
    enum Kind { case hiVis, rust, short, neutral }
    let text: String
    var systemImage: String? = nil
    var kind: Kind = .neutral

    private var fg: Color {
        switch kind {
        case .hiVis:   return Theme.accentInk
        case .rust:    return Theme.warning
        case .short:   return Theme.short
        case .neutral: return Theme.textSecondary
        }
    }
    private var bg: Color {
        switch kind {
        case .hiVis:   return Theme.accent
        case .rust:    return Theme.warning.opacity(0.14)
        case .short:   return Theme.short.opacity(0.14)
        case .neutral: return Theme.surfaceElevated
        }
    }
    private var border: Color {
        switch kind {
        case .hiVis:   return Theme.accent
        case .rust:    return Theme.warning.opacity(0.55)
        case .short:   return Theme.short.opacity(0.55)
        case .neutral: return Theme.hairline
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 11, weight: .black))
            }
            Text(text.uppercased()).font(.plStamp(12)).tracking(0.6)
        }
        .foregroundColor(fg)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Theme.radiusSmall).fill(bg)
                RoundedRectangle(cornerRadius: Theme.radiusSmall).stroke(border, lineWidth: 1)
            }
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Small building blocks

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.plStamp(12)).tracking(0.8)
            .foregroundColor(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HairlineDivider: View {
    var body: some View { Rectangle().fill(Theme.divider).frame(height: 1) }
}
