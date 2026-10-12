//
//  OogRenderer.swift
//  Oogo
//
//  Draws one frame of an Oog clip into a SwiftUI GraphicsContext. A direct
//  port of svgInner() in animation/engine.js: same shapes, strokes, z-order
//  and transforms, minus the white page so Oog sits on any background.
//

import SwiftUI

nonisolated enum OogRenderer {
    // Engine palette. Matches OogColor; mist is the engine's own floor tone.
    static let ink = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
    static let red = Color(red: 0xE5 / 255, green: 0x39 / 255, blue: 0x35 / 255)
    static let mist = Color(red: 0xE8 / 255, green: 0xE8 / 255, blue: 0xE5 / 255)
    static let white = Color.white

    private static let legWidth: Double = 3.2
    private static let armWidth: Double = 2.9

    /// Draws the clip at loop time `t`, fitted into a centred square of `size`.
    static func draw(_ clip: OogClip, at t: Double, in context: GraphicsContext, size: CGSize) {
        let side = min(size.width, size.height)
        guard side > 0 else { return }
        var g = context
        g.translateBy(x: (size.width - side) / 2, y: (size.height - side) / 2)
        g.scaleBy(x: side / 400, y: side / 400)
        g.translateBy(x: clip.fit.ox, y: clip.fit.oy)
        g.scaleBy(x: clip.fit.s, y: clip.fit.s)
        drawScene(clip, at: t, in: g)
    }

    // MARK: Scene

    private nonisolated struct Layer {
        let z: Double
        let order: Int
        let draw: (GraphicsContext) -> Void
    }

    private static func drawScene(_ clip: OogClip, at t: Double, in g: GraphicsContext) {
        let def = clip.def
        let pose = clip.pose(at: t)
        let leaf = clip.leaf(at: t)
        let beat = clip.beat(at: pose)
        let straining = clip.isStraining(at: pose)
        let front = clip.isFront

        var layers: [Layer] = []
        func add(_ z: Double, _ draw: @escaping (GraphicsContext) -> Void) {
            layers.append(Layer(z: z, order: layers.count, draw: draw))
        }

        // Body: cloud torso with the heart that pulses on effort.
        add(clip.zOrder["body"] ?? 5) { g in
            var body = g
            body.translateBy(x: pose.hip.x, y: pose.hip.y)
            body.rotate(by: .degrees(180 - pose.torso))
            body.scaleBy(x: 1, y: pose.kp)
            body.fill(Shapes.cloud, with: .color(white))
            body.stroke(Shapes.cloud, with: .color(ink), style: style(2.6, join: .round))
            var heart = body
            heart.translateBy(x: front ? 14 : 18, y: -44)
            heart.scaleBy(x: 1 + beat * 0.45, y: 1 + beat * 0.45)
            heart.fill(Shapes.heart, with: .color(red))
        }

        // Head.
        let headCenter = pose.world(clip.headX, clip.headY)
        add(clip.zOrder["head"] ?? 6) { g in
            var head = g
            head.translateBy(x: headCenter.x, y: headCenter.y)
            head.rotate(by: .degrees(180 - pose.torso + pose.headRel))
            drawHead(in: head, leaf: leaf, straining: straining)
        }

        // Limbs.
        for side in OogSide.allCases {
            let s = side.name
            let leg = pose.leg(side)
            add(pose.c["zg" + s] ?? clip.zOrder["leg" + s] ?? 1) { g in
                let halo = polyline([leg.hip, leg.knee, leg.ankle, leg.toe])
                g.stroke(halo, with: .color(white), style: style(legWidth + 2.6, cap: .round, join: .round))
                g.stroke(polyline([leg.hip, leg.knee, leg.ankle]), with: .color(ink), style: style(legWidth, cap: .round, join: .round))
                g.stroke(polyline([leg.ankle, leg.toe]), with: .color(ink), style: style(legWidth, cap: .round))
            }
            let arm = pose.arm(side)
            add(pose.c["z" + s] ?? clip.zOrder["arm" + s] ?? 7) { g in
                let limb = polyline([arm.shoulder, arm.elbow, arm.hand])
                g.stroke(limb, with: .color(white), style: style(armWidth + 2.6, cap: .round, join: .round))
                g.stroke(limb, with: .color(ink), style: style(armWidth, cap: .round, join: .round))
                g.fill(circle(arm.hand, 2.5), with: .color(ink))
            }
        }

        // Kettlebells.
        for (i, bell) in pose.bells.enumerated() where bell.opacity > 0.01 {
            add(bell.z + Double(i) * 0.01) { g in
                var b = g
                b.translateBy(x: bell.x, y: bell.y)
                b.rotate(by: .degrees(-bell.a))
                b.scaleBy(x: 0.9, y: 0.9)
                if bell.opacity < 1 {
                    b.opacity = bell.opacity
                    b.drawLayer { layer in drawBell(in: layer) }
                } else {
                    drawBell(in: b)
                }
            }
        }

        // Speed lines trailing a bell, hand or foot.
        for motion in def.motion ?? [] where motion.win.count == 2 {
            let p0 = motion.win[0], p1 = motion.win[1]
            guard pose.p >= p0, pose.p <= p1 else { continue }
            let show = sin(.pi * (pose.p - p0) / (p1 - p0))
            func tracked(_ time: Double) -> OogPoint? {
                let q = clip.pose(at: time)
                if let bell = motion.bell { return bell < q.bells.count ? q.bells[bell].center : nil }
                if let hand = motion.hand { return q.arm(hand == "r" ? .r : .l).hand }
                if let foot = motion.foot { return q.leg(foot == "r" ? .r : .l).ankle }
                return nil
            }
            guard let a = tracked(t), let b = tracked(t - 0.1) else { continue }
            let dx = a.x - b.x, dy = a.y - b.y
            let length = (dx * dx + dy * dy).squareRoot()
            guard length >= 2 else { continue }
            let nx = -dy / length, ny = dx / length
            let ux = dx / length, uy = dy / length
            let back = motion.back ?? 14
            add(motion.z ?? 0.5) { g in
                for k in [-1.0, 0, 1] {
                    let off = k * 7
                    let x2 = a.x - ux * back + nx * off, y2 = a.y - uy * back + ny * off
                    let tail = k == 0 ? 14.0 : 9.0
                    let x1 = x2 - ux * tail, y1 = y2 - uy * tail
                    var line = g
                    line.opacity = show * (k == 0 ? 1 : 0.7)
                    line.stroke(segment(OogPoint(x: x1, y: y1), OogPoint(x: x2, y: y2)),
                                with: .color(ink), style: style(2.2, cap: .round))
                }
            }
        }

        // Sweat drop flicking off the head at set loop times.
        for st in def.sweat ?? [] {
            let sp = (pose.t - st) / 0.7
            guard sp > 0, sp < 1 else { continue }
            let q = clip.pose(at: st)
            let hc = q.world(clip.headX, clip.headY)
            let back: Double = front ? (OogMath.jsMod(st, 2) < 1 ? -1 : 1) : -1
            let x = hc.x + back * (32 + sp * 20)
            let y = hc.y - 20 - sin(sp * .pi) * 14 + sp * 12
            let opacity = min(1, sp * 5, (1 - sp) * 4)
            add(20) { g in
                var drop = g
                drop.translateBy(x: x, y: y)
                drop.rotate(by: .degrees(back * (40 - sp * 60)))
                drop.scaleBy(x: 1.4, y: 1.4)
                drop.opacity = opacity
                drop.drawLayer { layer in
                    layer.fill(Shapes.sweat, with: .color(white))
                    layer.stroke(Shapes.sweat, with: .color(ink), style: style(1.8, join: .round))
                }
            }
        }

        // Ground first, then props behind, then the body parts by z, then props in front.
        let shadow = clip.shadow(at: pose)
        g.fill(Path(ellipseIn: CGRect(x: shadow.x - shadow.rx, y: 1.5 - 4.8, width: shadow.rx * 2, height: 9.6)),
               with: .color(mist))
        if let speed = def.scroll, speed != 0 {
            let gap = 40.0
            let off = OogMath.jsMod(OogMath.jsMod(pose.t * speed, gap) + gap, gap)
            for x in stride(from: -240.0, through: 240, by: gap) {
                let xx = x - off
                let fade = OogMath.clamp(1 - abs(xx) / 200, 0, 1)
                var tick = g
                tick.opacity = fade * 0.35
                tick.stroke(segment(OogPoint(x: xx, y: 9), OogPoint(x: xx + 12, y: 9)),
                            with: .color(ink), style: style(2.2, cap: .round))
            }
        }
        for prop in def.props ?? [] { drawProp(prop, pose: pose, in: g) }
        for layer in layers.sorted(by: { ($0.z, $0.order) < ($1.z, $1.order) }) { layer.draw(g) }
        for prop in def.propsFront ?? [] { drawProp(prop, pose: pose, in: g) }
    }

    // MARK: Head

    private static func drawHead(in g: GraphicsContext, leaf: Double, straining: Bool) {
        var sprout = g
        sprout.translateBy(x: 0, y: -33)
        sprout.rotate(by: .degrees(leaf))
        sprout.translateBy(x: 0, y: 33)
        sprout.stroke(Shapes.stem, with: .color(ink), style: style(2.2, cap: .round))
        sprout.fill(Shapes.leaf, with: .color(white))
        sprout.stroke(Shapes.leaf, with: .color(ink), style: style(2, join: .round))
        sprout.stroke(Shapes.leafVeins, with: .color(ink), style: style(1.3, cap: .round))

        g.fill(Shapes.ears, with: .color(white))
        g.stroke(Shapes.ears, with: .color(ink), style: style(2.4))
        g.fill(Shapes.face, with: .color(white))
        g.stroke(Shapes.face, with: .color(ink), style: style(2.6))
        g.fill(Shapes.hair, with: .color(ink))
        g.stroke(straining ? Shapes.browsStrain : Shapes.browsCalm, with: .color(ink), style: style(2.8, cap: .round))
        g.stroke(straining ? Shapes.eyesStrain : Shapes.eyesCalm, with: .color(ink),
                 style: style(straining ? 2.2 : 2, cap: .round))
        g.stroke(Shapes.nose, with: .color(ink), style: style(1.8, cap: .round, join: .round))
        g.fill(Shapes.beard, with: .color(ink))
        g.fill(Shapes.beardDots, with: .color(ink))
        g.fill(straining ? Shapes.mouthStrain : Shapes.mouthCalm, with: .color(white))
    }

    // MARK: Kettlebell

    private static func drawBell(in g: GraphicsContext) {
        g.stroke(Shapes.bellHandle, with: .color(white), style: style(7, cap: .round))
        g.fill(circle(OogPoint(x: 0, y: 18), 12.6), with: .color(white))
        g.fill(roundedRect(x: -9.6, y: 25.4, w: 19.2, h: 6.7, r: 2.5), with: .color(white))
        g.stroke(Shapes.bellHandle, with: .color(ink), style: style(4, cap: .round))
        g.fill(circle(OogPoint(x: 0, y: 18), 11), with: .color(ink))
        g.fill(roundedRect(x: -8, y: 27, w: 16, h: 3.5, r: 1.5), with: .color(ink))
        var shine = g
        shine.opacity = 0.8
        shine.stroke(Shapes.bellShine, with: .color(white), style: style(1.6, cap: .round))
    }

    // MARK: Props

    private static func drawProp(_ def: OogPropDef, pose: OogPose, in g: GraphicsContext) {
        var type = def.type
        var v = def.values
        if type == "fn", let table = def.table, table.n > 0 {
            type = table.base?["type"] ?? ""
            v = [:]
            for (name, column) in table.fields where column.count == table.n {
                v[name] = OogClip.sampleLoop(column, n: table.n, t: pose.t)
            }
        }
        func n(_ key: String, _ fallback: Double = 0) -> Double { v[key] ?? fallback }
        func line(_ a: OogPoint, _ b: OogPoint, _ width: Double) {
            g.stroke(segment(a, b), with: .color(ink), style: style(width, cap: .round))
        }
        func panel(_ path: Path, _ width: Double, join: CGLineJoin = .miter) {
            g.fill(path, with: .color(white))
            g.stroke(path, with: .color(ink), style: style(width, join: join))
        }

        switch type {
        case "box":
            panel(roundedRect(x: n("x"), y: n("y"), w: n("w"), h: n("h"), r: n("r", 4)), 2.6)
        case "bench":
            let th = n("th", 9)
            panel(roundedRect(x: n("x"), y: n("y"), w: n("w"), h: th, r: 3), 2.6)
            line(OogPoint(x: n("x") + 8, y: n("y") + th), OogPoint(x: n("x") + 8, y: 0), 2.8)
            line(OogPoint(x: n("x") + n("w") - 8, y: n("y") + th), OogPoint(x: n("x") + n("w") - 8, y: 0), 2.8)
        case "barSide":
            let post = n("post", 30)
            line(OogPoint(x: n("x") + post, y: n("y")), OogPoint(x: n("x") + post, y: n("ground", 0)), 3)
            line(OogPoint(x: n("x"), y: n("y")), OogPoint(x: n("x") + post, y: n("y")), 3)
            panel(circle(OogPoint(x: n("x"), y: n("y")), 3.6), 2.6)
        case "barFront":
            line(OogPoint(x: n("x1"), y: n("y")), OogPoint(x: n("x2"), y: n("y")), 3.6)
            line(OogPoint(x: n("x1") + 4, y: n("y") - 5), OogPoint(x: n("x1") + 4, y: n("y") + 9), 3.6)
            line(OogPoint(x: n("x2") - 4, y: n("y") - 5), OogPoint(x: n("x2") - 4, y: n("y") + 9), 3.6)
        case "dip":
            line(OogPoint(x: n("x1"), y: n("y")), OogPoint(x: n("x2"), y: n("y")), 3.4)
            line(OogPoint(x: n("x1") + 3, y: n("y")), OogPoint(x: n("x1") + 3, y: 0), 3.4)
            line(OogPoint(x: n("x2") - 3, y: n("y")), OogPoint(x: n("x2") - 3, y: 0), 3.4)
        case "ring":
            line(OogPoint(x: n("ax"), y: n("ay")), OogPoint(x: n("x"), y: n("y") - 7), 2.2)
            g.stroke(circle(OogPoint(x: n("x"), y: n("y")), 6.5), with: .color(ink), style: style(2.8))
        case "towel":
            let x = n("x"), y = n("y"), len = n("len", 34), sw = sin(pose.t * 2) * 1.5
            var path = Path()
            path.move(to: CGPoint(x: x - 3, y: y))
            path.addCurve(to: CGPoint(x: x - 3, y: y + len),
                          control1: CGPoint(x: x - 6 + sw, y: y + len * 0.35),
                          control2: CGPoint(x: x + sw, y: y + len * 0.6))
            path.addLine(to: CGPoint(x: x + 4, y: y + len))
            path.addCurve(to: CGPoint(x: x + 4, y: y),
                          control1: CGPoint(x: x + 7 + sw, y: y + len * 0.6),
                          control2: CGPoint(x: x + 1 + sw, y: y + len * 0.35))
            path.closeSubpath()
            panel(path, 2.2, join: .round)
        case "block":
            panel(roundedRect(x: n("x") - n("w") / 2, y: -n("h"), w: n("w"), h: n("h"), r: 2.5), 2.6)
        case "wedge":
            var path = Path()
            path.move(to: CGPoint(x: n("x1"), y: 0))
            path.addLine(to: CGPoint(x: n("x2"), y: 0))
            path.addLine(to: CGPoint(x: n("x1"), y: -n("h")))
            path.closeSubpath()
            panel(path, 2.4, join: .round)
        case "handles":
            line(OogPoint(x: n("x1"), y: n("y")), OogPoint(x: n("x1"), y: n("y") + 14), 3.2)
            line(OogPoint(x: n("x2"), y: n("y")), OogPoint(x: n("x2"), y: n("y") + 14), 3.2)
        case "post":
            line(OogPoint(x: n("x"), y: n("y")), OogPoint(x: n("x"), y: 0), 3.4)
            line(OogPoint(x: n("x") - 7, y: n("y")), OogPoint(x: n("x") + 7, y: n("y")), 3.6)
        case "mat":
            g.fill(roundedRect(x: n("x1"), y: -2.5, w: n("x2") - n("x1"), h: 2.5, r: 1.25), with: .color(mist))
        default:
            break
        }
    }

    // MARK: Helpers

    private static func style(_ width: Double, cap: CGLineCap = .butt, join: CGLineJoin = .miter) -> StrokeStyle {
        // SVG defaults: butt caps, miter joins, miter limit 4.
        StrokeStyle(lineWidth: width, lineCap: cap, lineJoin: join, miterLimit: 4)
    }

    private static func polyline(_ points: [OogPoint]) -> Path {
        var path = Path()
        path.addLines(points.map { CGPoint(x: $0.x, y: $0.y) })
        return path
    }

    private static func segment(_ a: OogPoint, _ b: OogPoint) -> Path {
        polyline([a, b])
    }

    private static func circle(_ c: OogPoint, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    }

    private static func roundedRect(x: Double, y: Double, w: Double, h: Double, r: Double) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: r, height: r), style: .circular)
    }

    // MARK: Fixed shapes, copied from engine.js

    private nonisolated enum Shapes {
        static let cloud: Path = {
            // cloudPath(0, -36, 42, 38, 12, 9): twelve puffs around an ellipse.
            let cx = 0.0, cy = -36.0, rx = 42.0, ry = 38.0, n = 12, bulge = 9.0
            var path = Path()
            for i in 0...n {
                let a = Double(i) / Double(n) * .pi * 2 + 0.3
                let p = CGPoint(x: cx + cos(a) * rx, y: cy + sin(a) * ry)
                if i == 0 {
                    path.move(to: p)
                    continue
                }
                let am = (Double(i) - 0.5) / Double(n) * .pi * 2 + 0.3
                path.addQuadCurve(to: p, control: CGPoint(x: cx + cos(am) * (rx + bulge), y: cy + sin(am) * (ry + bulge)))
            }
            path.closeSubpath()
            return path
        }()

        static let heart = OogPathData.path("M0 3 C-6 -2 -6 -7 -3 -8 C-1.5 -8.6 -0.3 -7.6 0 -6.3 C0.3 -7.6 1.5 -8.6 3 -8 C6 -7 6 -2 0 3 Z")

        static let stem = OogPathData.path("M0 -33 C0 -40 1 -44 3 -48")
        static let leaf = OogPathData.path("M3 -48 C6 -58 18 -60 22 -55 C18 -48 8 -45 3 -48 Z")
        static let leafVeins = OogPathData.path("M5 -49 L19 -55 M10 -51 L11 -55 M14 -53 L15 -56.5")
        static let ears = OogPathData.path("M-29 -2 C-36 -4 -36 10 -28 10 M29 -2 C36 -4 36 10 28 10")
        static let face = Path(ellipseIn: CGRect(x: -28, y: -33, width: 56, height: 66))
        static let hair: Path = {
            var path = Path()
            for (x, y) in [(-10.0, -30.0), (-4, -32.5), (2, -33), (8, -31.5), (13, -29)] {
                path.addEllipse(in: CGRect(x: x - 3.6, y: y - 3.6, width: 7.2, height: 7.2))
            }
            return path
        }()
        static let browsCalm = OogPathData.path("M-18 -12 C-14 -15 -8 -15 -4 -12 M4 -12 C8 -15 14 -15 18 -12")
        static let browsStrain = OogPathData.path("M-18 -14 C-14 -13 -8 -11 -4 -9 M4 -9 C8 -11 14 -13 18 -14")
        static let eyesCalm = OogPathData.path("M-17 -4 C-14 0 -8 0 -5 -4 M5 -4 C8 0 14 0 17 -4")
        static let eyesStrain = OogPathData.path("M-17 -3 L-6 -3 M6 -3 L17 -3")
        static let nose = OogPathData.path("M1 -6 L-1 7 C0 9 3 9 4 8")
        static let beard = OogPathData.path("M-27 4 C-26 30 -12 44 0 45 C12 44 26 30 27 4 C20 14 10 11 0 11 C-10 11 -20 14 -27 4 Z")
        static let beardDots: Path = {
            var path = Path()
            for i in 0...12 {
                let a = Double.pi * (0.02 + 0.96 * Double(i) / 12)
                let x = cos(a) * 26, y = 14 + sin(a) * 30
                path.addEllipse(in: CGRect(x: x - 6.2, y: y - 6.2, width: 12.4, height: 12.4))
            }
            return path
        }()
        static let mouthCalm = OogPathData.path("M-7 17 C-4 16 4 16 7 17 C6 23 -6 23 -7 17 Z")
        static let mouthStrain = OogPathData.path("M-7 17 C-3 15.5 3 15.5 7 17 C6 21 -6 21 -7 17 Z")

        static let bellHandle = OogPathData.path("M-7 10 C-8 -3 8 -3 7 10")
        static let bellShine = OogPathData.path("M-6 14 C-5 11 -3 10 -1 9.5")

        static let sweat = OogPathData.path("M0 -6 C3 -2 4 1 4 3 A4 4 0 0 1 -4 3 C-4 1 -3 -2 0 -6 Z")
    }
}
