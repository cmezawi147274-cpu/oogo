//
//  MovementCues.swift
//  Oogo
//
//  Oog words on how to do a move: set up, brace, breathe, tempo.
//

import Foundation

/// Four short coaching lines oog says about a movement.
nonisolated struct MovementCues: Hashable {
    nonisolated let setUp: String
    nonisolated let brace: String
    nonisolated let breathe: String
    nonisolated let tempo: String

    nonisolated init(_ setUp: String, _ brace: String, _ breathe: String, _ tempo: String) {
        self.setUp = setUp
        self.brace = brace
        self.breathe = breathe
        self.tempo = tempo
    }

    /// The three body lines, each with its tiny label.
    nonisolated var lines: [(label: String, text: String)] {
        [("set up", setUp), ("brace", brace), ("breathe", breathe)]
    }
}

/// Every cue oog knows. Movements without their own words fall back to the pattern.
nonisolated enum MovementCueBook {
    /// Cues for a movement, its own if written, else the pattern's.
    nonisolated static func cues(for movement: Movement) -> MovementCues {
        byMovement[movement.id] ?? fallback(for: movement.pattern)
    }

    nonisolated static func fallback(for pattern: MovementPattern) -> MovementCues {
        switch pattern {
        case .push:
            return MovementCues(
                "stand tall, shoulder down and back",
                "squeeze butt, ribs stay down",
                "air out when you push away",
                "push quick, come back slow"
            )
        case .pull:
            return MovementCues(
                "long spine, chest proud, grip hard",
                "middle tight, hips stay still",
                "air out as elbow drive back",
                "pull quick, let go slow"
            )
        case .squat:
            return MovementCues(
                "feet flat, toe point little out",
                "big air in belly, chest up",
                "hold air down, blow out on way up",
                "down slow, up strong"
            )
        case .hinge:
            return MovementCues(
                "hip go back, shin stay near straight",
                "grip floor with foot, lat tight",
                "sharp air out when hip snap",
                "snap fast, load slow"
            )
        case .core:
            return MovementCues(
                "stack rib over hip, eye forward",
                "squeeze middle like oog punch coming",
                "small breath through nose, never hold long",
                "slow and even, no rush"
            )
        }
    }

    // MARK: - Written cues

    nonisolated static let byMovement: [String: MovementCues] = [
        // Push
        "strict-press": .init("bell rest on back of wrist, elbow tuck", "squeeze butt, ribs down, no lean back", "air out as bell pass head", "up strong, down slow count two"),
        "push-press": .init("small dip with knee, bell in rack", "middle tight before dip", "air out at top of drive", "dip fast, press fast, lower slow"),
        "half-kneeling-press": .init("one knee down, front foot flat", "squeeze back butt cheek hard", "air out as bell go up", "smooth up, slow down"),
        "z-press": .init("sit on floor, leg straight in front", "sit tall, no round back", "air out as arm lock", "slow both way, no bounce"),
        "bottoms-up-press": .init("bell upside down, crush handle", "grip hard, whole arm tight", "small breath, stay calm", "slow. bell wobble mean slower"),
        "floor-press": .init("lay down, elbow at 45 from body", "press heel in floor, middle tight", "air out as arm push up", "down till elbow touch, then drive"),
        "push-jerk": .init("bell in rack, foot under hip", "brace before dip, no soft middle", "sharp air out under bell", "explode up, catch soft, stand"),
        "thruster": .init("bell in rack, feet squat wide", "middle tight all way down", "air out as you stand and press", "squat slow, stand and press one move"),
        "clean-and-press": .init("bell between foot, hinge to grab", "lat tight so bell stay close", "air out at top of press", "clean fast, press strong, drop slow"),
        "push-up": .init("hand under shoulder, body one line", "squeeze butt and middle, no sag hip", "air out on way up", "down slow count two, up quick"),
        "deficit-push-up": .init("hand on bell or book, chest go low", "hip in line with shoulder", "air out as you push floor away", "go deep slow, feel stretch"),
        "close-grip-push-up": .init("hand narrow, elbow brush ribs", "middle tight, no elbow flare", "air out at top", "down slow, up strong"),
        "archer-push-up": .init("hand wide, one arm stay straight", "hip square, no twist", "air out as bend arm push up", "slow to side, quick back"),
        "double-press": .init("two bell in rack, elbow tuck in", "squeeze butt, ribs down", "air out as both bell rise", "up together, down slow"),
        "double-floor-press": .init("lay down, two bell over chest", "heel press floor, middle tight", "air out as arm lock", "down till elbow kiss floor"),
        "dips": .init("grip bar, lean chest little forward", "shoulder pull down away from ear", "air out as you push up", "down to elbow bend square, up strong"),
        "bench-dip": .init("hand on edge behind you, hip close", "chest up, shoulder not shrug", "air out on way up", "down slow, up quick"),

        // Pull
        "gorilla-row": .init("two bell on floor, hinge over them", "one hand press bell down, other row", "air out as elbow go past ribs", "pull quick, lower slow"),
        "single-arm-row": .init("hinge over, free hand on knee", "hip square, no twist to sky", "air out as elbow drive back", "pull to hip, lower long"),
        "three-point-row": .init("hand on box or knee, back flat", "middle tight, hip level", "air out on pull", "pull quick, stretch bottom"),
        "renegade-row": .init("plank on two bell, feet wide", "hip stay still, no rock", "small breath, middle stays tight", "slow row. still hip more important"),
        "ballistic-row": .init("hinge over, bell hang", "lat tight before pull", "sharp air out on pull", "explode up, catch and slow down"),
        "pull-high-pull": .init("hinge, bell swing back between leg", "brace at bottom", "air out at top of pull", "hip snap fast, elbow follow"),
        "dead-clean-pull": .init("bell dead on floor each rep", "lat tight, arm stay soft rope", "air out on pull", "reset every rep, no bounce"),
        "pull-up": .init("full hang, hand just wide of shoulder", "squeeze butt, leg still, no kick", "air out as chin rise", "up strong, down slow count two"),
        "chin-up": .init("palm face you, full hang", "ribs down, no swing", "air out on way up", "up quick, lower slow"),
        "neutral-grip-pull-up": .init("palm face each other, hang long", "shoulder pull down first", "air out at top", "smooth up, slow down"),
        "inverted-row": .init("bar low, body one straight line", "squeeze butt, heel dig floor", "air out as chest touch bar", "pull quick, lower slow"),
        "double-row": .init("hinge over, one bell each hand", "back flat, hip square", "air out as both elbow go back", "pull together, lower slow"),
        "towel-pull-up": .init("towel over bar, grip end hard", "crush towel, shoulder down", "short breath, grip is work", "up strong, hold one count, down slow"),

        // Squat
        "goblet-squat": .init("bell at chest, elbow inside knee", "big air in belly, chest tall", "hold air down, blow out on stand", "down slow count three, up strong"),
        "front-rack-squat": .init("bell on wrist, elbow tuck ribs", "brace before you drop", "air out on way up", "down controlled, up fast"),
        "tempo-goblet-squat": .init("bell at chest, foot flat", "middle tight whole time", "breathe at top only", "five count down, one count up"),
        "pause-squat": .init("bell at chest, feet shoulder wide", "stay tight in hole, no relax", "hold air in pause", "down slow, pause two, up strong"),
        "cyclist-squat": .init("heel lift on plate or book", "chest tall, knee track over toe", "air out on stand", "down slow, feel thigh burn"),
        "reverse-lunge": .init("step back long, front shin near up", "middle tight, no lean forward", "air out as you stand", "step back slow, drive up quick"),
        "walking-lunge": .init("long step, knee kiss floor soft", "chest tall, eye forward", "air out each stand", "even pace, no bounce"),
        "forward-lunge": .init("step out, weight in front heel", "brace before step", "air out on push back", "step slow, push back strong"),
        "bulgarian-split-squat": .init("back foot on chair, front foot far", "hip square, chest tall", "air out on stand", "down slow count three, up strong"),
        "step-up": .init("box or stair knee high, whole foot on", "drive through top heel, no push off back", "air out on way up", "up strong, down slow"),
        "double-front-squat": .init("two bell in rack, elbow tight ribs", "big air, chest fight to stay tall", "blow out on stand", "down slow, up strong"),
        "rope-skip": .init("rope handle at hip, elbow near ribs", "middle tight, tall body", "breathe steady through nose", "small hop, wrist do work"),
        "rope-double-under": .init("rope longer, stand tall", "middle tight, no pike leg", "breathe every rep, no hold", "jump little higher, spin wrist fast"),
        "rope-high-knee": .init("knee to hip high each turn", "middle tight, chest up", "steady breath, keep rhythm", "fast foot, soft land"),
        "cossack-squat": .init("wide stance, sit to one side", "other leg straight, toe up", "air out on stand", "slow to bottom, own the stretch"),
        "lateral-lunge": .init("step wide, hip go back", "chest up, foot stay flat", "air out on push back", "step slow, push strong"),
        "skater-squat": .init("one leg, other leg back off floor", "middle tight, arm counter balance", "air out on stand", "very slow down, no fall"),
        "squat": .init("feet shoulder wide, toe little out", "big air, chest tall", "blow out on stand", "steady rhythm, full depth"),

        // Hinge
        "two-hand-swing": .init("bell one foot in front, hike back hard", "shin near straight, hip go back not down", "sharp air out at top", "snap hip fast, let bell fall"),
        "one-hand-swing": .init("one hand on handle, free arm mirror", "shoulder square, no twist", "sharp hiss at top", "snap fast, float, load again"),
        "hand-to-hand-swing": .init("swap hand at float top", "grip loose in swap, tight after", "air out on each snap", "let bell float, then swap"),
        "alternating-swing": .init("swap hand every rep at top", "middle tight through swap", "hiss out each snap", "snap fast, calm hand"),
        "dead-clean": .init("bell dead each rep, hinge to grab", "lat tight, bell stay near body", "air out as bell land in rack", "guide bell, no bang wrist"),
        "hinge-high-pull": .init("swing back hard, elbow lead up", "hip do work, arm just steer", "hiss out at top", "fast hip, quick elbow"),
        "clean": .init("hike bell back, tame arc close", "thumb spin back, bell land soft", "air out as bell land", "fast up, soft catch"),
        "snatch": .init("hike hard, punch hand through top", "middle tight, arm loose", "hiss at hip snap", "one move floor to sky, then slow down"),
        "alternating-snatch": .init("swap hand at bottom of swing", "shoulder packed at top", "sharp air out each rep", "steady rhythm, no rush"),
        "clean-and-jerk": .init("clean to rack, then dip and drive", "brace before each dip", "hiss out under bell", "explode, catch soft, stand tall"),
        "long-cycle": .init("clean then jerk, over and over", "breathe in rack, stay calm", "big air in rack, out on drive", "find slow rhythm you can keep"),
        "double-snatch": .init("two bell hike, punch both overhead", "middle very tight, arm loose", "hiss at hip snap", "fast up, control down"),
        "romanian-deadlift": .init("bell close to leg, soft knee", "long spine, lat tight", "air in on way down, out on stand", "slow down, feel hamstring, stand strong"),
        "kettlebell-deadlift": .init("bell between mid foot, hip back", "chest up, grip hard", "air out as you stand", "push floor away, slow down"),
        "single-leg-deadlift": .init("one leg, other leg go back like scale", "hip square to floor, no roll open", "air out on stand", "very slow, balance first"),
        "good-morning": .init("hand behind head, soft knee", "long spine, no round", "air out on stand", "slow down, stop before back round"),
        "hip-thrust": .init("shoulder on chair or floor, foot flat", "ribs down, squeeze butt at top", "air out at top squeeze", "up strong, hold one count, down slow"),
        "double-swing": .init("two bell, wide stance, hike between leg", "hip back hard, back stay flat", "sharp hiss at top", "snap fast, let bell drop"),

        // Core
        "suitcase-carry": .init("one bell at side, stand tall", "do not lean to bell side", "steady breath, walk calm", "slow step, ribs stacked"),
        "front-rack-carry": .init("bell on wrist, elbow tuck", "ribs down, breathe behind brace", "small breath through nose", "short step, no wobble"),
        "waiters-carry": .init("bell overhead, arm straight, elbow lock", "shoulder in socket, ribs down", "calm breath, keep walking", "slow step, eye forward"),
        "overhead-carry": .init("bell straight over shoulder", "middle tight, no back arch", "steady quiet breath", "short slow step"),
        "halo": .init("bell by horn, upside down at chest", "ribs down, hip still", "steady breath, no hold", "slow circle, close to head"),
        "around-the-world": .init("stand tall, pass bell around hip", "middle tight, hip still", "breathe with each pass", "smooth pass, no swing body"),
        "half-kneeling-chop": .init("one knee down, bell across body", "back butt squeeze, hip square", "air out at end of chop", "controlled both way"),
        "uppercut": .init("bell in rack, small hip turn", "back foot pivot, middle tight", "sharp air out on punch", "quick punch, slow return"),
        "figure-8-to-hold": .init("hinge low, pass bell through leg", "back flat whole time", "air out as bell come up", "smooth pass, tight hold at top"),
        "rotational-clean": .init("hinge, pivot back foot, clean to rack", "hip turn, spine stay long", "air out as bell land", "turn smooth, catch soft"),
        "rotational-deadlift": .init("bell to one side, pivot foot", "hip turn, no spine twist", "air out on stand", "slow turn, strong stand"),
        "windmill": .init("bell overhead, foot turn away", "eye on bell, back leg straight", "air out on stand", "very slow down, own each inch"),
        "bent-press": .init("bell in rack, hip push out to side", "eye on bell, spine long", "small breath, stay tight", "slow. this move take time"),
        "arm-bar": .init("lay on side, bell straight over shoulder", "elbow lock, eye on bell", "slow breath, let chest open", "move slow, hold and breathe"),
        "offset-march": .init("one bell, march knee to hip", "do not lean away from bell", "quiet breath, stay tall", "slow march, pause at top"),
        "front-rack-march": .init("bell in rack, march tall", "ribs down, middle tight", "breathe behind brace", "slow, high knee"),
        "overhead-march": .init("bell locked overhead, march", "shoulder packed, no back arch", "steady breath", "slow knee up, control down"),
        "plank": .init("elbow under shoulder, body one line", "squeeze butt and middle hard", "small breath, never hold air", "still. shake is fine"),
        "side-plank": .init("elbow under shoulder, hip stack", "push hip to sky, squeeze butt", "small steady breath", "hold still, no sink"),
        "hollow-hold": .init("low back press floor, arm by ear", "ribs down, middle tight", "small shallow breath", "still. lower leg only if back stay flat"),
        "hanging-knee-raise": .init("full hang, shoulder pull down", "no swing, ribs down", "air out as knee rise", "up controlled, down slow"),
        "hanging-leg-raise": .init("full hang, leg straight", "middle tight, stop the swing", "air out on way up", "slow up, slower down"),
        "dead-bug": .init("lay down, arm and knee over hip", "low back glue to floor", "air out as limb reach out", "slow. stop if back lift"),
        "bird-dog": .init("hand and knee down, back flat", "hip level, no rotate", "air out as you reach long", "slow reach, small pause")
    ]
}
