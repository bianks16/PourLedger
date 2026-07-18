//
//  RootFlowView.swift
//  PourLedger
//
//  Splash → Pour. No onboarding gate — the empty Pour teaches by doing (spec §8).
//

import SwiftUI

struct RootFlowView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSplash = true

    var body: some View {
        ZStack {
            PourView()
                .opacity(showSplash ? 0 : 1)
            if showSplash {
                SplashView()
                    .transition(reduceMotion
                                ? .opacity
                                : .asymmetric(insertion: .identity,
                                              removal: .opacity.combined(with: .scale(scale: 0.97))))
                    .zIndex(1)
            }
        }
        .preferredColorScheme(app.colorScheme)
        .task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)   // one full loop, within policy
            withAnimation(reduceMotion ? .easeInOut(duration: 0.35) : Theme.viscous) {
                showSplash = false
            }
        }
    }
}
