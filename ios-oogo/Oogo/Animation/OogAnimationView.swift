//
//  OogAnimationView.swift
//  Oogo
//
//  Oog showing a movement on a ten-second loop, drawn live as vectors.
//

import SwiftUI

/// Loads OogClips.json once and hands out compiled clips by movement id.
@MainActor
final class OogClipLibrary {
    static let shared = OogClipLibrary()

    private var defs: [String: OogClipDef] = [:]
    private var compiled: [String: OogClip] = [:]
    private var isLoaded = false

    func clip(for movementID: String) -> OogClip? {
        loadIfNeeded()
        if let clip = compiled[movementID] { return clip }
        guard let def = defs[movementID] else { return nil }
        let clip = OogClip(def: def)
        compiled[movementID] = clip
        return clip
    }

    func hasClip(for movementID: String) -> Bool {
        loadIfNeeded()
        return defs[movementID] != nil
    }

    private func loadIfNeeded() {
        guard !isLoaded else { return }
        isLoaded = true
        let url = Bundle.main.url(forResource: "OogClips", withExtension: "json")
            ?? Bundle.main.url(forResource: "OogClips", withExtension: "json", subdirectory: "Resources")
        guard let url else {
            assertionFailure("OogClips.json missing from the app bundle")
            return
        }
        let file: OogClipFile
        do {
            file = try OogClipFile.load(from: url)
        } catch {
            assertionFailure("OogClips.json failed to decode: \(error)")
            return
        }
        for def in file.clips {
            for id in [def.movementId].compactMap({ $0 }) + (def.movementAliases ?? []) where defs[id] == nil {
                defs[id] = def
            }
        }
    }
}

/// Play/pause bookkeeping so a paused clip resumes where it stopped.
private struct OogClock {
    var banked: TimeInterval = 0
    var runningSince: Date?

    func time(at date: Date) -> TimeInterval {
        guard let start = runningSince else { return banked }
        return banked + max(0, date.timeIntervalSince(start))
    }

    mutating func run(at date: Date) {
        guard runningSince == nil else { return }
        runningSince = date
    }

    mutating func hold(at date: Date) {
        guard let start = runningSince else { return }
        banked += max(0, date.timeIntervalSince(start))
        runningSince = nil
    }
}

struct OogAnimationView: View {
    let movement: Movement
    /// Freezes Oog mid-move, e.g. while the workout is paused.
    var isPaused: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var clock = OogClock()
    /// With Reduce Motion on, Oog waits still until tapped.
    @State private var playsWithReducedMotion = false

    private var isFrozen: Bool { isPaused || (reduceMotion && !playsWithReducedMotion) }

    var body: some View {
        Group {
            if let clip = OogClipLibrary.shared.clip(for: movement.id) {
                TimelineView(.animation(paused: isFrozen)) { timeline in
                    let t = clock.time(at: timeline.date)
                    Canvas { context, size in
                        OogRenderer.draw(clip, at: t, in: context, size: size)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if reduceMotion && !isPaused {
                        Image(systemName: playsWithReducedMotion ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(OogoColor.secondaryText)
                            .frame(width: 30, height: 30)
                            .background { Circle().fill(OogoColor.cloud) }
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(.rect)
                .onTapGesture {
                    guard reduceMotion else { return }
                    playsWithReducedMotion.toggle()
                }
            } else {
                Image("OogWave")
                    .resizable()
                    .scaledToFit()
                    .padding(28)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { sync(frozen: isFrozen) }
        .onChange(of: isFrozen) { _, frozen in sync(frozen: frozen) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("oog show \(movement.name.lowercased())")
        .accessibilityAddTraits(.isImage)
    }

    private func sync(frozen: Bool) {
        if frozen {
            clock.hold(at: .now)
        } else {
            clock.run(at: .now)
        }
    }
}

#Preview {
    OogAnimationView(movement: MovementLibrary.all.first { $0.id == "two-hand-swing" } ?? MovementLibrary.all[0])
        .frame(width: 320, height: 320)
        .background(OogoColor.page)
}
