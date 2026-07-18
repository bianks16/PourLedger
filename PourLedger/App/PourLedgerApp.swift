//
//  PourLedgerApp.swift
//  PourLedger
//

import SwiftUI

@main
struct PourLedgerApp: App {
    @StateObject private var store = PourStore()
    @StateObject private var app = AppState()

    init() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-resetSupplierSetup") {
            UserDefaults.standard.set(false, forKey: "hasSeenSupplierSetup")
        }
        if args.contains("-clearData") {
            UserDefaults.standard.removeObject(forKey: "current.pour.v1")
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            try? FileManager.default.removeItem(at: docs.appendingPathComponent("pours.json"))
        }
        if args.contains("-seedSample") {   // QA-only; never a default first-launch behavior
            var p = Pour()
            p.siteName = "Maple St foundation"
            var slab = Element.new(.slab); slab.name = "Ground slab"
            slab.dims.l = 8; slab.dims.w = 5; slab.dims.t = 0.2
            var strip = Element.new(.strip); strip.name = "Perimeter footing"
            strip.dims.l = 20; strip.dims.w = 0.3; strip.dims.d = 0.35
            var col = Element.new(.columnRect); col.name = "Columns"
            col.dims.sectionA = 0.3; col.dims.sectionB = 0.3; col.dims.h = 3; col.count = 6
            p.elements = [slab, strip, col]
            if let data = try? JSONEncoder().encode(p) {
                UserDefaults.standard.set(data, forKey: "current.pour.v1")
            }
        }
        if args.contains("-seedFull") {      // QA-only: exact full-load pour
            var p = Pour(); p.siteName = "Depot slab"
            var slab = Element.new(.slab); slab.name = "Yard slab"
            slab.dims.l = 9.343; slab.dims.w = 8; slab.dims.t = 0.2   // net ≈ 14.95 → V_req 16.0
            p.elements = [slab]
            if let data = try? JSONEncoder().encode(p) {
                UserDefaults.standard.set(data, forKey: "current.pour.v1")
            }
        }
        if args.contains("-seedTiny") {       // QA-only: tiny underload (r≈0.3) → round-to-full
            var p = Pour(); p.siteName = "Loading bay"
            var slab = Element.new(.slab); slab.name = "Bay slab"
            slab.dims.l = 7.75; slab.dims.w = 5; slab.dims.t = 0.2   // net 7.75 → V_req 8.3, r 0.3
            p.elements = [slab]
            if let data = try? JSONEncoder().encode(p) {
                UserDefaults.standard.set(data, forKey: "current.pour.v1")
            }
        }
        if args.contains("-seedSites") {      // QA-only: populate the Sites ledger
            struct SeedLib: Codable { var schemaVersion = 1; var pours: [Pour] }
            func mk(_ name: String, _ l: Double, _ w: Double, _ t: Double) -> Pour {
                var p = Pour(); p.siteName = name
                var s = Element.new(.slab); s.dims.l = l; s.dims.w = w; s.dims.t = t
                p.elements = [s]; return p
            }
            let lib = SeedLib(pours: [mk("Maple St foundation", 8, 5, 0.2),
                                      mk("Harbour retaining wall", 6, 0.3, 2.4),
                                      mk("Depot slab", 9.343, 8, 0.2)])
            if let data = try? JSONEncoder().encode(lib) {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                try? data.write(to: docs.appendingPathComponent("pours.json"), options: .atomic)
            }
        }
        Self.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .environmentObject(store)
                .environmentObject(app)
        }
    }

    private static func configureAppearance() {
        let a = UINavigationBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor = UIColor.dynamic(light: "#E7E8E4", dark: "#1B1C18")
        a.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = a
        UINavigationBar.appearance().scrollEdgeAppearance = a
        UINavigationBar.appearance().compactAppearance = a
    }
}
