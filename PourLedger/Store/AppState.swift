//
//  AppState.swift
//  PourLedger
//
//  App-wide preferences. @AppStorage-backed so they persist and apply immediately.
//  No auth / login / profile.
//

import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

final class AppState: ObservableObject {
    @AppStorage("themeMode") var themeModeRaw = AppThemeMode.system.rawValue {
        didSet { objectWillChange.send() }
    }
    @AppStorage("currency") var currency = "€" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("hapticsEnabled") var hapticsEnabled = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("hasSeenSupplierSetup") var hasSeenSupplierSetup = false {
        didSet { objectWillChange.send() }
    }

    // Defaults that seed a NEW pour's OrderSettings.
    @AppStorage("def_truckCapacity") var defTruckCapacity = 8.0   { didSet { objectWillChange.send() } }
    @AppStorage("def_supplierMin")   var defSupplierMin   = 3.0   { didSet { objectWillChange.send() } }
    @AppStorage("def_shrinkPct")     var defShrinkPct     = 0.02  { didSet { objectWillChange.send() } }
    @AppStorage("def_wastePct")      var defWastePct      = 0.05  { didSet { objectWillChange.send() } }
    @AppStorage("def_price")         var defPrice         = 120.0 { didSet { objectWillChange.send() } }
    @AppStorage("def_bagYield")      var defBagYield      = 0.011 { didSet { objectWillChange.send() } }
    @AppStorage("def_surcharge")     var defSurcharge     = 0.0   { didSet { objectWillChange.send() } }

    var themeMode: AppThemeMode {
        get { AppThemeMode(rawValue: themeModeRaw) ?? .system }
        set { themeModeRaw = newValue.rawValue }
    }
    var colorScheme: ColorScheme? { themeMode.colorScheme }

    func defaultSettings() -> OrderSettings {
        OrderSettings(shrinkPct: defShrinkPct,
                      wastePct: defWastePct,
                      truckCapacity: defTruckCapacity,
                      supplierMin: defSupplierMin,
                      partLoadSurcharge: defSurcharge,
                      pricePerM3: defPrice,
                      bagYield: defBagYield)
    }

    func money(_ v: Double) -> String { Fmt.money(v, currency: currency) }
    func money0(_ v: Double) -> String { Fmt.money0(v, currency: currency) }

    func resetDefaults() {
        defTruckCapacity = 8.0
        defSupplierMin = 3.0
        defShrinkPct = 0.02
        defWastePct = 0.05
        defPrice = 120.0
        defBagYield = 0.011
        defSurcharge = 0.0
    }
}
