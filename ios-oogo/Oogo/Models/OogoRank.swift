//
//  OogoRank.swift
//  Oogo
//
//  Work ranks. Every finished work is one mark, loose work on rest day too.
//  Skipping loose work costs nothing. Painted starting history counts for nothing.
//

import Foundation

/// One rung on the work ladder.
nonisolated struct OogoRank: Identifiable, Hashable {
    nonisolated let index: Int
    nonisolated let name: String
    /// Work needed to stand here.
    nonisolated let works: Int

    nonisolated var id: Int { index }

    /// Last rank shouts in caps. Everything else keeps oog's quiet lowercase.
    nonisolated var isFinal: Bool { index == OogoRankBook.lastIndex }

    /// Name as printed anywhere in the app.
    nonisolated var display: String { isFinal ? name.uppercased() : name.lowercased() }
}

/// The whole ladder, from first work to immortal.
nonisolated enum OogoRankBook {
    nonisolated private static let table: [(String, Int)] = [
        ("Youngblood", 1),
        ("Stonehand", 2),
        ("Fireborn", 3),
        ("Spearhand", 5),
        ("War Pup", 7),
        ("Hut Raider", 10),
        ("Boneguard", 15),
        ("Boar Hunter", 20),
        ("Wolfblood", 30),
        ("Stone Raider", 40),
        ("Warborn", 50),
        ("Skullguard", 75),
        ("Mammoth Hunter", 100),
        ("Red Spear", 150),
        ("Tribe Warrior", 200),
        ("Bonecrusher", 300),
        ("Wolfslayer", 400),
        ("War Chief", 500),
        ("Bloodfang", 650),
        ("Mammoth Slayer", 800),
        ("High Chieftain", 1000),
        ("Beastlord", 1200),
        ("Stone Warlord", 1450),
        ("First Spear", 1700),
        ("Skull King", 1950),
        ("War Mammoth", 2150),
        ("Ancient Chief", 2300),
        ("Legendborn", 2450),
        ("Last Warlord", 2550),
        ("IMMORTAL HUNTER", 2600)
    ]

    nonisolated static let ranks: [OogoRank] = table.enumerated().map {
        OogoRank(index: $0.offset, name: $0.element.0, works: $0.element.1)
    }

    nonisolated static let lastIndex: Int = table.count - 1

    /// Rank the hooman stands on. Nil until the first work is done.
    nonisolated static func rank(forWorks works: Int) -> OogoRank? {
        ranks.last { $0.works <= works }
    }

    /// Rank waiting ahead. Nil once the ladder is topped out.
    nonisolated static func next(afterWorks works: Int) -> OogoRank? {
        ranks.first { $0.works > works }
    }

    /// Work still needed for the next rank.
    nonisolated static func worksToNext(fromWorks works: Int) -> Int? {
        guard let next = next(afterWorks: works) else { return nil }
        return max(next.works - works, 0)
    }

    /// How far along the current rung the hooman stands, 0 to 1.
    nonisolated static func progress(works: Int) -> Double {
        guard let next = next(afterWorks: works) else { return 1 }
        let floorWorks = rank(forWorks: works)?.works ?? 0
        let span = Double(next.works - floorWorks)
        guard span > 0 else { return 1 }
        return min(max(Double(works - floorWorks) / span, 0), 1)
    }

    /// One line oog says when a hooman climbs.
    nonisolated static func praise(for rank: OogoRank) -> String {
        switch rank.index {
        case 0: return "first work done. hooman start now."
        case 1...4: return "small rank. real rank. keep go."
        case 5...9: return "tribe see hooman work."
        case 10...14: return "few hooman come this far."
        case 15...19: return "oog tell story about hooman."
        case 20...24: return "hooman name on cave wall now."
        default: return "no hooman stand higher. oog bow."
        }
    }
}
