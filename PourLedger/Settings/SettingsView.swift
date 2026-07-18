//
//  SettingsView.swift
//  PourLedger
//
//  Preferences — theme, currency, haptics, and the defaults that seed a new pour.
//  Every control has a real, persisted effect. No auth / login / profile.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    private let currencies = ["€", "£", "$", "kr", "zł"]

    var body: some View {
        SheetScaffold(title: "Settings", subtitle: "theme, currency, and pour defaults",
                      onClose: { dismiss() }) {
            CastPanel(label: "Appearance") {
                SectionLabel(text: "Theme")
                FormworkSegment(options: AppThemeMode.allCases,
                                label: { $0.label },
                                selection: $app.themeMode)
                SectionLabel(text: "Currency")
                FormworkSegment(options: currencies, label: { $0 }, selection: $app.currency)
            }

            CastPanel(label: "Feedback") {
                Toggle(isOn: $app.hapticsEnabled) {
                    Text("Haptics").font(.plHeadline(16)).foregroundColor(Theme.textPrimary)
                }
                .tint(Theme.accent)
            }

            CastPanel(label: "New-pour defaults") {
                Text("These seed the order settings whenever you start a new pour.")
                    .font(.plCaption(12.5)).foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                TickSlider(title: "Truck capacity", value: $app.defTruckCapacity,
                           range: 1...12, step: 0.5, unit: "m³", display: { Fmt.vol1($0) })
                TickSlider(title: "Supplier minimum", value: $app.defSupplierMin,
                           range: 0...12, step: 0.5, unit: "m³", display: { Fmt.vol1($0) })
                TickSlider(title: "Shrink", value: $app.defShrinkPct,
                           range: 0...0.15, step: 0.01, unit: "", display: { Fmt.pct($0) })
                TickSlider(title: "Waste", value: $app.defWastePct,
                           range: 0...0.25, step: 0.01, unit: "", display: { Fmt.pct($0) })
                TickSlider(title: "Price", value: $app.defPrice,
                           range: 0...400, step: 5, unit: "/m³",
                           display: { Fmt.money0($0, currency: app.currency) })
                TickSlider(title: "Part-load surcharge", value: $app.defSurcharge,
                           range: 0...120, step: 5, unit: "/m³",
                           display: { Fmt.money0($0, currency: app.currency) })
                TickSlider(title: "Bag yield", value: bagYieldLitres,
                           range: 5...25, step: 0.5, unit: "L/bag", display: { Fmt.int($0) })
            }

            HiVisButton(title: "Reset defaults", systemImage: "arrow.counterclockwise",
                        kind: .ghost) {
                app.resetDefaults()
                Haptics.warning()
            }

            NoteLine(text: "PourLedger keeps everything on your device. No account, no sign-in.")
        }
    }

    private var bagYieldLitres: Binding<Double> {
        Binding(get: { app.defBagYield * 1000 },
                set: { app.defBagYield = max(0.001, $0 / 1000) })
    }
}
