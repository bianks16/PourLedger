//
//  SitesView.swift
//  PourLedger
//
//  Saved pours as a glanceable truck-ledger. Drill list of PourCards. Spec §5.5.
//

import SwiftUI

struct SitesView: View {
    @EnvironmentObject var store: PourStore
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    private var sorted: [Pour] {
        store.saved.sorted {
            if $0.displaySiteName.localizedCaseInsensitiveCompare($1.displaySiteName) == .orderedSame {
                return $0.date > $1.date
            }
            return $0.displaySiteName.localizedCaseInsensitiveCompare($1.displaySiteName) == .orderedAscending
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            HairlineDivider()
            if store.saved.isEmpty {
                ScrollView { SitesEmptyView(onNew: startNew).padding(.top, 20) }
            } else {
                List {
                    ForEach(sorted) { pour in
                        Button { store.open(pour); dismiss() } label: {
                            PourCard(pour: pour, currency: app.currency)
                        }
                        .buttonStyle(PressSink())
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation(Theme.drop) { store.deleteSaved(pour) }
                                Haptics.medium()
                            } label: { Label("Delete", systemImage: "trash") }
                            Button {
                                store.duplicateForNew(pour)
                                Haptics.rigid()
                                dismiss()
                            } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                                .tint(Theme.accentMuted)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 10)
            }
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { startNew() } label: {
                    Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
                .buttonStyle(PressSink())
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("SITES").font(.plStamp(28)).tracking(-0.3).foregroundColor(Theme.textPrimary)
            Spacer()
            MonoMetric(value: "\(store.saved.count)", unit: store.saved.count == 1 ? "pour" : "pours",
                       size: 15, weight: .bold, color: Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    private func startNew() {
        withAnimation(Theme.drop) { store.newPour(settings: app.defaultSettings()) }
        dismiss()
    }
}
