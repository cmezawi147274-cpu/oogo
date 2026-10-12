//
//  OogoModels.swift
//  Oogo
//
//  Core domain: movement patterns, day types, movements, logged sessions.
//

import Foundation

/// The five primitive patterns oogo trains. Carries and rotation live inside core.
nonisolated enum MovementPattern: String, Codable, CaseIterable, Identifiable {
    case push
    case pull
    case squat
    case hinge
    case core

    nonisolated var id: String { rawValue }

    /// Uppercase label used above movement names, e.g. `PULL`.
    nonisolated var label: String { rawValue.uppercased() }

    /// Caveman word for the pattern, used in plain sentences.
    nonisolated var caveWord: String {
        switch self {
        case .push: return "push"
        case .pull: return "pull"
        case .squat: return "legs"
        case .hinge: return "swing"
        case .core: return "middle"
        }
    }
}

/// The three oogo day types. Hunt and Gather alternate, Feast is rest.
nonisolated enum DayType: String, Codable, CaseIterable, Identifiable {
    case hunt
    case gather
    case feast

    nonisolated var id: String { rawValue }

    nonisolated var shortName: String {
        switch self {
        case .hunt: return "Hunt"
        case .gather: return "Gather"
        case .feast: return "Feast"
        }
    }

    nonisolated var title: String { "\(shortName) Day" }

    nonisolated var patterns: [MovementPattern] {
        switch self {
        case .hunt: return [.push, .squat]
        case .gather: return [.pull, .hinge, .core]
        case .feast: return []
        }
    }

    /// Dot separated summary, e.g. `Pull · Hinge · Core`.
    nonisolated var summaryDots: String {
        switch self {
        case .feast: return "Rest · Recover"
        default: return patterns.map { $0.rawValue.capitalized }.joined(separator: " · ")
        }
    }

    /// Short caveman line describing what the day is for.
    nonisolated var caveLine: String {
        switch self {
        case .hunt: return "push heavy. legs strong."
        case .gather: return "pull hard. swing bell. hold middle."
        case .feast: return "eat. sleep. walk slow."
        }
    }

    nonisolated var estimatedMinutes: Int {
        switch self {
        case .hunt: return 30
        case .gather: return 35
        case .feast: return 0
        }
    }
}

/// Weight display preference. Values are always stored in kilograms.
nonisolated enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg
    case lb

    nonisolated var id: String { rawValue }
    nonisolated var label: String { rawValue }
}

/// Kit the hooman may own. Movements that need missing kit stay hidden.
nonisolated enum OogoGear: String, Codable, CaseIterable, Identifiable {
    case oneBell
    case twoBells
    case pullUpBar
    case dipBars
    case jumpRope

    nonisolated var id: String { rawValue }

    nonisolated var label: String {
        switch self {
        case .oneBell: return "one bell"
        case .twoBells: return "two bell"
        case .pullUpBar: return "bar to hang"
        case .dipBars: return "dip bar"
        case .jumpRope: return "rope"
        }
    }

    /// Small words under the label on the kit step.
    nonisolated var hint: String {
        switch self {
        case .oneBell: return "all oogo need"
        case .twoBells: return "same size, two hand"
        case .pullUpBar: return "door bar count"
        case .dipBars: return "or two chair"
        case .jumpRope: return "leg go fast"
        }
    }

    nonisolated var symbol: String {
        switch self {
        case .oneBell: return "bag.fill"
        case .twoBells: return "scalemass"
        case .pullUpBar: return "figure.play"
        case .dipBars: return "equal"
        case .jumpRope: return "figure.jumprope"
        }
    }

    /// Bells are the whole app, so they cannot be unpicked entirely.
    nonisolated var isBell: Bool { self == .oneBell || self == .twoBells }
}

/// What the hooman came for. Shapes rest length and oog's words.
nonisolated enum OogoGoal: String, Codable, CaseIterable, Identifiable {
    case strong
    case move
    case lean
    case muscle
    case athletic
    case wind
    case habit

    nonisolated var id: String { rawValue }

    nonisolated var label: String {
        switch self {
        case .strong: return "get strong"
        case .move: return "move better"
        case .lean: return "lose fat"
        case .muscle: return "build meat"
        case .athletic: return "feel fast"
        case .wind: return "better wind"
        case .habit: return "just move more"
        }
    }

    nonisolated var symbol: String {
        switch self {
        case .strong: return "bolt.fill"
        case .move: return "figure.flexibility"
        case .lean: return "flame.fill"
        case .muscle: return "figure.strengthtraining.traditional"
        case .athletic: return "figure.run"
        case .wind: return "wind"
        case .habit: return "calendar"
        }
    }

    /// Rest oog starts the hooman on, in seconds.
    nonisolated var restSeconds: Int {
        switch self {
        case .strong, .muscle: return 60
        case .move, .habit: return 45
        case .lean, .wind, .athletic: return 30
        }
    }

    /// One line oog says back when the plan is revealed.
    nonisolated var planLine: String {
        switch self {
        case .strong: return "heavy bell. low rep. get strong."
        case .move: return "slow rep. full range. move good."
        case .lean: return "short rest. keep move. fat go."
        case .muscle: return "more round. more rep. grow meat."
        case .athletic: return "fast swing. quick foot. feel light."
        case .wind: return "short rest. long set. lung big."
        case .habit: return "small work. every week. no miss."
        }
    }
}

/// How a movement counts its work.
nonisolated enum RepKind {
    case reps
    case repsPerSide
    case seconds
    case secondsPerSide

    nonisolated var isTimed: Bool { self == .seconds || self == .secondsPerSide }

    /// How far one tap of the stepper moves the number.
    nonisolated var step: Int { isTimed ? 5 : 1 }

    nonisolated var lowest: Int { isTimed ? 10 : 1 }
    nonisolated var highest: Int { isTimed ? 180 : 50 }
}

/// A single exercise. `reps` holds the default, which the hooman can tune per move.
nonisolated struct Movement: Codable, Identifiable, Hashable {
    nonisolated let id: String
    nonisolated let name: String
    nonisolated let pattern: MovementPattern
    nonisolated let reps: String
    nonisolated let repsLabel: String
    nonisolated let usesBell: Bool
    /// Kit this movement cannot happen without.
    nonisolated var needs: OogoGear? = nil

    /// How this movement counts, read off its default reps string.
    nonisolated var repKind: RepKind {
        let perSide = reps.contains("/side")
        if reps.contains("sec") { return perSide ? .secondsPerSide : .seconds }
        return perSide ? .repsPerSide : .reps
    }

    /// Leading number of the default reps string, e.g. 8 from `8/side`.
    nonisolated var defaultRepValue: Int {
        Int(reps.prefix { $0.isNumber }) ?? 1
    }

    /// Builds a reps string for a chosen number, e.g. `10/side`, `60 sec`.
    nonisolated func repsText(for value: Int) -> String {
        switch repKind {
        case .reps: return "\(value)"
        case .repsPerSide: return "\(value)/side"
        case .seconds: return "\(value) sec"
        case .secondsPerSide: return "\(value) sec/side"
        }
    }

    /// A copy of this movement carrying a tuned rep count.
    nonisolated func withReps(_ value: Int) -> Movement {
        Movement(
            id: id,
            name: name,
            pattern: pattern,
            reps: repsText(for: value),
            repsLabel: repsLabel,
            usesBell: usesBell,
            needs: needs
        )
    }
}

/// A finished training session.
nonisolated struct SessionLog: Codable, Identifiable, Hashable {
    nonisolated let id: UUID
    nonisolated let date: Date
    nonisolated let dayType: DayType
    nonisolated let movementNames: [String]
    nonisolated let rounds: Int
    nonisolated let bellWeight: Int
    nonisolated let durationSeconds: Int
    nonisolated let feel: String
    /// True for the starting history oog paints on the wall. Never counts as a hunt.
    nonisolated let isSeed: Bool?

    nonisolated init(
        id: UUID = UUID(),
        date: Date,
        dayType: DayType,
        movementNames: [String],
        rounds: Int,
        bellWeight: Int,
        durationSeconds: Int,
        feel: String,
        isSeed: Bool? = nil
    ) {
        self.id = id
        self.date = date
        self.dayType = dayType
        self.movementNames = movementNames
        self.rounds = rounds
        self.bellWeight = bellWeight
        self.durationSeconds = durationSeconds
        self.feel = feel
        self.isSeed = isSeed
    }
}

/// Work currently being performed. Carries a resume point so interrupted work can continue.
nonisolated struct ActiveSession: Identifiable {
    nonisolated let id: UUID
    nonisolated let dayType: DayType
    nonisolated let movements: [Movement]
    nonisolated let rounds: Int
    nonisolated let restSeconds: Int
    nonisolated let startRound: Int
    nonisolated let startMovementIndex: Int
    nonisolated let startElapsed: Int

    nonisolated init(
        id: UUID = UUID(),
        dayType: DayType,
        movements: [Movement],
        rounds: Int,
        restSeconds: Int,
        startRound: Int = 1,
        startMovementIndex: Int = 0,
        startElapsed: Int = 0
    ) {
        self.id = id
        self.dayType = dayType
        self.movements = movements
        self.rounds = rounds
        self.restSeconds = restSeconds
        self.startRound = startRound
        self.startMovementIndex = startMovementIndex
        self.startElapsed = startElapsed
    }
}

/// Persisted resume point for work that was left unfinished.
nonisolated struct WorkSnapshot: Codable, Equatable {
    nonisolated let dayType: DayType
    nonisolated let movementIDs: [String]
    nonisolated let rounds: Int
    nonisolated let restSeconds: Int
    nonisolated let round: Int
    nonisolated let movementIndex: Int
    nonisolated let elapsedSeconds: Int
    nonisolated let savedAt: Date

    nonisolated var movements: [Movement] {
        movementIDs.compactMap { MovementLibrary.movement(id: $0) }
    }

    /// Rebuilds a session that picks up exactly where work stopped.
    nonisolated var session: ActiveSession {
        ActiveSession(
            dayType: dayType,
            movements: movements,
            rounds: rounds,
            restSeconds: restSeconds,
            startRound: round,
            startMovementIndex: movementIndex,
            startElapsed: elapsedSeconds
        )
    }
}

/// How the hooman felt after work.
nonisolated enum SessionFeel: String, CaseIterable, Identifiable {
    case easy
    case good
    case hard
    case death

    nonisolated var id: String { rawValue }
}

/// Every movement oogo knows, grouped by pattern.
nonisolated enum MovementLibrary {
    // MARK: Push — upper body strength (hunt day)

    nonisolated static let push: [Movement] = [
        Movement(id: "strict-press", name: "Strict Press", pattern: .push, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "push-press", name: "Push Press", pattern: .push, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "half-kneeling-press", name: "Half-Kneeling Press", pattern: .push, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "z-press", name: "Z Press", pattern: .push, reps: "5/side", repsLabel: "reps", usesBell: true),
        Movement(id: "bottoms-up-press", name: "Bottoms-Up Press", pattern: .push, reps: "5/side", repsLabel: "reps", usesBell: true),
        Movement(id: "floor-press", name: "Floor Press", pattern: .push, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "push-jerk", name: "Push Jerk", pattern: .push, reps: "5/side", repsLabel: "reps", usesBell: true),
        Movement(id: "thruster", name: "Thruster", pattern: .push, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "clean-and-press", name: "Clean & Press", pattern: .push, reps: "5/side", repsLabel: "reps", usesBell: true),
        Movement(id: "push-up", name: "Push-up", pattern: .push, reps: "12", repsLabel: "reps", usesBell: false),
        Movement(id: "deficit-push-up", name: "Deficit Push-up", pattern: .push, reps: "10", repsLabel: "reps", usesBell: false),
        Movement(id: "close-grip-push-up", name: "Close-Grip Push-up", pattern: .push, reps: "10", repsLabel: "reps", usesBell: false),
        Movement(id: "archer-push-up", name: "Archer Push-up", pattern: .push, reps: "6/side", repsLabel: "reps", usesBell: false),
        Movement(id: "double-press", name: "Double Press", pattern: .push, reps: "5", repsLabel: "reps", usesBell: true, needs: .twoBells),
        Movement(id: "double-floor-press", name: "Double Floor Press", pattern: .push, reps: "8", repsLabel: "reps", usesBell: true, needs: .twoBells),
        Movement(id: "dips", name: "Dips", pattern: .push, reps: "8", repsLabel: "reps", usesBell: false, needs: .dipBars),
        Movement(id: "bench-dip", name: "Bench Dip", pattern: .push, reps: "12", repsLabel: "reps", usesBell: false, needs: .dipBars),
    ]

    // MARK: Pull — back, grip, lats (gather day)

    nonisolated static let pull: [Movement] = [
        Movement(id: "gorilla-row", name: "Gorilla Row", pattern: .pull, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "single-arm-row", name: "Single-Arm Row", pattern: .pull, reps: "10/side", repsLabel: "reps", usesBell: true),
        Movement(id: "three-point-row", name: "Three-Point Row", pattern: .pull, reps: "10/side", repsLabel: "reps", usesBell: true),
        Movement(id: "renegade-row", name: "Renegade Row", pattern: .pull, reps: "6/side", repsLabel: "reps", usesBell: true, needs: .twoBells),
        Movement(id: "ballistic-row", name: "Ballistic Row", pattern: .pull, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "pull-high-pull", name: "High Pull", pattern: .pull, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "dead-clean-pull", name: "Dead Clean Pull", pattern: .pull, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "pull-up", name: "Pull-up", pattern: .pull, reps: "6", repsLabel: "reps", usesBell: false, needs: .pullUpBar),
        Movement(id: "chin-up", name: "Chin-up", pattern: .pull, reps: "6", repsLabel: "reps", usesBell: false, needs: .pullUpBar),
        Movement(id: "neutral-grip-pull-up", name: "Neutral-Grip Pull-up", pattern: .pull, reps: "6", repsLabel: "reps", usesBell: false, needs: .pullUpBar),
        Movement(id: "inverted-row", name: "Inverted Row", pattern: .pull, reps: "10", repsLabel: "reps", usesBell: false, needs: .pullUpBar),
        Movement(id: "double-row", name: "Double Row", pattern: .pull, reps: "8", repsLabel: "reps", usesBell: true, needs: .twoBells),
        Movement(id: "towel-pull-up", name: "Towel Pull-up", pattern: .pull, reps: "5", repsLabel: "reps", usesBell: false, needs: .pullUpBar),
    ]

    // MARK: Squat — strength, stability, mobility (hunt day)

    nonisolated static let squat: [Movement] = [
        Movement(id: "goblet-squat", name: "Goblet Squat", pattern: .squat, reps: "10", repsLabel: "reps", usesBell: true),
        Movement(id: "front-rack-squat", name: "Front Rack Squat", pattern: .squat, reps: "8", repsLabel: "reps", usesBell: true),
        Movement(id: "tempo-goblet-squat", name: "Tempo Goblet Squat", pattern: .squat, reps: "8", repsLabel: "slow reps", usesBell: true),
        Movement(id: "pause-squat", name: "Pause Squat", pattern: .squat, reps: "8", repsLabel: "reps", usesBell: true),
        Movement(id: "cyclist-squat", name: "Cyclist Squat", pattern: .squat, reps: "10", repsLabel: "reps", usesBell: true),
        Movement(id: "reverse-lunge", name: "Reverse Lunge", pattern: .squat, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "walking-lunge", name: "Walking Lunge", pattern: .squat, reps: "10/side", repsLabel: "steps", usesBell: true),
        Movement(id: "forward-lunge", name: "Forward Lunge", pattern: .squat, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "bulgarian-split-squat", name: "Bulgarian Split Squat", pattern: .squat, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "step-up", name: "Step-Up", pattern: .squat, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "double-front-squat", name: "Double Front Squat", pattern: .squat, reps: "6", repsLabel: "reps", usesBell: true, needs: .twoBells),
        Movement(id: "rope-skip", name: "Rope Skip", pattern: .squat, reps: "60 sec", repsLabel: "work", usesBell: false, needs: .jumpRope),
        Movement(id: "rope-double-under", name: "Double Under", pattern: .squat, reps: "30", repsLabel: "reps", usesBell: false, needs: .jumpRope),
        Movement(id: "rope-high-knee", name: "Rope High Knee", pattern: .squat, reps: "40 sec", repsLabel: "work", usesBell: false, needs: .jumpRope),
        Movement(id: "cossack-squat", name: "Cossack Squat", pattern: .squat, reps: "6/side", repsLabel: "reps", usesBell: false),
        Movement(id: "lateral-lunge", name: "Lateral Lunge", pattern: .squat, reps: "8/side", repsLabel: "reps", usesBell: false),
        Movement(id: "skater-squat", name: "Skater Squat", pattern: .squat, reps: "6/side", repsLabel: "reps", usesBell: false),
        Movement(id: "squat", name: "Squat", pattern: .squat, reps: "20", repsLabel: "reps", usesBell: false),
    ]

    // MARK: Hinge — posterior chain, power, ballistics (gather day)

    nonisolated static let hinge: [Movement] = [
        Movement(id: "two-hand-swing", name: "Two-Hand Swing", pattern: .hinge, reps: "15", repsLabel: "reps", usesBell: true),
        Movement(id: "one-hand-swing", name: "One-Hand Swing", pattern: .hinge, reps: "10/side", repsLabel: "reps", usesBell: true),
        Movement(id: "hand-to-hand-swing", name: "Hand-to-Hand Swing", pattern: .hinge, reps: "20", repsLabel: "reps", usesBell: true),
        Movement(id: "alternating-swing", name: "Alternating Swing", pattern: .hinge, reps: "20", repsLabel: "reps", usesBell: true),
        Movement(id: "dead-clean", name: "Dead Clean", pattern: .hinge, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "hinge-high-pull", name: "High Pull", pattern: .hinge, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "clean", name: "Clean", pattern: .hinge, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "snatch", name: "Snatch", pattern: .hinge, reps: "5/side", repsLabel: "reps", usesBell: true),
        Movement(id: "alternating-snatch", name: "Alternating Snatch", pattern: .hinge, reps: "10", repsLabel: "reps", usesBell: true),
        Movement(id: "clean-and-jerk", name: "Clean & Jerk", pattern: .hinge, reps: "5/side", repsLabel: "reps", usesBell: true),
        Movement(id: "long-cycle", name: "Long Cycle", pattern: .hinge, reps: "60 sec", repsLabel: "work", usesBell: true),
        Movement(id: "double-snatch", name: "Double Snatch", pattern: .hinge, reps: "5", repsLabel: "reps", usesBell: true, needs: .twoBells),
        Movement(id: "romanian-deadlift", name: "Romanian Deadlift", pattern: .hinge, reps: "10", repsLabel: "reps", usesBell: true),
        Movement(id: "kettlebell-deadlift", name: "Kettlebell Deadlift", pattern: .hinge, reps: "8", repsLabel: "reps", usesBell: true),
        Movement(id: "single-leg-deadlift", name: "Single-Leg Deadlift", pattern: .hinge, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "good-morning", name: "Good Morning", pattern: .hinge, reps: "12", repsLabel: "reps", usesBell: false),
        Movement(id: "hip-thrust", name: "Hip Thrust", pattern: .hinge, reps: "12", repsLabel: "reps", usesBell: true),
        Movement(id: "double-swing", name: "Double Swing", pattern: .hinge, reps: "12", repsLabel: "reps", usesBell: true, needs: .twoBells),
    ]

    // MARK: Core — bracing, carries, rotation (gather day)

    nonisolated static let core: [Movement] = [
        Movement(id: "suitcase-carry", name: "Suitcase Carry", pattern: .core, reps: "20/side", repsLabel: "steps", usesBell: true),
        Movement(id: "front-rack-carry", name: "Front Rack Carry", pattern: .core, reps: "20/side", repsLabel: "steps", usesBell: true),
        Movement(id: "waiters-carry", name: "Waiter's Carry", pattern: .core, reps: "15/side", repsLabel: "steps", usesBell: true),
        Movement(id: "overhead-carry", name: "Overhead Carry", pattern: .core, reps: "15/side", repsLabel: "steps", usesBell: true),
        Movement(id: "halo", name: "Halo", pattern: .core, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "around-the-world", name: "Around the World", pattern: .core, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "half-kneeling-chop", name: "Half-Kneeling Chop", pattern: .core, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "uppercut", name: "Uppercut", pattern: .core, reps: "10/side", repsLabel: "reps", usesBell: true),
        Movement(id: "figure-8-to-hold", name: "Figure-8 to Hold", pattern: .core, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "rotational-clean", name: "Rotational Clean", pattern: .core, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "rotational-deadlift", name: "Rotational Deadlift", pattern: .core, reps: "8/side", repsLabel: "reps", usesBell: true),
        Movement(id: "windmill", name: "Windmill", pattern: .core, reps: "6/side", repsLabel: "reps", usesBell: true),
        Movement(id: "bent-press", name: "Bent Press", pattern: .core, reps: "4/side", repsLabel: "reps", usesBell: true),
        Movement(id: "arm-bar", name: "Arm Bar", pattern: .core, reps: "30 sec/side", repsLabel: "hold", usesBell: true),
        Movement(id: "offset-march", name: "Offset March", pattern: .core, reps: "20/side", repsLabel: "steps", usesBell: true),
        Movement(id: "front-rack-march", name: "Front Rack March", pattern: .core, reps: "20", repsLabel: "steps", usesBell: true),
        Movement(id: "overhead-march", name: "Overhead March", pattern: .core, reps: "15/side", repsLabel: "steps", usesBell: true),
        Movement(id: "plank", name: "Plank", pattern: .core, reps: "45 sec", repsLabel: "hold", usesBell: false),
        Movement(id: "side-plank", name: "Side Plank", pattern: .core, reps: "30 sec/side", repsLabel: "hold", usesBell: false),
        Movement(id: "hollow-hold", name: "Hollow Hold", pattern: .core, reps: "30 sec", repsLabel: "hold", usesBell: false),
        Movement(id: "hanging-knee-raise", name: "Hanging Knee Raise", pattern: .core, reps: "10", repsLabel: "reps", usesBell: false, needs: .pullUpBar),
        Movement(id: "hanging-leg-raise", name: "Hanging Leg Raise", pattern: .core, reps: "8", repsLabel: "reps", usesBell: false, needs: .pullUpBar),
        Movement(id: "dead-bug", name: "Dead Bug", pattern: .core, reps: "10/side", repsLabel: "reps", usesBell: false),
        Movement(id: "bird-dog", name: "Bird Dog", pattern: .core, reps: "10/side", repsLabel: "reps", usesBell: false),
    ]

    nonisolated static let all: [Movement] = push + pull + squat + hinge + core

    /// Every movement that leans on a given piece of kit.
    nonisolated static func movements(needing gear: OogoGear) -> [Movement] {
        all.filter { $0.needs == gear }
    }

    /// Movements for a pattern the hooman can actually do with the kit owned.
    nonisolated static func movements(for pattern: MovementPattern, gear: Set<OogoGear>) -> [Movement] {
        let all = movements(for: pattern)
        let usable = all.filter { movement in
            guard let needs = movement.needs else { return true }
            return gear.contains(needs)
        }
        return usable.isEmpty ? all : usable
    }

    nonisolated static func movements(for pattern: MovementPattern) -> [Movement] {
        switch pattern {
        case .push: return push
        case .pull: return pull
        case .squat: return squat
        case .hinge: return hinge
        case .core: return core
        }
    }

    nonisolated static func first(for pattern: MovementPattern) -> Movement {
        movements(for: pattern).first ?? all[0]
    }

    nonisolated static func movement(id: String) -> Movement? {
        all.first { $0.id == id }
    }

    /// Loose work offered on rest days: mobility plus a light carry.
    nonisolated static var feastPair: [Movement] {
        [
            movement(id: "halo") ?? first(for: .core),
            movement(id: "cossack-squat") ?? first(for: .squat)
        ]
    }
}
