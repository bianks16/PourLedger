//
//  PourView.swift
//  PourLedger
//
//  ROOT. Sticky LoadGauge hero + build-up stack of cast-blocks + "+ Element".
//  iPhone: hero → stack, order breakdown as a sheet from the gauge.
//  iPad (regular width): two columns — build-up stack left, live order breakdown right.
//  Spec §5.1 / §9.
//

import SwiftUI

private struct ConfiguratorItem: Identifiable {
    let id = UUID()
    let element: Element
    let editing: Bool
}

// MARK: - Hero

struct PourHero: View {
    let result: PourResult
    var onTapGauge: (() -> Void)?

    var body: some View {
        if let onTapGauge {
            Button(action: onTapGauge) { content }
                .buttonStyle(PressSink(scale: 0.99))
                .accessibilityHint("Opens the order breakdown")
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 12) {
            LoadGauge(fills: result.gaugeFills,
                      usesNumericSummary: result.usesNumericSummary,
                      full: result.full,
                      partialRemainder: result.partialRemainder,
                      isFullLoad: result.isFullLoad,
                      accessibilityLabel: result.gaugeAccessibilityLabel)
                .frame(height: 92)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    MonoDisplay(value: Fmt.vol1(result.vNet), unit: "m³", size: 52)
                    Text(result.mode == .handMix ? "net to mix" : "net poured")
                        .font(.plCaption(12)).foregroundColor(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 7) {
                    if result.mode == .handMix {
                        MonoMetric(value: "\(result.handMix?.bags ?? 0)", unit: "bags",
                                   size: 20, weight: .bold)
                    } else {
                        MonoMetric(value: "\(result.trucks)",
                                   unit: result.trucks == 1 ? "truck" : "trucks",
                                   size: 20, weight: .bold)
                    }
                    summaryChip
                }
            }

            if onTapGauge != nil {
                HStack(spacing: 4) {
                    Spacer()
                    Text("ORDER BREAKDOWN").font(.plStamp(11)).tracking(0.7)
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .black))
                }
                .foregroundColor(Theme.accent)
            }
        }
    }

    @ViewBuilder private var summaryChip: some View {
        if result.isEmpty {
            StampChip(text: "0 trucks", kind: .neutral)
        } else if result.mode == .handMix {
            StampChip(text: "hand-mix", kind: .neutral)
        } else if result.isFullLoad {
            StampChip(text: "FULL LOAD", systemImage: "checkmark.seal.fill", kind: .hiVis)
        } else if result.isBelowMinimum {
            StampChip(text: "min \(Fmt.vol1(result.ordered)) m³", kind: .rust)
        } else if result.waste > 0.001 {
            StampChip(text: "waste \(Fmt.vol1(result.waste)) m³", kind: .rust)
        }
    }
}

// MARK: - Root

struct PourView: View {
    @EnvironmentObject var store: PourStore
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var configuratorItem: ConfiguratorItem?
    @State private var showOrder = false
    @State private var showSettings = false
    @State private var showSites = false
    @State private var showMixIpad = false
    @State private var renaming = false
    @State private var renameText = ""

    private var result: PourResult { LoadPacker.compute(pour: store.current) }
    private var isRegular: Bool { hSize == .regular }
    private var isEmpty: Bool { store.current.elements.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if isRegular { iPadLayout } else { phoneLayout }
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .navigationDestination(isPresented: $showSites) { SitesView() }
            .sheet(item: $configuratorItem) { item in
                ElementConfiguratorView(editing: item.editing, element: item.element) { e in
                    withAnimation(Theme.drop) {
                        if item.editing { store.updateElement(e) } else { store.addElement(e) }
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showOrder) { OrderBreakdownView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showMixIpad) { MixAndBagsView() }
            .onAppear(perform: handleDebugArgs)
            .alert("Site name", isPresented: $renaming) {
                TextField("e.g. Maple St foundation", text: $renameText)
                Button("Save") { store.current.siteName = renameText }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Name this pour for your Sites ledger.")
            }
        }
    }

    // MARK: Layouts

    private var phoneLayout: some View {
        VStack(spacing: 0) {
            PourHero(result: result, onTapGauge: { showOrder = true })
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 14)
            HairlineDivider()
            if isEmpty {
                ScrollView { EmptyPourComposition(onAdd: openNew).padding(.top, 16) }
            } else {
                elementsList
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !isEmpty { bottomAddBar }
        }
    }

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    SectionLabel(text: "Build-up stack")
                    Spacer()
                    MonoMetric(value: "\(store.current.elements.count)", unit: "elements",
                               size: 13, weight: .bold, color: Theme.textSecondary)
                }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 6)
                if isEmpty {
                    ScrollView { EmptyPourComposition(onAdd: openNew).padding(.top, 16) }
                } else {
                    elementsList
                }
                bottomAddBar
            }
            .frame(maxWidth: .infinity)

            Rectangle().fill(Theme.divider).frame(width: 1).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PourHero(result: result, onTapGauge: nil)
                    if isEmpty {
                        EmptyReceipt(onClose: nil)
                    } else {
                        OrderContent(onApplied: {}, presentMix: { showMixIpad = true })
                    }
                }
                .padding(16)
            }
            .frame(width: 400)
            .background(Theme.surface)
        }
    }

    private var elementsList: some View {
        List {
            ForEach(store.current.elements) { el in
                Button { configuratorItem = ConfiguratorItem(element: el, editing: true) } label: {
                    ElementBlock(element: el)
                }
                .buttonStyle(PressSink())
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        withAnimation(Theme.drop) { store.deleteElement(el) }
                        Haptics.light()
                    } label: { Label("Delete", systemImage: "trash") }
                    Button {
                        withAnimation(Theme.drop) { store.duplicateElement(el) }
                        Haptics.rigid()
                    } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                        .tint(Theme.accentMuted)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 10)
    }

    private var bottomAddBar: some View {
        VStack(spacing: 0) {
            HairlineDivider()
            HiVisButton(title: "Add element", systemImage: "plus", kind: .solid) { openNew() }
                .padding(16)
        }
        .background(Theme.surface)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { showSites = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "square.stack.3d.up.fill").font(.system(size: 14, weight: .bold))
                    Text("Sites").font(.plStamp(14))
                }
                .foregroundColor(Theme.accent)
            }
            .buttonStyle(PressSink())
        }
        ToolbarItem(placement: .principal) {
            Button {
                renameText = store.current.siteName
                renaming = true
            } label: {
                HStack(spacing: 5) {
                    Text(store.current.displaySiteName)
                        .font(.plStamp(18)).tracking(-0.2)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Image(systemName: "pencil").font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .buttonStyle(PressSink())
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button { store.saveCurrentToSites(); Haptics.success() } label: {
                    Label("Save to Sites", systemImage: "tray.and.arrow.down.fill")
                }
                Button { withAnimation(Theme.drop) { store.newPour(settings: app.defaultSettings()) } } label: {
                    Label("New pour", systemImage: "plus.rectangle.on.rectangle")
                }
                Divider()
                Button { showSettings = true } label: {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
            } label: {
                Image(systemName: "ellipsis.circle").font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.accent)
            }
        }
    }

    private func openNew() {
        configuratorItem = ConfiguratorItem(element: Element.new(.slab), editing: false)
    }

    /// QA-only auto-present, gated behind launch args — never fires in normal use.
    private func handleDebugArgs() {
        let args = ProcessInfo.processInfo.arguments
        func after(_ block: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: block)
        }
        if args.contains("-showOrder") { after { showOrder = true } }
        if args.contains("-showConfig") {
            after { configuratorItem = ConfiguratorItem(element: sampleSlab(), editing: false) }
        }
        if args.contains("-showSettings") { after { showSettings = true } }
        if args.contains("-showSites") { after { showSites = true } }
        if args.contains("-showMix") { after { showMixIpad = true } }
    }

    private func sampleSlab() -> Element {
        var e = Element.new(.slab); e.name = "Ground slab"
        e.dims.l = 8; e.dims.w = 5; e.dims.t = 0.2
        return e
    }
}
