//
//  OogClipData.swift
//  Oogo
//
//  Plain data for one Oog exercise loop, decoded from OogClips.json.
//  The JSON is generated from animation/*.js by `node animation/export.js`;
//  never hand-edit it. Field names mirror the JS clip definitions.
//

import Foundation

/// A point or vector in Oog world space: x forward, y down, ground at y = 0.
nonisolated struct OogPoint: Codable, Hashable {
    var x: Double
    var y: Double

    static let zero = OogPoint(x: 0, y: 0)

    static func + (a: OogPoint, b: OogPoint) -> OogPoint { OogPoint(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: OogPoint, b: OogPoint) -> OogPoint { OogPoint(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: OogPoint, k: Double) -> OogPoint { OogPoint(x: a.x * k, y: a.y * k) }

    var length: Double { (x * x + y * y).squareRoot() }

    func lerp(to b: OogPoint, _ k: Double) -> OogPoint {
        OogPoint(x: x + (b.x - x) * k, y: y + (b.y - y) * k)
    }
}

/// One keyframe: `[phase, { channel: value }]` in the JSON.
nonisolated struct OogKey: Decodable {
    let p: Double
    let values: [String: Double]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        p = try container.decode(Double.self)
        values = try container.decode([String: Double].self)
    }
}

nonisolated struct OogBellDef: Decodable {
    /// "l", "r", "mid" or "swap". Decides the default hand weight.
    let hand: String?
    let offset: OogPoint?
    let mirror: Bool?
    let z: Double?
}

/// Speed lines behind a bell, hand or foot during a phase window.
nonisolated struct OogMotionDef: Decodable {
    let win: [Double]
    let bell: Int?
    let hand: String?
    let foot: String?
    let back: Double?
    let z: Double?
}

nonisolated struct OogShadowDef: Decodable {
    let x: Double
    let rx: Double
}

/// Channel values a JS `post` hook produced, sampled across one rep cycle.
nonisolated struct OogPostTable: Decodable {
    let n: Int
    let channels: [String]
    /// values[channel][sample]
    let values: [[Double]]
    /// Channels that jump (z-order switches): hold the previous sample, never blend.
    let stepChannels: [String]?
}

/// Shadow sampled across the whole loop, for clips whose shadow follows the body.
nonisolated struct OogShadowTable: Decodable {
    let n: Int
    let x: [Double]
    let rx: [Double]
}

/// Numeric prop fields sampled across the whole loop, for props that follow the body.
nonisolated struct OogPropTable: Decodable {
    let n: Int
    /// Non-numeric fields of the prop. Only string values are kept.
    let base: [String: String]?
    let fields: [String: [Double]]

    private enum CodingKeys: String, CodingKey { case n, base, fields }

    private nonisolated struct AnyKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        n = try container.decode(Int.self, forKey: .n)
        fields = try container.decode([String: [Double]].self, forKey: .fields)
        if let raw = try? container.nestedContainer(keyedBy: AnyKey.self, forKey: .base) {
            var base: [String: String] = [:]
            for key in raw.allKeys {
                if let value = try? raw.decode(String.self, forKey: key) { base[key.stringValue] = value }
            }
            self.base = base
        } else {
            base = nil
        }
    }
}

/// A piece of scenery: bench, bar, box, ring... Numbers live in `values`.
nonisolated struct OogPropDef: Decodable {
    let type: String
    let values: [String: Double]
    let table: OogPropTable?

    private nonisolated struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        var type = ""
        var values: [String: Double] = [:]
        var table: OogPropTable?
        for key in container.allKeys {
            switch key.stringValue {
            case "type": type = try container.decode(String.self, forKey: key)
            case "table": table = try container.decode(OogPropTable.self, forKey: key)
            default:
                if let number = try? container.decode(Double.self, forKey: key) {
                    values[key.stringValue] = number
                }
            }
        }
        self.type = type
        self.values = values
        self.table = table
    }
}

/// One clip definition, exactly as authored in animation/ex_*.js.
nonisolated struct OogClipDef: Decodable {
    let id: String
    let name: String?
    let cat: String?
    /// The app `Movement.id` this clip shows, if any.
    let movementId: String?
    /// Other app movements that reuse this clip, e.g. both High Pull variants.
    let movementAliases: [String]?

    let view: String?
    let rep: Double?
    let keys: [OogKey]
    let defaults: [String: Double]?
    let hipOff: [String: OogPoint]?
    let shOff: [String: OogPoint]?
    let armLen: [Double]?
    let legMode: [String: String]?
    let armMode: [String: String]?
    let kneeSign: [String: Double]?
    let elbowSign: [String: Double]?
    let flex: [String: Double]?
    let z: [String: Double]?
    let bells: [OogBellDef]?
    let headPos: OogPoint?
    let face: String?
    let strainAt: [[Double]]?
    let effort: [Double]?
    let motion: [OogMotionDef]?
    let sweat: [Double]?
    let shadow: OogShadowDef?
    let shadowTable: OogShadowTable?
    let scroll: Double?
    let props: [OogPropDef]?
    let propsFront: [OogPropDef]?
    let fitExtra: [[Double]]?
    let maxScale: Double?
    let headComp: Double?
    let headClamp: Double?
    let blendSpace: String?
    let postTable: OogPostTable?
}

nonisolated struct OogClipFile: Decodable {
    let version: Int
    let loop: Double
    let clips: [OogClipDef]

    static func load(from url: URL) throws -> OogClipFile {
        try JSONDecoder().decode(OogClipFile.self, from: Data(contentsOf: url))
    }
}
