//
//  PourStore.swift
//  PourLedger
//
//  Single source of truth for the working pour + the saved Sites ledger.
//  Saved pours → JSON file in Documents (schema-versioned). Working pour → mirrored
//  to UserDefaults for instant restore. No seed/demo data.
//

import Foundation
import Combine
import SwiftUI

private struct PersistedLibrary: Codable {
    var schemaVersion: Int
    var pours: [Pour]
}

final class PourStore: ObservableObject {
    /// The pour being built on the Pour screen.
    @Published var current: Pour
    /// Saved pours shown in Sites.
    @Published var saved: [Pour] = []

    private let schemaVersion = 1
    private let savedFileName = "pours.json"
    private let currentKey = "current.pour.v1"
    private var cancellables = Set<AnyCancellable>()
    private var isLoading = true

    init() {
        // Restore the working pour if present, else a fresh empty one.
        if let data = UserDefaults.standard.data(forKey: currentKey),
           let p = try? JSONDecoder().decode(Pour.self, from: data) {
            current = p
        } else {
            current = Pour()
        }
        loadSaved()
        isLoading = false

        // Debounced persistence — separate concerns but one cheap sink.
        $current
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.persistCurrent() }
            .store(in: &cancellables)

        $saved
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.persistSaved() }
            .store(in: &cancellables)
    }

    // MARK: - Element operations on the working pour

    func addElement(_ e: Element) {
        current.elements.append(e)
    }

    func updateElement(_ e: Element) {
        if let i = current.elements.firstIndex(where: { $0.id == e.id }) {
            current.elements[i] = e
        }
    }

    func deleteElement(_ e: Element) {
        current.elements.removeAll { $0.id == e.id }
    }

    func duplicateElement(_ e: Element) {
        var copy = e
        copy.id = UUID()
        if let i = current.elements.firstIndex(where: { $0.id == e.id }) {
            current.elements.insert(copy, at: i + 1)
        } else {
            current.elements.append(copy)
        }
    }

    /// Two-way binding for editing a specific element in place.
    func binding(for id: UUID) -> Binding<Element> {
        Binding(
            get: { self.current.elements.first(where: { $0.id == id }) ?? Element() },
            set: { newVal in
                if let i = self.current.elements.firstIndex(where: { $0.id == id }) {
                    self.current.elements[i] = newVal
                }
            }
        )
    }

    // MARK: - Sites ledger

    /// Save (or update) the working pour into the saved ledger.
    func saveCurrentToSites() {
        var p = current
        if p.siteName.trimmingCharacters(in: .whitespaces).isEmpty {
            p.siteName = ""
        }
        if let i = saved.firstIndex(where: { $0.id == p.id }) {
            saved[i] = p
        } else {
            saved.insert(p, at: 0)
        }
        current = p
    }

    var currentIsSaved: Bool { saved.contains { $0.id == current.id } }

    func newPour(settings: OrderSettings) {
        current = Pour(settings: settings)
    }

    /// Open a saved pour into the working area (continue editing the same record).
    func open(_ pour: Pour) {
        current = pour
    }

    func duplicateForNew(_ pour: Pour) {
        var copy = pour
        copy.id = UUID()
        copy.date = Date()
        copy.siteName = pour.displaySiteName + " (copy)"
        current = copy
    }

    func deleteSaved(_ pour: Pour) {
        saved.removeAll { $0.id == pour.id }
    }

    func clearAll() {
        saved.removeAll()
        current = Pour()
    }

    // MARK: - Persistence

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var savedURL: URL { documentsURL.appendingPathComponent(savedFileName) }

    private func loadSaved() {
        guard let data = try? Data(contentsOf: savedURL) else { return }
        guard let lib = try? JSONDecoder().decode(PersistedLibrary.self, from: data) else { return }
        // Migration hook: lib.schemaVersion < schemaVersion → transform here.
        saved = lib.pours
    }

    private func persistSaved() {
        guard !isLoading else { return }
        let lib = PersistedLibrary(schemaVersion: schemaVersion, pours: saved)
        guard let data = try? JSONEncoder().encode(lib) else { return }
        try? data.write(to: savedURL, options: .atomic)
    }

    private func persistCurrent() {
        guard !isLoading else { return }
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: currentKey)
        }
    }
}

private extension Pour {
    init(settings: OrderSettings) {
        self.init()
        self.settings = settings
    }
}
