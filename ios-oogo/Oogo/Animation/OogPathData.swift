//
//  OogPathData.swift
//  Oogo
//
//  Turns SVG path data ("M0 3 C-6 -2 ... Z") into a SwiftUI Path, so Oog's
//  shapes can be copied verbatim from animation/engine.js.
//  Supports absolute M, L, H, V, C, Q, A and Z.
//

import SwiftUI

nonisolated enum OogPathData {
    static func path(_ data: String) -> Path {
        var path = Path()
        var scanner = Tokens(data)
        var command: Character = "M"
        var current = CGPoint.zero
        var start = CGPoint.zero

        while let token = scanner.next() {
            switch token {
            case .command(let c):
                command = c
                if c == "Z" || c == "z" {
                    path.closeSubpath()
                    current = start
                }
                continue
            case .number(let first):
                scanner.pushBack(first)
            }

            switch command {
            case "M":
                guard let p = scanner.point() else { return path }
                path.move(to: p)
                current = p
                start = p
                command = "L" // Extra pairs after M are line-tos.
            case "L":
                guard let p = scanner.point() else { return path }
                path.addLine(to: p)
                current = p
            case "H":
                guard let x = scanner.number() else { return path }
                current = CGPoint(x: x, y: current.y)
                path.addLine(to: current)
            case "V":
                guard let y = scanner.number() else { return path }
                current = CGPoint(x: current.x, y: y)
                path.addLine(to: current)
            case "C":
                guard let c1 = scanner.point(), let c2 = scanner.point(), let p = scanner.point() else { return path }
                path.addCurve(to: p, control1: c1, control2: c2)
                current = p
            case "Q":
                guard let c1 = scanner.point(), let p = scanner.point() else { return path }
                path.addQuadCurve(to: p, control: c1)
                current = p
            case "A":
                guard let rx = scanner.number(), let ry = scanner.number(), let rotation = scanner.number(),
                      let large = scanner.number(), let sweep = scanner.number(), let p = scanner.point()
                else { return path }
                addArc(to: &path, from: current, to: p, rx: rx, ry: ry, rotation: rotation,
                       largeArc: large != 0, sweep: sweep != 0)
                current = p
            default:
                // Unsupported command: skip its numbers.
                _ = scanner.number()
            }
        }
        return path
    }

    /// SVG elliptical arc (endpoint form) as cubic Béziers, per SVG 1.1 appendix F.6.
    private static func addArc(to path: inout Path, from p0: CGPoint, to p1: CGPoint,
                               rx rx0: Double, ry ry0: Double, rotation: Double,
                               largeArc: Bool, sweep: Bool) {
        var rx = abs(rx0), ry = abs(ry0)
        guard rx > 0, ry > 0, p0 != p1 else {
            path.addLine(to: p1)
            return
        }
        let phi = rotation * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy

        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            rx *= lambda.squareRoot()
            ry *= lambda.squareRoot()
        }
        let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        var coef = den == 0 ? 0 : (max(0, num) / den).squareRoot()
        if largeArc == sweep { coef = -coef }
        let cxp = coef * (rx * y1p / ry)
        let cyp = coef * -(ry * x1p / rx)
        let cx = cosPhi * cxp - sinPhi * cyp + (p0.x + p1.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (p0.y + p1.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        let segments = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
        let step = delta / Double(segments)
        let k = 4.0 / 3.0 * tan(step / 4)
        var t = theta1
        func point(_ a: Double) -> CGPoint {
            let x = rx * cos(a), y = ry * sin(a)
            return CGPoint(x: cx + cosPhi * x - sinPhi * y, y: cy + sinPhi * x + cosPhi * y)
        }
        func derivative(_ a: Double) -> CGPoint {
            let x = -rx * sin(a), y = ry * cos(a)
            return CGPoint(x: cosPhi * x - sinPhi * y, y: sinPhi * x + cosPhi * y)
        }
        for _ in 0..<segments {
            let a0 = t, a1 = t + step
            let s = point(a0), e = point(a1)
            let d0 = derivative(a0), d1 = derivative(a1)
            path.addCurve(to: e,
                          control1: CGPoint(x: s.x + k * d0.x, y: s.y + k * d0.y),
                          control2: CGPoint(x: e.x - k * d1.x, y: e.y - k * d1.y))
            t = a1
        }
    }

    // MARK: Tokenizer

    private nonisolated enum Token {
        case command(Character)
        case number(Double)
    }

    private nonisolated struct Tokens {
        private let chars: [Character]
        private var index = 0
        private var pending: Double?

        init(_ text: String) { chars = Array(text) }

        mutating func pushBack(_ value: Double) { pending = value }

        mutating func number() -> Double? {
            if let value = pending {
                pending = nil
                return value
            }
            guard case .number(let value)? = next() else { return nil }
            return value
        }

        mutating func point() -> CGPoint? {
            guard let x = number(), let y = number() else { return nil }
            return CGPoint(x: x, y: y)
        }

        mutating func next() -> Token? {
            if let value = pending {
                pending = nil
                return .number(value)
            }
            while index < chars.count, chars[index] == " " || chars[index] == "," || chars[index].isNewline {
                index += 1
            }
            guard index < chars.count else { return nil }
            let c = chars[index]
            if c.isLetter && c != "e" && c != "E" {
                index += 1
                return .command(c)
            }
            var text = ""
            if c == "-" || c == "+" {
                text.append(c)
                index += 1
            }
            var seenDot = false
            var seenExp = false
            while index < chars.count {
                let d = chars[index]
                if d.isNumber {
                    text.append(d)
                } else if d == "." && !seenDot && !seenExp {
                    seenDot = true
                    text.append(d)
                } else if (d == "e" || d == "E") && !seenExp {
                    seenExp = true
                    text.append(d)
                    if index + 1 < chars.count, chars[index + 1] == "-" || chars[index + 1] == "+" {
                        index += 1
                        text.append(chars[index])
                    }
                } else {
                    break
                }
                index += 1
            }
            guard let value = Double(text) else {
                index += 1
                return next()
            }
            return .number(value)
        }
    }
}
