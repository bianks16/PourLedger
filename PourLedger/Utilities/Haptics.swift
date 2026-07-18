//
//  Haptics.swift
//  PourLedger
//
//  Central haptic map. Respects the user's "haptics" preference (@AppStorage-backed).
//

import UIKit

enum Haptics {
    /// Mirrors AppStorage("hapticsEnabled"); defaults to on when unset.
    static var enabled: Bool {
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }

    static func rigid()  { impact(.rigid) }   // add a block
    static func soft()   { impact(.soft) }    // crossed an underload threshold
    static func light()  { impact(.light) }   // delete / minor
    static func medium() { impact(.medium) }  // commit / destructive-in-list
    static func selection() {
        guard enabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }

    static func success() {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }
    static func warning() {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }
}
