//
//  ContentView.swift
//  Oogo
//

import SwiftUI

struct ContentView: View {
    @Environment(OogoStore.self) private var store

    var body: some View {
        ZStack {
            if store.hasOnboarded {
                RootTabView()
                    .transition(.opacity)
            } else {
                OnboardingView(onDone: {})
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: store.hasOnboarded)
    }
}

#Preview {
    let store = OogoStore(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    return ContentView()
        .environment(store)
        .environment(AuthManager.shared)
        .environment(OogoSync(store: store))
}
