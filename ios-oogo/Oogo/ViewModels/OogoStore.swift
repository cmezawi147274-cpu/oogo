//
//  OogoStore.swift
//  Oogo
//
//  Single source of truth: plan, history, streaks, preferences, resume point.
//

import Foundation
import Observation
import SwiftUI
import UserNotifications

@Observable
final class OogoStore {
    // MARK: - Plan (persisted)

    var rounds: Int {
        didSet { defaults.set(rounds, forKey: Key.rounds) }
    }

    var bellWeight: Int {
        didSet { defaults.set(bellWeight, forKey: Key.bellWeight) }
    }

    var restSeconds: Int {
        didSet { defaults.set(restSeconds, forKey: Key.restSeconds) }
    }

    /// 3, 4 or 5 training days per week.
    var daysPerWeek: Int {
        didSet {
            defaults.set(daysPerWeek, forKey: Key.daysPerWeek)
            refreshNudges()
        }
    }

    var weightUnit: WeightUnit {
        didSet { defaults.set(weightUnit.rawValue, forKey: Key.weightUnit) }
    }

    /// Bell sizes in kilograms the hooman actually owns.
    private(set) var ownedBells: Set<Int>

    /// Kit the hooman owns. Movements needing missing kit stay hidden.
    private(set) var gear: Set<OogoGear>

    /// What hooman came for. Two at most, newest last.
    private(set) var goals: [OogoGoal]

    /// False until oog finished meeting the hooman.
    var hasOnboarded: Bool {
        didSet { defaults.set(hasOnboarded, forKey: Key.onboarded) }
    }

    /// True once the hooman held the stone and committed. Happens once, ever.
    var hasCommitted: Bool {
        didSet { defaults.set(hasCommitted, forKey: Key.committed) }
    }

    /// True once this phone has settled its cloud plan: either it took the plan
    /// already waiting in the sky, or the sky accepted the plan this phone carried
    /// up. From then on the plan on this phone is the truth, and a routine carry
    /// must never paint older cloud values back over it.
    private(set) var hasAdoptedCloudPlan: Bool {
        didSet { defaults.set(hasAdoptedCloudPlan, forKey: Key.adoptedPlan) }
    }

    /// Chosen movement id per pattern.
    private(set) var selections: [MovementPattern: String]

    /// Rep count the hooman tuned, per movement id. Missing means use the default.
    private(set) var repOverrides: [String: Int]

    var sessions: [SessionLog] {
        didSet { persistSessions() }
    }

    var isMember: Bool {
        didSet { defaults.set(isMember, forKey: Key.isMember) }
    }

    var hoomanName: String {
        didSet { defaults.set(hoomanName, forKey: Key.name) }
    }

    var remindersOn: Bool {
        didSet {
            defaults.set(remindersOn, forKey: Key.reminders)
            refreshNudges()
        }
    }

    /// Hour of day oog shouts on work days.
    var nudgeHour: Int {
        didSet {
            defaults.set(nudgeHour, forKey: Key.nudgeHour)
            refreshNudges()
        }
    }

    var nudgeMinute: Int {
        didSet {
            defaults.set(nudgeMinute, forKey: Key.nudgeMinute)
            refreshNudges()
        }
    }

    /// Rank the hooman climbed on the last logged work. Cleared by the next work.
    private(set) var rankNote: String?

    /// Unfinished work, restored on next launch.
    private(set) var unfinishedWork: WorkSnapshot?

    private(set) var memberSince: Date

    private let defaults: UserDefaults

    /// Bell size the hooman already declined to move up from.
    private var dismissedBellNudge: Int {
        didSet { defaults.set(dismissedBellNudge, forKey: Key.bellNudge) }
    }

    /// Ids of finished work already written to the wall, oldest first. Persisted so
    /// one finished work can never be logged twice, even across a relaunch.
    private var loggedWorkIDs: [String]

    private enum Key {
        static let rounds = "oogo.rounds"
        static let bellWeight = "oogo.bellWeight"
        static let restSeconds = "oogo.restSeconds"
        static let daysPerWeek = "oogo.daysPerWeek"
        static let weightUnit = "oogo.weightUnit"
        static let ownedBells = "oogo.ownedBells"
        static let selections = "oogo.selections"
        static let repOverrides = "oogo.repOverrides"
        static let sessions = "oogo.sessions"
        static let isMember = "oogo.isMember"
        static let name = "oogo.name"
        static let reminders = "oogo.reminders"
        static let since = "oogo.memberSince"
        static let seeded = "oogo.seeded.v1"
        static let resume = "oogo.resume"
        static let bellNudge = "oogo.bellNudge"
        static let gear = "oogo.gear"
        static let goals = "oogo.goals"
        static let onboarded = "oogo.onboarded.v1"
        static let committed = "oogo.committed.v1"
        static let nudgeHour = "oogo.nudgeHour"
        static let nudgeMinute = "oogo.nudgeMinute"
        static let rankNote = "oogo.rankNote"
        static let loggedWorks = "oogo.loggedWorks.v1"
        static let adoptedPlan = "oogo.adoptedCloudPlan.v1"
    }

    /// Every bell size oogo knows about, in kilograms.
    nonisolated static let bellCatalog: [Int] = [8, 12, 16, 20, 24, 28, 32, 36, 40, 48]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rounds = defaults.object(forKey: Key.rounds) as? Int ?? 3
        bellWeight = defaults.object(forKey: Key.bellWeight) as? Int ?? 24
        restSeconds = defaults.object(forKey: Key.restSeconds) as? Int ?? 45
        daysPerWeek = defaults.object(forKey: Key.daysPerWeek) as? Int ?? 3
        weightUnit = WeightUnit(rawValue: defaults.string(forKey: Key.weightUnit) ?? "kg") ?? .kg
        isMember = defaults.bool(forKey: Key.isMember)
        hoomanName = defaults.string(forKey: Key.name) ?? "hooman"
        remindersOn = defaults.object(forKey: Key.reminders) as? Bool ?? true
        nudgeHour = defaults.object(forKey: Key.nudgeHour) as? Int ?? 7
        nudgeMinute = defaults.object(forKey: Key.nudgeMinute) as? Int ?? 0
        rankNote = defaults.string(forKey: Key.rankNote)
        dismissedBellNudge = defaults.object(forKey: Key.bellNudge) as? Int ?? 0
        loggedWorkIDs = defaults.array(forKey: Key.loggedWorks) as? [String] ?? []
        hasOnboarded = defaults.bool(forKey: Key.onboarded)
        hasCommitted = defaults.bool(forKey: Key.committed)
        // Restored before any carry can run. A missing key means a genuine first
        // run, never a relaunch.
        hasAdoptedCloudPlan = defaults.bool(forKey: Key.adoptedPlan)

        // Unknown raw values (old bench / box / rings) simply drop out here.
        let storedGear = defaults.array(forKey: Key.gear) as? [String] ?? []
        var restoredGear = Set(storedGear.compactMap { OogoGear(rawValue: $0) })
        // One bell is the floor: oogo is a kettlebell app.
        restoredGear.insert(.oneBell)
        gear = restoredGear

        let storedGoals = defaults.array(forKey: Key.goals) as? [String] ?? []
        goals = storedGoals.compactMap { OogoGoal(rawValue: $0) }

        if let stored = defaults.array(forKey: Key.ownedBells) as? [Int], !stored.isEmpty {
            ownedBells = Set(stored)
        } else {
            ownedBells = [16, 24]
        }

        if let stored = defaults.object(forKey: Key.since) as? Date {
            memberSince = stored
        } else {
            let now = Date()
            defaults.set(now, forKey: Key.since)
            memberSince = now
        }

        var restored: [MovementPattern: String] = [:]
        if let raw = defaults.dictionary(forKey: Key.selections) as? [String: String] {
            for (key, value) in raw {
                if let pattern = MovementPattern(rawValue: key) {
                    restored[pattern] = value
                }
            }
        }
        selections = restored
        repOverrides = defaults.dictionary(forKey: Key.repOverrides) as? [String: Int] ?? [:]

        if let data = defaults.data(forKey: Key.sessions),
           let decoded = try? JSONDecoder().decode([SessionLog].self, from: data) {
            sessions = decoded
        } else {
            sessions = []
        }

        if let data = defaults.data(forKey: Key.resume),
           let decoded = try? JSONDecoder().decode(WorkSnapshot.self, from: data),
           Calendar.current.isDateInToday(decoded.savedAt) {
            unfinishedWork = decoded
        } else {
            unfinishedWork = nil
            defaults.removeObject(forKey: Key.resume)
        }

        if !defaults.bool(forKey: Key.seeded) {
            defaults.set(true, forKey: Key.seeded)
            sessions = Self.seedHistory(daysPerWeek: daysPerWeek)
        }

        persistGear()
        dropUnreachableSelections()
    }

    // MARK: - Movement selection

    /// Movements for a pattern, minus anything the hooman has no kit for.
    func options(for pattern: MovementPattern) -> [Movement] {
        MovementLibrary.movements(for: pattern, gear: gear)
    }

    func movement(for pattern: MovementPattern) -> Movement {
        let usable = options(for: pattern)
        if let id = selections[pattern], let found = usable.first(where: { $0.id == id }) {
            return found
        }
        return usable.first ?? MovementLibrary.first(for: pattern)
    }

    func select(_ movement: Movement) {
        selections[movement.pattern] = movement.id
        let raw = selections.reduce(into: [String: String]()) { partial, entry in
            partial[entry.key.rawValue] = entry.value
        }
        defaults.set(raw, forKey: Key.selections)
    }

    /// The chosen movement for a pattern, carrying the hooman's own rep count.
    func tunedMovement(for pattern: MovementPattern) -> Movement {
        tuned(movement(for: pattern))
    }

    /// A movement with the hooman's rep count applied.
    func tuned(_ movement: Movement) -> Movement {
        movement.withReps(repValue(for: movement))
    }

    func movements(for dayType: DayType) -> [Movement] {
        let base = dayType == .feast ? MovementLibrary.feastPair : dayType.patterns.map { movement(for: $0) }
        return base.map { tuned($0) }
    }

    /// Rebuilds interrupted work, keeping current rep choices.
    func session(resuming snapshot: WorkSnapshot) -> ActiveSession {
        ActiveSession(
            dayType: snapshot.dayType,
            movements: snapshot.movements.map { tuned($0) },
            rounds: snapshot.rounds,
            restSeconds: snapshot.restSeconds,
            startRound: snapshot.round,
            startMovementIndex: snapshot.movementIndex,
            startElapsed: snapshot.elapsedSeconds
        )
    }

    // MARK: - Reps per movement

    /// Rep count for a movement: the tuned one if set, else the library default.
    func repValue(for movement: Movement) -> Int {
        repOverrides[movement.id] ?? movement.defaultRepValue
    }

    /// Reps as shown, e.g. `10/side`, `60 sec`.
    func repsText(for movement: Movement) -> String {
        movement.repsText(for: repValue(for: movement))
    }

    func canRepUp(_ movement: Movement) -> Bool {
        repValue(for: movement) < movement.repKind.highest
    }

    func canRepDown(_ movement: Movement) -> Bool {
        repValue(for: movement) > movement.repKind.lowest
    }

    func stepReps(_ movement: Movement, by direction: Int) {
        let kind = movement.repKind
        let next = repValue(for: movement) + (direction * kind.step)
        setReps(min(max(next, kind.lowest), kind.highest), for: movement)
    }

    func setReps(_ value: Int, for movement: Movement) {
        if value == movement.defaultRepValue {
            repOverrides.removeValue(forKey: movement.id)
        } else {
            repOverrides[movement.id] = value
        }
        defaults.set(repOverrides, forKey: Key.repOverrides)
    }

    /// True when the hooman moved this movement off its default count.
    func hasCustomReps(_ movement: Movement) -> Bool {
        repOverrides[movement.id] != nil
    }

    func resetReps(for movement: Movement) {
        setReps(movement.defaultRepValue, for: movement)
    }

    // MARK: - Onboarding answers

    /// True when the hooman owns a matched pair, which unlocks double-bell work.
    var hasTwoBells: Bool { gear.contains(.twoBells) }

    func toggleGear(_ item: OogoGear) {
        switch item {
        case .oneBell:
            // One bell is never off. Tapping it just steps down from a pair.
            gear.insert(.oneBell)
            gear.remove(.twoBells)
        case .twoBells:
            gear.insert(.oneBell)
            if gear.contains(.twoBells) {
                gear.remove(.twoBells)
            } else {
                gear.insert(.twoBells)
            }
        default:
            if gear.contains(item) {
                gear.remove(item)
            } else {
                gear.insert(item)
            }
        }
        persistGear()
        dropUnreachableSelections()
    }

    private func persistGear() {
        defaults.set(gear.map(\.rawValue).sorted(), forKey: Key.gear)
    }

    /// Keeps two goals at most: a third pushes the oldest one out.
    func toggleGoal(_ goal: OogoGoal) {
        if let index = goals.firstIndex(of: goal) {
            goals.remove(at: index)
        } else {
            goals.append(goal)
            if goals.count > 2 { goals.removeFirst() }
        }
        defaults.set(goals.map(\.rawValue), forKey: Key.goals)
    }

    /// Rest length oog starts the hooman on, read off the chosen goals.
    func applyGoalsToRest() {
        guard let shortest = goals.map(\.restSeconds).min() else { return }
        restSeconds = shortest
    }

    func setOwnedBells(_ bells: Set<Int>) {
        guard !bells.isEmpty else { return }
        ownedBells = bells
        defaults.set(Array(bells).sorted(), forKey: Key.ownedBells)
        snapBellToOwned()
    }

    /// Forgets any chosen move the hooman no longer has kit for.
    private func dropUnreachableSelections() {
        for (pattern, id) in selections {
            let usable = options(for: pattern)
            if !usable.contains(where: { $0.id == id }) {
                selections.removeValue(forKey: pattern)
            }
        }
        let raw = selections.reduce(into: [String: String]()) { partial, entry in
            partial[entry.key.rawValue] = entry.value
        }
        defaults.set(raw, forKey: Key.selections)
    }

    // MARK: - Bells owned

    /// Owned bells, light to heavy.
    var bellLadder: [Int] {
        let owned = ownedBells.sorted()
        return owned.isEmpty ? Self.bellCatalog : owned
    }

    /// Every bell on the floor is fair game: hoomans collect sizes over time.
    func toggleBell(_ weight: Int) {
        if ownedBells.contains(weight) {
            guard ownedBells.count > 1 else { return }
            ownedBells.remove(weight)
        } else {
            ownedBells.insert(weight)
        }
        defaults.set(Array(ownedBells).sorted(), forKey: Key.ownedBells)
        snapBellToOwned()
    }

    /// Keeps the working bell on a size that actually exists.
    private func snapBellToOwned() {
        guard !ownedBells.contains(bellWeight) else { return }
        let ladder = bellLadder
        let nearest = ladder.min { abs($0 - bellWeight) < abs($1 - bellWeight) }
        bellWeight = nearest ?? bellWeight
    }

    var canStepBellUp: Bool { bellLadder.contains { $0 > bellWeight } }
    var canStepBellDown: Bool { bellLadder.contains { $0 < bellWeight } }

    func stepBellUp() {
        guard let next = bellLadder.first(where: { $0 > bellWeight }) else { return }
        bellWeight = next
    }

    func stepBellDown() {
        guard let previous = bellLadder.last(where: { $0 < bellWeight }) else { return }
        bellWeight = previous
    }

    // MARK: - Schedule

    /// Weekday offsets from Monday that are training days.
    nonisolated static func trainingOffsets(_ daysPerWeek: Int) -> [Int] {
        switch daysPerWeek {
        case 4: return [0, 1, 3, 4]
        case 5: return [0, 1, 3, 4, 5]
        default: return [0, 2, 4]
        }
    }

    /// Monday used as the rotation anchor so Hunt / Gather never reset on Monday.
    nonisolated private static var anchor: Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date(timeIntervalSince1970: 1_704_067_200)
    }

    /// Day type for a date, following the chosen weekly schedule.
    nonisolated static func dayType(for date: Date, daysPerWeek: Int) -> DayType {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let elapsed = calendar.dateComponents([.day], from: anchor, to: day).day ?? 0
        let offsets = trainingOffsets(daysPerWeek)
        let weekday = ((elapsed % 7) + 7) % 7
        guard let slot = offsets.firstIndex(of: weekday) else { return .feast }
        let week = Int(floor(Double(elapsed) / 7.0))
        let index = week * offsets.count + slot
        return ((index % 2) + 2) % 2 == 0 ? .hunt : .gather
    }

    func dayType(for date: Date) -> DayType {
        Self.dayType(for: date, daysPerWeek: daysPerWeek)
    }

    var todayDayType: DayType { dayType(for: Date()) }

    /// The next training day after today, used for the rest-day nudge.
    var nextTrainingDay: (date: Date, type: DayType)? {
        let calendar = Calendar.current
        for offset in 1...8 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let type = dayType(for: date)
            if type != .feast { return (date, type) }
        }
        return nil
    }

    // MARK: - Weight display

    func weightValue(_ kilograms: Int) -> Int {
        weightUnit == .kg ? kilograms : Int((Double(kilograms) * 2.20462).rounded())
    }

    func weightText(_ kilograms: Int) -> String {
        "\(weightValue(kilograms)) \(weightUnit.label)"
    }

    var bellText: String { weightText(bellWeight) }

    // MARK: - Derived stats

    var trainedDays: Set<Date> {
        let calendar = Calendar.current
        return Set(sessions.map { calendar.startOfDay(for: $0.date) })
    }

    func didTrain(on date: Date) -> Bool {
        trainedDays.contains(Calendar.current.startOfDay(for: date))
    }

    var didTrainToday: Bool { didTrain(on: Date()) }

    /// Work days kept in a row. Rest days are skipped, never counted against the hooman.
    var streak: Int {
        let calendar = Calendar.current
        let days = trainedDays
        var cursor = calendar.startOfDay(for: Date())
        var count = 0

        // Today is still open: if unlogged, start judging from yesterday.
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }

        for _ in 0..<400 {
            if dayType(for: cursor) == .feast {
                // Rest day: neither breaks nor builds the streak.
            } else if days.contains(cursor) {
                count += 1
            } else {
                break
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let days = trainedDays
        guard let earliest = days.min() else { return 0 }
        var cursor = calendar.startOfDay(for: Date())
        var best = 0
        var run = 0

        while cursor >= earliest {
            if dayType(for: cursor) == .feast {
                // Skip.
            } else if days.contains(cursor) {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return max(best, streak)
    }

    /// Monday-first week containing today.
    private var weekStart: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: Date())
        let interval = calendar.dateInterval(of: .weekOfYear, for: today)
        return interval?.start ?? today
    }

    /// Work done on scheduled work days this week. Rest-day loose work is a bonus,
    /// never counted against the week target.
    var workThisWeek: Int {
        let calendar = Calendar.current
        let start = weekStart
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else { return 0 }
        return trainedDays.filter { $0 >= start && $0 < end && dayType(for: $0) != .feast }.count
    }

    var weekTarget: Int { daysPerWeek }

    var weekProgress: Double {
        min(Double(workThisWeek) / Double(max(weekTarget, 1)), 1)
    }

    var sessionsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return trainedDays.filter {
            calendar.isDate($0, equalTo: now, toGranularity: .month)
        }.count
    }

    var totalSessions: Int { sessions.count }

    var heaviestBell: Int {
        sessions.map(\.bellWeight).max() ?? bellWeight
    }

    var mostRounds: Int {
        sessions.map(\.rounds).max() ?? rounds
    }

    var recentSessions: [SessionLog] {
        sessions.sorted { $0.date > $1.date }
    }

    // MARK: - Gentle progression

    /// True when recent work on this bell felt easy and a heavier bell is owned.
    var shouldSuggestHeavierBell: Bool {
        guard canStepBellUp, dismissedBellNudge != bellWeight else { return false }
        let recent = recentSessions.prefix(3)
        guard recent.count == 3 else { return false }
        return recent.allSatisfy { $0.feel == SessionFeel.easy.rawValue && $0.bellWeight == bellWeight }
    }

    var nextBellUp: Int? { bellLadder.first { $0 > bellWeight } }

    func acceptHeavierBell() {
        stepBellUp()
        dismissedBellNudge = 0
    }

    func dismissBellNudge() {
        dismissedBellNudge = bellWeight
    }

    // MARK: - Cave wall

    /// Day cells ending today, oldest first.
    func caveWallDays(count: Int = 68) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<count).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }

    // MARK: - Resume

    func saveProgress(
        session: ActiveSession,
        round: Int,
        movementIndex: Int,
        elapsedSeconds: Int
    ) {
        let snapshot = WorkSnapshot(
            dayType: session.dayType,
            movementIDs: session.movements.map(\.id),
            rounds: session.rounds,
            restSeconds: session.restSeconds,
            round: round,
            movementIndex: movementIndex,
            elapsedSeconds: elapsedSeconds,
            savedAt: Date()
        )
        unfinishedWork = snapshot
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Key.resume)
    }

    func clearProgress() {
        unfinishedWork = nil
        defaults.removeObject(forKey: Key.resume)
    }

    // MARK: - Logging

    /// Writes one finished work to the wall.
    ///
    /// Keyed on the work's own id, so the same finished work can never land twice
    /// however many times done is tapped or the summary is revisited. Returns true
    /// only when this call actually wrote the work.
    @discardableResult
    func log(
        sessionID: UUID,
        dayType: DayType,
        movements: [Movement],
        rounds: Int,
        duration: Int,
        feel: SessionFeel
    ) -> Bool {
        guard !loggedWorkIDs.contains(sessionID.uuidString) else { return false }
        rememberLogged(sessionID)

        let worksBefore = workCount
        let entry = SessionLog(
            date: Date(),
            dayType: dayType,
            movementNames: movements.map(\.name),
            rounds: rounds,
            bellWeight: bellWeight,
            durationSeconds: duration,
            feel: feel.rawValue
        )
        sessions.append(entry)
        clearProgress()

        let climbed = OogoRankBook.rank(forWorks: workCount)
        let stood = OogoRankBook.rank(forWorks: worksBefore)
        if let climbed, climbed.index != stood?.index {
            setRankNote(climbed.display)
        } else {
            setRankNote(nil)
        }
        refreshNudges()
        return true
    }

    /// Remembers a logged work id, keeping only the recent tail so defaults stay small.
    private func rememberLogged(_ sessionID: UUID) {
        loggedWorkIDs.append(sessionID.uuidString)
        let cap = 60
        if loggedWorkIDs.count > cap {
            loggedWorkIDs.removeFirst(loggedWorkIDs.count - cap)
        }
        defaults.set(loggedWorkIDs, forKey: Key.loggedWorks)
    }

    func clearHistory() {
        sessions = []
        setRankNote(nil)
        refreshNudges()
    }

    /// Burns this phone back to first run: wall, plan, kit, membership, all of it.
    /// Used when the hooman deletes their account — nothing survives.
    func wipeEverything() {
        sessions = []
        setRankNote(nil)
        clearProgress()

        rounds = 3
        bellWeight = 24
        restSeconds = 45
        daysPerWeek = 3
        weightUnit = .kg
        isMember = false
        hoomanName = "hooman"
        remindersOn = true
        nudgeHour = 7
        nudgeMinute = 0
        hasOnboarded = false
        hasCommitted = false
        hasAdoptedCloudPlan = false

        ownedBells = [16, 24]
        defaults.set([16, 24], forKey: Key.ownedBells)

        gear = [.oneBell]
        persistGear()

        goals = []
        defaults.set([String](), forKey: Key.goals)

        selections = [:]
        defaults.set([String: String](), forKey: Key.selections)

        repOverrides = [:]
        defaults.set([String: Int](), forKey: Key.repOverrides)

        dismissedBellNudge = 0

        loggedWorkIDs = []
        defaults.removeObject(forKey: Key.loggedWorks)

        // A fresh cave starts counting rank from today, and never re-seeds
        // the painted starting history.
        let now = Date()
        memberSince = now
        defaults.set(now, forKey: Key.since)
        defaults.set(true, forKey: Key.seeded)

        refreshNudges()
    }

    private func setRankNote(_ value: String?) {
        rankNote = value
        if let value {
            defaults.set(value, forKey: Key.rankNote)
        } else {
            defaults.removeObject(forKey: Key.rankNote)
        }
    }

    // MARK: - Work ranks

    /// Every work hooman finish counts, rest-day loose work too.
    /// Painted starting history counts for nothing.
    var workCount: Int {
        let floorDate = Calendar.current.startOfDay(for: memberSince)
        return sessions.filter { entry in
            entry.isSeed != true && entry.date >= floorDate
        }.count
    }

    var rank: OogoRank? { OogoRankBook.rank(forWorks: workCount) }

    var nextRank: OogoRank? { OogoRankBook.next(afterWorks: workCount) }

    var rankProgress: Double { OogoRankBook.progress(works: workCount) }

    var worksToNextRank: Int? { OogoRankBook.worksToNext(fromWorks: workCount) }

    /// Line under the rank on the hooman page.
    var rankDetail: String {
        guard rank != nil else { return "one work make hooman youngblood." }
        guard let left = worksToNextRank, let next = nextRank else { return "top of ladder. no hooman higher." }
        return left == 1 ? "1 work to \(next.display)." : "\(left) work to \(next.display)."
    }

    // MARK: - Nudge

    /// Chosen shout time, as a date today for the picker.
    var nudgeTime: Date {
        get {
            Calendar.current.date(
                bySettingHour: nudgeHour,
                minute: nudgeMinute,
                second: 0,
                of: Date()
            ) ?? Date()
        }
        set {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            nudgeMinute = parts.minute ?? 0
            nudgeHour = parts.hour ?? 7
        }
    }

    var nudgeTimeText: String {
        nudgeTime.formatted(.dateTime.hour().minute())
    }

    /// When oog will next open his mouth, skipping rest days and finished work.
    var nextNudge: Date? {
        guard remindersOn else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()
        for offset in 0..<21 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            guard dayType(for: day) != .feast, !didTrain(on: day) else { continue }
            guard let fire = calendar.date(bySettingHour: nudgeHour, minute: nudgeMinute, second: 0, of: day),
                  fire > now else { continue }
            return fire
        }
        return nil
    }

    /// Rebuilds oog's queue of grunts. Safe to call often.
    func refreshNudges() {
        let isOn = remindersOn
        let hour = nudgeHour
        let minute = nudgeMinute
        let days = daysPerWeek
        let name = hoomanName
        let trained = trainedDays
        Task {
            await NudgeService.reschedule(
                isOn: isOn,
                hour: hour,
                minute: minute,
                daysPerWeek: days,
                hoomanName: name,
                trainedDays: trained
            )
        }
    }

    private func persistSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        defaults.set(data, forKey: Key.sessions)
    }

    // MARK: - Cloud

    /// Folds cloud work into the wall. Union by id, so nothing is ever lost
    /// and a session synced twice still counts once.
    /// Returns the work that only exists on this phone and still needs pushing.
    @discardableResult
    func mergeRemoteSessions(_ remote: [SessionLog]) -> [SessionLog] {
        let localIDs = Set(sessions.map(\.id))
        let remoteIDs = Set(remote.map(\.id))

        let incoming = remote.filter { !localIDs.contains($0.id) }
        if !incoming.isEmpty {
            sessions = (sessions + incoming).sorted { $0.date < $1.date }
        }

        return sessions.filter { !remoteIDs.contains($0.id) }
    }

    /// Takes the cloud's plan as truth. Used when a known hooman signs in on a new phone.
    func applyRemotePlan(
        hoomanName: String?,
        rounds: Int,
        bellWeight: Int,
        restSeconds: Int,
        daysPerWeek: Int,
        weightUnit: String,
        ownedBells: [Int],
        gear: [String],
        goals: [String],
        selections: [String: String],
        repOverrides: [String: Int],
        remindersOn: Bool,
        nudgeHour: Int,
        nudgeMinute: Int,
        hasCommitted: Bool
    ) {
        if let hoomanName, !hoomanName.isEmpty { self.hoomanName = hoomanName }
        self.rounds = rounds
        self.restSeconds = restSeconds
        self.daysPerWeek = daysPerWeek
        self.weightUnit = WeightUnit(rawValue: weightUnit) ?? self.weightUnit

        var restoredGear = Set(gear.compactMap { OogoGear(rawValue: $0) })
        restoredGear.insert(.oneBell)
        self.gear = restoredGear
        persistGear()

        self.goals = goals.compactMap { OogoGoal(rawValue: $0) }
        defaults.set(self.goals.map(\.rawValue), forKey: Key.goals)

        if !ownedBells.isEmpty {
            self.ownedBells = Set(ownedBells)
            defaults.set(ownedBells.sorted(), forKey: Key.ownedBells)
        }

        var restoredSelections: [MovementPattern: String] = [:]
        for (key, value) in selections {
            if let pattern = MovementPattern(rawValue: key) { restoredSelections[pattern] = value }
        }
        self.selections = restoredSelections
        defaults.set(selections, forKey: Key.selections)

        self.repOverrides = repOverrides
        defaults.set(repOverrides, forKey: Key.repOverrides)

        self.nudgeHour = nudgeHour
        self.nudgeMinute = nudgeMinute
        self.remindersOn = remindersOn
        if hasCommitted { self.hasCommitted = true }

        // Bell last: it has to land on a size the hooman actually owns.
        self.bellWeight = bellWeight
        snapBellToOwned()
        dropUnreachableSelections()
    }

    /// Marks this phone as owner of its plan. Called once the sky has either
    /// handed oog a plan to take, or accepted the plan this phone carried up.
    func markCloudPlanAdopted() {
        guard !hasAdoptedCloudPlan else { return }
        hasAdoptedCloudPlan = true
    }

    /// Cloud says the hooman paid. Never downgrades a local membership.
    func adoptMembership(isMember: Bool) {
        guard isMember else { return }
        self.isMember = true
    }

    /// Everything worth keeping about how this hooman trains.
    var planFields: (
        name: String,
        rounds: Int,
        bell: Int,
        rest: Int,
        days: Int,
        unit: String,
        bells: [Int],
        gear: [String],
        goals: [String],
        selections: [String: String],
        reps: [String: Int],
        reminders: Bool,
        hour: Int,
        minute: Int,
        committed: Bool
    ) {
        (
            hoomanName,
            rounds,
            bellWeight,
            restSeconds,
            daysPerWeek,
            weightUnit.rawValue,
            ownedBells.sorted(),
            gear.map(\.rawValue).sorted(),
            goals.map(\.rawValue),
            selections.reduce(into: [String: String]()) { $0[$1.key.rawValue] = $1.value },
            repOverrides,
            remindersOn,
            nudgeHour,
            nudgeMinute,
            hasCommitted
        )
    }

    // MARK: - Seed

    /// Builds a believable starting history so the cave wall has texture on day one.
    nonisolated private static func seedHistory(daysPerWeek: Int) -> [SessionLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (1...60).compactMap { offset -> SessionLog? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let type = dayType(for: date, daysPerWeek: daysPerWeek)
            guard type != .feast, offset % 7 != 3 else { return nil }
            let stamped = calendar.date(byAdding: .hour, value: 8, to: date) ?? date
            let names = type.patterns.map { MovementLibrary.first(for: $0).name }
            return SessionLog(
                date: stamped,
                dayType: type,
                movementNames: names,
                rounds: 3 + (offset % 3),
                bellWeight: offset % 5 == 0 ? 24 : 16,
                durationSeconds: 1600 + (offset % 6) * 90,
                feel: [SessionFeel.good, .hard, .easy][offset % 3].rawValue,
                isSeed: true
            )
        }
    }
}
