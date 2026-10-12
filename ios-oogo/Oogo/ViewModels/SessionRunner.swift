//
//  SessionRunner.swift
//  Oogo
//
//  Drives live work: rounds, movements, rest countdown, elapsed time.
//

import Foundation
import Observation

@Observable
final class SessionRunner {
    let session: ActiveSession

    var round: Int
    var movementIndex: Int
    var elapsedSeconds: Int
    var restRemaining: Int = 0
    var isResting: Bool = false
    var isPaused: Bool = false
    var isFinished: Bool = false

    init(session: ActiveSession) {
        self.session = session
        round = min(max(session.startRound, 1), max(session.rounds, 1))
        movementIndex = min(max(session.startMovementIndex, 0), max(session.movements.count - 1, 0))
        elapsedSeconds = max(session.startElapsed, 0)
    }

    var movements: [Movement] { session.movements }

    var currentMovement: Movement {
        movements[min(movementIndex, max(movements.count - 1, 0))]
    }

    /// The movement that comes after the current one, wrapping into the next round.
    var nextMovement: Movement? {
        guard !movements.isEmpty else { return nil }
        if movementIndex + 1 < movements.count { return movements[movementIndex + 1] }
        return round < session.rounds ? movements[0] : nil
    }

    var totalUnits: Int { max(session.rounds * movements.count, 1) }

    var completedUnits: Int { (round - 1) * movements.count + movementIndex }

    var progress: Double {
        min(Double(completedUnits) / Double(totalUnits), 1)
    }

    /// Rest time left as a fraction, used by the countdown ring.
    var restProgress: Double {
        guard session.restSeconds > 0 else { return 0 }
        return Double(restRemaining) / Double(session.restSeconds)
    }

    var elapsedText: String { Self.timeText(elapsedSeconds) }

    var restText: String { Self.timeText(restRemaining) }

    var plannedRestText: String { Self.timeText(session.restSeconds) }

    nonisolated static func timeText(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    nonisolated static func minutesText(_ seconds: Int) -> String {
        "\(max(seconds / 60, 1)) min"
    }

    func tick() {
        guard !isPaused, !isFinished else { return }
        elapsedSeconds += 1
        guard isResting else { return }
        restRemaining -= 1
        // Rising taps as rest drains away.
        if restRemaining > 0, restRemaining <= 3 {
            Haptic.soft(intensity: 1.0 - (Double(restRemaining) * 0.2))
        }
        if restRemaining <= 0 {
            endRest()
        }
    }

    /// Rolls the clock forward after the app was away, so time never freezes in pocket.
    func catchUp(by seconds: Int) {
        guard seconds > 0, !isPaused, !isFinished else { return }
        elapsedSeconds += seconds
        guard isResting else { return }
        restRemaining -= seconds
        if restRemaining <= 0 { endRest() }
    }

    /// Marks current movement done and moves work forward.
    func advance() {
        guard !isFinished else { return }
        if isResting {
            endRest()
            return
        }
        if movementIndex + 1 < movements.count {
            movementIndex += 1
            Haptic.tap()
            return
        }
        movementIndex = 0
        if round >= session.rounds {
            finish()
        } else {
            startRest()
        }
    }

    /// Steps one movement back, crossing into the previous round when needed.
    func goBack() {
        guard !isFinished else { return }
        if isResting {
            isResting = false
            restRemaining = 0
            movementIndex = max(movements.count - 1, 0)
            Haptic.tick()
            return
        }
        if movementIndex > 0 {
            movementIndex -= 1
        } else if round > 1 {
            round -= 1
            movementIndex = max(movements.count - 1, 0)
        }
        Haptic.tick()
    }

    var canGoBack: Bool { isResting || movementIndex > 0 || round > 1 }

    func startRest() {
        guard session.restSeconds > 0 else {
            round = min(round + 1, session.rounds)
            return
        }
        isResting = true
        restRemaining = session.restSeconds
        // Round landed and rest opens: one medium click, never two.
        Haptic.firm()
    }

    func endRest() {
        isResting = false
        restRemaining = 0
        round = min(round + 1, session.rounds)
        Haptic.firm()
    }

    func togglePause() {
        isPaused.toggle()
        Haptic.tap()
    }

    func finish() {
        isFinished = true
        Haptic.done()
    }

    /// Rounds actually completed, used when work ends early.
    var completedRounds: Int {
        if isFinished && movementIndex == 0 && !isResting { return round }
        return max(round - 1, 0)
    }
}
