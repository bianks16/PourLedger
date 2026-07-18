//
//  ScreenKit.swift
//  PourLedger
//
//  Shared screen + sheet chrome. Surface background, compressed-black titles,
//  cast icon buttons.
//

import SwiftUI

extension View {
    func screenBackground() -> some View {
        background(Theme.surface.ignoresSafeArea())
    }
}

/// Small square cast icon button (close, back-ish actions inside sheets).
struct CastIconButton: View {
    let systemImage: String
    var tint: Color = Theme.textPrimary
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 34, height: 34)
                .castSurface(fill: Theme.surfaceElevated)
        }
        .buttonStyle(PressSink())
    }
}

/// Sheet layout: grab-hint + title bar + scrollable content.
struct SheetScaffold<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var onClose: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.plStamp(24)).tracking(-0.3)
                        .foregroundColor(Theme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.plCaption(13))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                Spacer()
                CastIconButton(systemImage: "xmark", action: onClose)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 12)

            HairlineDivider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Theme.surface.ignoresSafeArea())
    }
}

/// A grouped cast panel with an optional section label.
struct CastPanel<Content: View>: View {
    var label: String? = nil
    var fill: Color = Theme.surfaceElevated
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let label { SectionLabel(text: label) }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .castSurface(fill: fill)
    }
}

/// Note / disclaimer line.
struct NoteLine: View {
    let text: String
    var systemImage: String = "info.circle"
    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textFaint)
            Text(text)
                .font(.plCaption(12.5))
                .foregroundColor(Theme.textFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
