//
//  OogSnapshotTests.swift
//  OogoTests
//
//  Renders Oog clips and the workout screen to PNG so they can be eyeballed
//  without a Mac. Only runs when OOG_SNAPSHOT_DIR is set (CI passes it in as
//  TEST_RUNNER_OOG_SNAPSHOT_DIR); otherwise every test returns at once.
//

import SwiftUI
import Testing
import UIKit
@testable import Oogo

@MainActor
struct OogSnapshotTests {
    private var outputDirectory: URL? {
        guard let path = ProcessInfo.processInfo.environment["OOG_SNAPSHOT_DIR"], !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    @Test func contactSheetPerPattern() throws {
        guard let directory = outputDirectory else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for pattern in MovementPattern.allCases {
            let sheet = OogContactSheet(movements: MovementLibrary.movements(for: pattern),
                                        times: [0, 1.0, 2.0, 3.0, 4.5, 6.5])
            try write(sheet, scale: 1.5, to: directory.appendingPathComponent("sheet-\(pattern.rawValue).png"))
        }
    }

    @Test func workoutScreen() throws {
        guard let directory = outputDirectory else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = OogoStore(defaults: UserDefaults(suiteName: "oog-snapshots") ?? .standard)
        let picks = ["two-hand-swing", "goblet-squat", "pull-up", "halo", "walking-lunge"]
        let devices: [(name: String, size: CGSize)] = [
            ("iphone16", CGSize(width: 393, height: 852)),
            ("iphoneSE", CGSize(width: 375, height: 667)),
        ]
        for id in picks {
            guard let movement = MovementLibrary.all.first(where: { $0.id == id }) else { continue }
            let session = ActiveSession(dayType: .hunt, movements: [movement], rounds: 3, restSeconds: 60)
            for device in devices {
                let screen = SessionRunnerView(runner: SessionRunner(session: session), onQuit: {})
                    .environment(store)
                    .frame(width: device.size.width, height: device.size.height)
                try write(screen, scale: 2, to: directory.appendingPathComponent("workout-\(id)-\(device.name).png"))
            }
        }
    }

    private func write(_ view: some View, scale: CGFloat, to url: URL) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let data = renderer.uiImage?.pngData() else {
            Issue.record("Could not render \(url.lastPathComponent)")
            return
        }
        try data.write(to: url)
    }
}

/// One row per movement: its name, then the clip frozen at each time.
private struct OogContactSheet: View {
    let movements: [Movement]
    let times: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(movements) { movement in
                HStack(spacing: 8) {
                    Text(movement.name)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 150, alignment: .leading)
                    if let clip = OogClipLibrary.shared.clip(for: movement.id) {
                        ForEach(times, id: \.self) { t in
                            Canvas { context, size in
                                OogRenderer.draw(clip, at: t, in: context, size: size)
                            }
                            .frame(width: 130, height: 130)
                            .background(OogoColor.page)
                            .overlay(alignment: .topLeading) {
                                Text(String(format: "%.1fs", t))
                                    .font(.system(size: 9, weight: .medium).monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .padding(4)
                            }
                        }
                    } else {
                        Text("NO CLIP")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 130, height: 130)
                            .background(Color.red)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
    }
}
