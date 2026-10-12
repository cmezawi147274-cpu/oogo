//
//  OogEngine.swift
//  Oogo
//
//  Swift port of animation/engine.js: keyframe tracks, 2D IK and the Oog rig.
//  Pure math, no drawing. OogEngineTests checks it against the JS engine's
//  output (OogGolden.json), so keep the two in step when either changes.
//

import Foundation

nonisolated enum OogMath {
    static let loop: Double = 10
    static let thigh: Double = 30
    static let shin: Double = 30
    static let upperArm: Double = 31
    static let forearm: Double = 30
    static let foot: Double = 9

    static func rad(_ d: Double) -> Double { d * .pi / 180 }
    static func deg(_ r: Double) -> Double { r * 180 / .pi }

    /// Unit vector for a rig angle: 0 points down, 90 forward (+x), 180 up.
    static func dir(_ a: Double) -> OogPoint { OogPoint(x: sin(rad(a)), y: cos(rad(a))) }

    static func angle(of v: OogPoint) -> Double { deg(atan2(v.x, v.y)) }

    static func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double { max(a, min(b, v)) }

    /// JS `%`: remainder with the sign of the dividend.
    static func jsMod(_ a: Double, _ b: Double) -> Double { a.truncatingRemainder(dividingBy: b) }

    /// JS `Math.round`: halves round toward +infinity.
    static func jsRound(_ v: Double) -> Double { (v + 0.5).rounded(.down) }

    /// Two-bone IK from anchor `a` toward target `t`. Returns the joint and the end point.
    static func ik(_ a: OogPoint, _ t: OogPoint, _ l1: Double, _ l2: Double, _ sign: Double) -> (joint: OogPoint, end: OogPoint) {
        let v = t - a
        let d = v.length
        let dmax = l1 + l2 - 0.01
        let dmin = abs(l1 - l2) + 0.5
        let dc = clamp(d, dmin, dmax)
        let u = d > 1e-6 ? v * (1 / d) : OogPoint(x: 0, y: 1)
        let bend = acos(clamp((l1 * l1 + dc * dc - l2 * l2) / (2 * l1 * dc), -1, 1))
        let th = -sign * bend
        let r = OogPoint(x: u.x * cos(th) - u.y * sin(th), y: u.x * sin(th) + u.y * cos(th))
        return (a + r * l1, a + u * dc)
    }
}

// MARK: - Keyframe track

/// Periodic monotone cubic per channel, sampled by cycle phase 0..<1.
nonisolated struct OogTrack {
    private let phases: [Double]
    private let channels: [String]
    /// values[key][channel]
    private let values: [[Double]]

    init(keys: [OogKey]) {
        // Keys are cumulative: a channel missing from a key inherits the previous one.
        var full: [[String: Double]] = []
        var current: [String: Double] = [:]
        for key in keys {
            current.merge(key.values) { _, new in new }
            full.append(current)
        }
        var channels: [String] = []
        var seen = Set<String>()
        for frame in full {
            for name in frame.keys.sorted() where !seen.contains(name) {
                seen.insert(name)
                channels.append(name)
            }
        }
        // Channels missing from the earliest keys borrow from the first key that has them.
        for name in channels {
            guard let first = full.first(where: { $0[name] != nil })?[name] else { continue }
            for index in full.indices where full[index][name] == nil {
                full[index][name] = first
            }
        }
        self.phases = keys.map(\.p)
        self.channels = channels
        self.values = full.map { frame in channels.map { frame[$0] ?? 0 } }
    }

    func sample(_ p: Double, into c: inout [String: Double]) {
        let n = phases.count
        guard n > 0 else { return }
        if n == 1 {
            for (j, name) in channels.enumerated() { c[name] = values[0][j] }
            return
        }
        var i = n - 1
        for k in 0..<n where p >= phases[k] { i = k }
        var pp = p
        if p < phases[0] {
            i = n - 1
            pp = p + 1
        }
        let t0 = time(i), t1 = time(i + 1), tm = time(i - 1), tp = time(i + 2)
        let h = t1 - t0
        let s = OogMath.clamp((pp - t0) / h, 0, 1)
        let s2 = s * s, s3 = s2 * s
        let h00 = 2 * s3 - 3 * s2 + 1
        let h10 = s3 - 2 * s2 + s
        let h01 = -2 * s3 + 3 * s2
        let h11 = s3 - s2
        for (j, name) in channels.enumerated() {
            let v0 = value(i, j), v1 = value(i + 1, j), vm = value(i - 1, j), vp = value(i + 2, j)
            let d0 = (v0 - vm) / (t0 - tm)
            let d1 = (v1 - v0) / h
            let d2 = (vp - v1) / (tp - t1)
            var m0 = Self.tangent(d0, d1)
            var m1 = Self.tangent(d1, d2)
            // Limit the tangents so the curve never overshoots its keys.
            if d1 != 0 {
                m0 = OogMath.clamp(m0 / d1, 0, 3) * d1
                m1 = OogMath.clamp(m1 / d1, 0, 3) * d1
            } else {
                m0 = 0
                m1 = 0
            }
            c[name] = h00 * v0 + h10 * h * m0 + h01 * v1 + h11 * h * m1
        }
    }

    private func wrap(_ k: Int) -> Int {
        let n = phases.count
        return ((k % n) + n) % n
    }

    private func time(_ k: Int) -> Double {
        phases[wrap(k)] + (Double(k) / Double(phases.count)).rounded(.down)
    }

    private func value(_ k: Int, _ j: Int) -> Double { values[wrap(k)][j] }

    private static func tangent(_ a: Double, _ b: Double) -> Double {
        a * b <= 0 ? 0 : 2 / (1 / a + 1 / b)
    }
}

// MARK: - Pose

nonisolated enum OogSide: Int, CaseIterable {
    case l, r

    var name: String { self == .l ? "l" : "r" }
}

nonisolated struct OogLegPose {
    var hip: OogPoint
    var knee: OogPoint
    var ankle: OogPoint
    var toe: OogPoint
}

nonisolated struct OogArmPose {
    var shoulder: OogPoint
    var elbow: OogPoint
    var hand: OogPoint
}

nonisolated struct OogBellPose {
    var x: Double
    var y: Double
    /// Rig angle of the handle-to-bell axis.
    var a: Double
    var z: Double
    var opacity: Double
    var center: OogPoint
}

nonisolated struct OogPose {
    let c: [String: Double]
    /// Phase within the current rep, 0..<1.
    let p: Double
    /// Time within the loop, 0..<10 s.
    let t: Double
    let hip: OogPoint
    /// Torso angle: 180 is upright.
    let torso: Double
    /// Vertical squash of the torso when it pitches toward the viewer.
    let kp: Double
    let legs: [OogLegPose]
    let arms: [OogArmPose]
    let headRel: Double
    let bells: [OogBellPose]
    let lean: Double

    /// Body space to world space: x along the torso width, y up the spine (negative).
    func world(_ lx: Double, _ ly0: Double) -> OogPoint {
        let ly = ly0 * kp
        let phi = OogMath.rad(180 - torso)
        return OogPoint(x: hip.x + lx * cos(phi) - ly * sin(phi), y: hip.y + lx * sin(phi) + ly * cos(phi))
    }

    func leg(_ side: OogSide) -> OogLegPose { legs[side.rawValue] }
    func arm(_ side: OogSide) -> OogArmPose { arms[side.rawValue] }
}

/// How the 400 x 400 frame maps world space: translate(ox, oy) then scale(s).
nonisolated struct OogFit: Equatable {
    var s: Double
    var ox: Double
    var oy: Double
}

// MARK: - Clip

/// A compiled clip: everything needed to pose Oog at any time in the loop.
nonisolated struct OogClip {
    let def: OogClipDef
    let isFront: Bool
    let rep: Double
    let headX: Double
    let headY: Double
    let face: String
    private(set) var fit = OogFit(s: 1, ox: 0, oy: 0)

    private let track: OogTrack
    private let defaults: [String: Double]
    private let hipOff: [OogPoint]
    private let shOff: [OogPoint]
    private let upperArm: Double
    private let forearm: Double
    private let legMode: [String]
    private let armMode: [String]
    private let kneeSign: [Double]
    private let elbowSign: [Double]
    private let flex: [Double]
    private let footDefault: [Double]
    let zOrder: [String: Double]

    init(def: OogClipDef) {
        self.def = def
        let front = def.view == "front"
        isFront = front
        // A rep always divides the 10 s loop; snap away any rounding in the JSON.
        let authoredRep = (def.rep ?? 0) == 0 ? 2 : def.rep!
        let repsPerLoop = OogMath.loop / authoredRep
        rep = abs(repsPerLoop - repsPerLoop.rounded()) < 1e-3 ? OogMath.loop / repsPerLoop.rounded() : authoredRep
        track = OogTrack(keys: def.keys)

        var d: [String: Double] = [
            "hx": 0, "hy": -60, "t": 180, "hd": 0,
            "lfx": -4, "lfy": 0, "rfx": 2, "rfy": 0,
            "lth": 0, "lk": 0, "rth": 0, "rk": 0,
            "lua": 0, "le": 0, "rua": 0, "re": 0,
            "lhx": 0, "lhy": -60, "rhx": 0, "rhy": -60,
        ]
        if front {
            d["lfx"] = -14
            d["rfx"] = 14
        }
        d.merge(def.defaults ?? [:]) { _, new in new }
        defaults = d

        func pair(_ dict: [String: OogPoint]?, _ fallback: [OogPoint]) -> [OogPoint] {
            guard let dict, let l = dict["l"], let r = dict["r"] else { return fallback }
            return [l, r]
        }
        hipOff = pair(def.hipOff, front
            ? [OogPoint(x: -14, y: -2), OogPoint(x: 14, y: -2)]
            : [OogPoint(x: -3, y: -2), OogPoint(x: 2, y: -2)])
        shOff = pair(def.shOff, front
            ? [OogPoint(x: -31, y: -66), OogPoint(x: 31, y: -66)]
            : [OogPoint(x: -6, y: -64), OogPoint(x: 6, y: -64)])

        if let armLen = def.armLen, armLen.count == 2 {
            upperArm = armLen[0]
            forearm = armLen[1]
        } else {
            upperArm = front ? 34 : OogMath.upperArm
            forearm = front ? 33 : OogMath.forearm
        }

        func sides<T>(_ base: [T], _ override: [String: T]?) -> [T] {
            [override?["l"] ?? base[0], override?["r"] ?? base[1]]
        }
        legMode = sides(["ik", "ik"], def.legMode)
        armMode = sides(["fk", "fk"], def.armMode)
        kneeSign = sides(front ? [-1, 1] : [1, 1], def.kneeSign)
        elbowSign = sides(front ? [1, -1] : [-1, -1], def.elbowSign)
        flex = sides(front ? [-1, 1] : [1, 1], def.flex)
        footDefault = front ? [-90, 90] : [90, 90]

        var z: [String: Double] = front
            ? ["legl": 1, "legr": 1, "body": 5, "arml": 7, "armr": 7]
            : ["legl": 1, "legr": 2, "body": 5, "arml": 3, "armr": 8]
        z.merge(def.z ?? [:]) { _, new in new }
        zOrder = z

        headX = def.headPos?.x ?? (front ? 0 : 4)
        headY = def.headPos?.y ?? -98
        face = def.face ?? "calm"

        fit = computeFit()
    }

    // MARK: Pose

    func pose(at t: Double) -> OogPose {
        let loop = OogMath.loop
        let tt = OogMath.jsMod(OogMath.jsMod(t, loop) + loop, loop)
        let p = OogMath.jsMod(tt, rep) / rep

        var c = defaults
        track.sample(p, into: &c)
        if let table = def.postTable { Self.apply(table, phase: p, to: &c) }

        let hip = OogPoint(x: c["hx"] ?? 0, y: c["hy"] ?? 0)
        let torso = c["t"] ?? 180
        let phi = OogMath.rad(180 - torso)
        let kp = max(0.45, cos(OogMath.rad(c["pt"] ?? 0)))
        func world(_ lx: Double, _ ly0: Double) -> OogPoint {
            let ly = ly0 * kp
            return OogPoint(x: hip.x + lx * cos(phi) - ly * sin(phi), y: hip.y + lx * sin(phi) + ly * cos(phi))
        }

        var legs: [OogLegPose] = []
        var arms: [OogArmPose] = []
        for side in OogSide.allCases {
            let s = side.name
            let i = side.rawValue
            func ch(_ name: String) -> Double { c[s + name] ?? 0 }

            // Legs
            let hipJoint = world(hipOff[i].x, hipOff[i].y)
            let thigh = OogMath.thigh * (c[s + "tf"] ?? 1)
            let shin = OogMath.shin * (c[s + "sf"] ?? 1)
            let knee: OogPoint
            let ankle: OogPoint
            if legMode[i] == "ik" {
                let r = OogMath.ik(hipJoint, OogPoint(x: ch("fx"), y: ch("fy")), thigh, shin, kneeSign[i])
                knee = r.joint
                ankle = r.end
            } else {
                let td = (legMode[i] == "fkw" ? 0 : torso - 180) + flex[i] * ch("th")
                knee = hipJoint + OogMath.dir(td) * thigh
                ankle = knee + OogMath.dir(td - flex[i] * ch("k")) * shin
            }
            let footAngle = c[s + "fa"] ?? footDefault[i]
            let toe = ankle + OogMath.dir(footAngle) * (OogMath.foot * (c[s + "ff"] ?? 1))
            legs.append(OogLegPose(hip: hipJoint, knee: knee, ankle: ankle, toe: toe))

            // Arms
            let shoulder = world(shOff[i].x, shOff[i].y)
            var elbow: OogPoint
            var hand: OogPoint
            switch armMode[i] {
            case "ik", "ikb":
                let target = armMode[i] == "ikb" ? world(ch("hx"), ch("hy")) : OogPoint(x: ch("hx"), y: ch("hy"))
                let r = OogMath.ik(shoulder, target, upperArm, forearm, elbowSign[i])
                elbow = r.joint
                hand = r.end
            case "blend":
                let ua = ch("ua")
                let e0 = shoulder + OogMath.dir(ua) * upperArm
                let fkHand = e0 + OogMath.dir(ua + flex[i] * ch("e")) * forearm
                let ikTarget = (def.blendSpace ?? "body").isEmpty || (def.blendSpace ?? "body") == "body"
                    ? world(ch("hx"), ch("hy"))
                    : OogPoint(x: ch("hx"), y: ch("hy"))
                let m = OogMath.clamp(c[s + "m"] ?? 0, 0, 1)
                if m < 0.001 {
                    elbow = e0
                    hand = fkHand
                } else {
                    let r = OogMath.ik(shoulder, fkHand.lerp(to: ikTarget, m), upperArm, forearm, elbowSign[i])
                    elbow = m < 1 ? e0.lerp(to: r.joint, min(1, m * 1.5)) : r.joint
                    hand = r.end
                    // Keep the forearm its true length after the elbow blend.
                    let v = hand - elbow
                    let l0 = v.length == 0 ? 1 : v.length
                    hand = elbow + v * (forearm / l0)
                }
            default:
                let ua = armMode[i] == "fkw" ? ch("ua") : torso - 180 + flex[i] * ch("ua")
                elbow = shoulder + OogMath.dir(ua) * upperArm
                hand = elbow + OogMath.dir(ua + flex[i] * ch("e")) * forearm
            }
            arms.append(OogArmPose(shoulder: shoulder, elbow: elbow, hand: hand))
        }

        var lean = 180 - torso
        while lean > 180 { lean -= 360 }
        while lean < -180 { lean += 360 }
        let headClamp = def.headClamp ?? 70
        let headRel = (def.headComp ?? -0.35) * OogMath.clamp(lean, -headClamp, headClamp) + (c["hd"] ?? 0)

        var bells: [OogBellPose] = []
        for (i, bell) in (def.bells ?? []).enumerated() {
            let key = "b\(i)"
            let fallbackWeight: Double = bell.hand == "r" ? 1 : bell.hand == "mid" ? 0.5 : 0
            let w = c[key + "w"] ?? fallbackWeight
            var at = arms[0].hand.lerp(to: arms[1].hand, OogMath.clamp(w, 0, 1))
            if let offset = bell.offset { at = at + offset }
            let a: Double
            if let fixed = c[key + "a"] {
                a = fixed
            } else {
                let arm = w > 0.5 ? arms[1] : arms[0]
                a = OogMath.angle(of: arm.hand - arm.elbow) + (c[key + "f"] ?? 0) * (bell.mirror == true ? -1 : 1)
            }
            let z = c[key + "z"] ?? bell.z ?? 9
            let opacity = c[key + "o"].map { OogMath.clamp($0, 0, 1) } ?? 1
            bells.append(OogBellPose(x: at.x, y: at.y, a: a, z: z, opacity: opacity, center: at + OogMath.dir(a) * (16 * 0.9)))
        }

        return OogPose(c: c, p: p, t: tt, hip: hip, torso: torso, kp: kp, legs: legs, arms: arms,
                       headRel: headRel, bells: bells, lean: lean)
    }

    private static func apply(_ table: OogPostTable, phase p: Double, to c: inout [String: Double]) {
        guard table.n > 0 else { return }
        let x = p * Double(table.n)
        let base = x.rounded(.down)
        let i0 = ((Int(base) % table.n) + table.n) % table.n
        let i1 = (i0 + 1) % table.n
        let k = x - base
        let steps = Set(table.stepChannels ?? [])
        for (j, name) in table.channels.enumerated() where j < table.values.count {
            let column = table.values[j]
            guard column.count == table.n else { continue }
            c[name] = steps.contains(name) ? column[i0] : column[i0] + (column[i1] - column[i0]) * k
        }
    }

    // MARK: Derived per-frame values

    /// Leaf sway on Oog's head, lagging behind recent body motion.
    func leaf(at t: Double) -> Double {
        let pa = pose(at: t - 0.06)
        let pb = pose(at: t - 0.16)
        let raw = -(pa.lean - pb.lean) * 1.6 + (pa.hip.x - pb.hip.x) * -0.6 + (pa.hip.y - pb.hip.y) * 0.5
        return OogMath.clamp(raw, -24, 24) + 3
    }

    /// Heart pulse 0...1, peaking at each effort phase.
    func beat(at pose: OogPose) -> Double {
        var beat: Double = 0
        for e in def.effort ?? [] {
            var d = pose.p - e
            d -= OogMath.jsRound(d)
            beat = max(beat, exp(-pow(d / 0.05, 2)))
        }
        return beat
    }

    func isStraining(at pose: OogPose) -> Bool {
        if let windows = def.strainAt {
            return windows.contains { $0.count == 2 && pose.p >= $0[0] && pose.p <= $0[1] }
        }
        return face == "strain"
    }

    /// Floor shadow centre and half-width.
    func shadow(at pose: OogPose) -> (x: Double, rx: Double) {
        if let table = def.shadowTable, table.n > 0, table.x.count == table.n, table.rx.count == table.n {
            return (Self.sampleLoop(table.x, n: table.n, t: pose.t), Self.sampleLoop(table.rx, n: table.n, t: pose.t))
        }
        if let shadow = def.shadow { return (shadow.x, shadow.rx) }
        let xs = [pose.hip.x, pose.legs[0].ankle.x, pose.legs[1].ankle.x, pose.world(0, -40).x]
        let x = xs.reduce(0, +) / Double(xs.count)
        let rx = OogMath.clamp(((xs.max() ?? 0) - (xs.min() ?? 0)) / 2 + 42, 44, 110)
        return (x, rx)
    }

    /// Linear sample of a table spread evenly over the 10 s loop.
    static func sampleLoop(_ values: [Double], n: Int, t: Double) -> Double {
        let x = t / OogMath.loop * Double(n)
        let base = x.rounded(.down)
        let i0 = ((Int(base) % n) + n) % n
        let i1 = (i0 + 1) % n
        return values[i0] + (values[i1] - values[i0]) * (x - base)
    }

    // MARK: Fit

    private func computeFit() -> OogFit {
        var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
        func include(_ q: OogPoint, _ r: Double) {
            x0 = min(x0, q.x - r)
            x1 = max(x1, q.x + r)
            y0 = min(y0, q.y - r)
            y1 = max(y1, q.y + r)
        }
        for i in 0..<120 {
            let pose = pose(at: Double(i) * OogMath.loop / 120)
            for k in 0..<16 {
                let a = Double(k) / 16 * .pi * 2
                include(pose.world(cos(a) * 50, -36 + sin(a) * 46), 0)
            }
            include(pose.world(headX, headY), 40)
            include(pose.world(headX + 12, headY - 60), 4)
            for leg in pose.legs { for q in [leg.knee, leg.ankle, leg.toe] { include(q, 3) } }
            for arm in pose.arms { for q in [arm.elbow, arm.hand] { include(q, 3) } }
            for bell in pose.bells where bell.opacity > 0.01 { include(bell.center, 16) }
        }
        include(OogPoint(x: 0, y: 4), 0)
        for extra in def.fitExtra ?? [] where extra.count == 2 {
            include(OogPoint(x: extra[0], y: extra[1]), 0)
        }

        let w = x1 - x0, h = y1 - y0
        let maxScale = (def.maxScale ?? 0) == 0 ? 1.45 : def.maxScale!
        let s = min(maxScale, 344 / w, 344 / h)
        let cx = (x0 + x1) / 2
        // Keep the floor low in the frame when there is room.
        var oy = 200 - ((y0 + y1) / 2) * s
        if oy < 360 { oy = min(360, 400 - 28 - y1 * s) }
        // Make sure the top fits.
        if y0 * s + oy < 26 { oy = 26 - y0 * s }
        return OogFit(s: s, ox: 200 - cx * s, oy: oy)
    }
}
