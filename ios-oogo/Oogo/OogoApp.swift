//
//  OogoApp.swift
//  Oogo
//

import SwiftUI

@main
struct OogoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: OogoStore
    @State private var auth = AuthManager.shared
    @State private var sync: OogoSync

    init() {
        let store = OogoStore()
        _store = State(initialValue: store)
        _sync = State(initialValue: OogoSync(store: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(auth)
                .environment(sync)
                .preferredColorScheme(.light)
                .tint(OogoColor.ink)
                .onAppear {
                    NudgeInbox.shared.register()
                    store.refreshNudges()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    store.refreshNudges()
                    Task { await sync.sync() }
                }
                .task(id: auth.user?.id) {
                    // Fires on launch once auth resolves, and again on every sign-in.
                    guard auth.user != nil else { return }
                    await sync.sync()
                }
        }
    }
}
