//
//  OogEngineTests.swift
//  OogoTests
//
//  Proves the Swift Oog engine poses Oog exactly like animation/engine.js.
//  Fixtures/OogGolden.json is written by `node animation/export.js` from the
//  real JS engine; re-run it whenever a clip or the engine changes.
//

import Foundation
import SwiftUI
import Testing
@testable import Oogo

private final class BundleToken {}

struct OogEngineTests {
    // Clips with a baked `post` hook are sampled at 240 points per rep, so they
    // trail the JS by up to ~0.7 degrees around a foot strike. Everything else
    // differs only by the 4-decimal rounding in OogClips.json.
    private let exactTolerance = 0.01
    private let bakedTolerance = 0.75

    private func loadClips() throws -> [String: OogClipDef] {
        let url = try #require(Bundle.main.url(forResource: "OogClips", withExtension: "json"))
        let file = try OogClipFile.load(from: url)
        return Dictionary(file.clips.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private func loadGolden() throws -> [GoldenClip] {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "OogGolden", withExtension: "json"))
        return try JSONDecoder().decode([GoldenClip].self, from: Data(contentsOf: url))
    }

    @Test func clipsDecode() throws {
        let clips = try loadClips()
        #expect(clips.count >= 81)
    }

    @Test func swiftEngineMatchesJavaScript() throws {
        let clips = try loadClips()
        let golden = try loadGolden()
        #expect(!golden.isEmpty)

        for reference in golden {
            let def = try #require(clips[reference.id], "No clip \(reference.id) in OogClips.json")
            let clip = OogClip(def: def)
            let tol = def.postTable == nil ? exactTolerance : bakedTolerance
            var worst = (error: 0.0, what: "")
            func check(_ swift: Double, _ js: Double, _ what: String) {
                let error = abs(swift - js)
                if error > worst.error { worst = (error, what) }
            }
            func check(_ swift: OogPoint, _ js: OogPoint, _ what: String) {
                check(swift.x, js.x, what + ".x")
                check(swift.y, js.y, what + ".y")
            }

            check(clip.fit.s * 100, reference.fit.S * 100, "fit.S x100")
            check(clip.fit.ox, reference.fit.ox, "fit.ox")
            check(clip.fit.oy, reference.fit.oy, "fit.oy")

            for sample in reference.samples {
                let pose = clip.pose(at: sample.t)
                let at = "t=\(sample.t)"
                check(pose.p, sample.p, "\(at) p")
                check(pose.torso, sample.T, "\(at) T")
                check(pose.kp, sample.kp, "\(at) kp")
                check(pose.headRel, sample.headRel, "\(at) headRel")
                check(pose.hip, sample.hip, "\(at) hip")
                for side in OogSide.allCases {
                    let leg = pose.leg(side), arm = pose.arm(side)
                    if let js = sample.legs[side.name] {
                        if let p = js["H"] { check(leg.hip, p, "\(at) leg.\(side.name).H") }
                        if let p = js["K"] { check(leg.knee, p, "\(at) leg.\(side.name).K") }
                        if let p = js["A"] { check(leg.ankle, p, "\(at) leg.\(side.name).A") }
                        if let p = js["F"] { check(leg.toe, p, "\(at) leg.\(side.name).F") }
                    }
                    if let js = sample.arms[side.name] {
                        if let p = js["S"] { check(arm.shoulder, p, "\(at) arm.\(side.name).S") }
                        if let p = js["E"] { check(arm.elbow, p, "\(at) arm.\(side.name).E") }
                        if let p = js["H"] { check(arm.hand, p, "\(at) arm.\(side.name).H") }
                    }
                }
                #expect(pose.bells.count == sample.bells.count, "\(reference.id) \(at) bell count")
                for (i, (swift, js)) in zip(pose.bells, sample.bells).enumerated() {
                    check(OogPoint(x: swift.x, y: swift.y), OogPoint(x: js.x, y: js.y), "\(at) bell\(i)")
                    check(swift.a, js.a, "\(at) bell\(i).a")
                    check(swift.opacity, js.op, "\(at) bell\(i).op")
                    if def.postTable == nil { check(swift.z, js.z, "\(at) bell\(i).z") }
                }
                check(clip.leaf(at: sample.t), sample.leaf, "\(at) leaf")
                check(clip.beat(at: pose), sample.beat, "\(at) beat")
                let shadow = clip.shadow(at: pose)
                check(shadow.x, sample.shadow.x, "\(at) shadow.x")
                check(shadow.rx, sample.shadow.rx, "\(at) shadow.rx")
                #expect(clip.isStraining(at: pose) == (sample.face == "strain"), "\(reference.id) \(at) face")
            }

            #expect(worst.error <= tol, "\(reference.id): worst \(worst.what) off by \(worst.error)")
        }
    }

    @MainActor @Test func everyMovementHasAClip() {
        let missing = MovementLibrary.all.map(\.id).filter { !OogClipLibrary.shared.hasClip(for: $0) }
        #expect(missing.isEmpty, "Movements without an Oog clip: \(missing.joined(separator: ", "))")
    }

    @Test func pathDataParsesEveryCommand() {
        let path = OogPathData.path("M0 -6 C3 -2 4 1 4 3 A4 4 0 0 1 -4 3 L-4 0 Q0 -8 0 -6 Z")
        let box = path.boundingRect
        #expect(abs(box.minX - -4) < 0.01)
        #expect(abs(box.maxX - 4) < 0.01)
        #expect(abs(box.maxY - 7) < 0.05) // bottom of the arc: centre (0, 3), radius 4
    }
}

// MARK: - Golden fixture shape

private struct GoldenClip: Decodable {
    let id: String
    let cat: String
    let fit: GoldenFit
    let samples: [GoldenSample]
}

private struct GoldenFit: Decodable {
    let S: Double
    let ox: Double
    let oy: Double
}

private struct GoldenSample: Decodable {
    let t: Double
    let p: Double
    let T: Double
    let kp: Double
    let lean: Double
    let headRel: Double
    let hip: OogPoint
    let legs: [String: [String: OogPoint]]
    let arms: [String: [String: OogPoint]]
    let bells: [GoldenBell]
    let leaf: Double
    let beat: Double
    let face: String
    let shadow: GoldenShadow
}

private struct GoldenBell: Decodable {
    let x: Double
    let y: Double
    let a: Double
    let z: Double
    let op: Double
}

private struct GoldenShadow: Decodable {
    let x: Double
    let rx: Double
}
