//
//  SessionFlowView.swift
//  Oogo
//
//  Live work runner, then work-done summary.
//

import Combine
import SwiftUI
import UIKit

struct SessionFlowView: View {
    let session: ActiveSession

    @Environment(OogoStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Environment(\.scenePhase) private var scenePhase

    @State private var runner: SessionRunner
    @State private var showSummary: Bool = false
    /// When the app went away mid-work, so the clock can catch up on return.
    @State private var leftAt: Date?

    init(session: ActiveSession) {
        self.session = session
        _runner = State(initialValue: SessionRunner(session: session))
    }

    var body: some View {
        ZStack {
            OogoColor.page.ignoresSafeArea()

            if showSummary {
                WorkDoneView(
                    session: session,
                    rounds: max(runner.completedRounds, 1),
                    duration: runner.elapsedSeconds,
                    onDone: { dismiss() }
                )
                .transition(.opacity)
            } else {
                SessionRunnerView(runner: runner, onQuit: {
                    store.clearProgress()
                    dismiss()
                })
                .transition(.opacity)
            }
        }
        .animation(OogoMotion.soft, value: showSummary)
        .onChange(of: runner.isFinished) { _, finished in
            guard finished else { return }
            showSummary = true
        }
        .onChange(of: runner.movementIndex) { _, _ in saveProgress() }
        .onChange(of: runner.round) { _, _ in saveProgress() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                guard let leftAt else { return }
                runner.catchUp(by: Int(Date().timeIntervalSince(leftAt).rounded()))
                self.leftAt = nil
            case .inactive, .background:
                guard leftAt == nil, !runner.isFinished else { return }
                leftAt = Date()
                saveProgress()
            @unknown default:
                break
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            saveProgress()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    /// Keeps a resume point so interrupted work can be picked up from camp.
    private func saveProgress() {
        guard !runner.isFinished else { return }
        store.saveProgress(
            session: session,
            round: runner.round,
            movementIndex: runner.movementIndex,
            elapsedSeconds: runner.elapsedSeconds
        )
    }
}

// MARK: - Runner

struct SessionRunnerView: View {
    let runner: SessionRunner
    let onQuit: () -> Void

    @Environment(OogoStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmEnd: Bool = false
    @State private var showCues: Bool = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// Height of the button stack the cue card must float clear of.
    private let cueLift: CGFloat = 232

    private var isShowingCues: Bool { showCues && !runner.isResting }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            roundHeader

            Spacer(minLength: 8)

            if runner.isResting {
                restBlock
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                movementBlock
                    .layoutPriority(1)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            Spacer(minLength: 8)

            // The runner picks its own weight here: tap, round-landed click, or the finish thud.
            OogoPrimaryButton(title: runner.isResting ? "skip rest" : "done", firesHaptic: false) {
                withAnimation(OogoMotion.snap) { runner.advance() }
            }
            .padding(.horizontal, 28)

            statusPill
                .padding(.top, 14)

            controls
                .padding(.top, 22)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OogoColor.page)
        .overlay(alignment: .bottom) {
            if isShowingCues {
                FormCueCard(movement: runner.currentMovement)
                    .padding(.horizontal, OogoMetric.margin)
                    .padding(.bottom, cueLift)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .move(edge: .bottom).combined(with: .opacity)
                    )
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : OogoMotion.soft, value: isShowingCues)
        .animation(OogoMotion.snap, value: runner.isResting)
        .animation(OogoMotion.snap, value: runner.movementIndex)
        .animation(OogoMotion.snap, value: runner.round)
        .onReceive(ticker) { _ in
            runner.tick()
        }
        .alert("end work?", isPresented: $confirmEnd) {
            Button("keep go", role: .cancel) {}
            Button("end", role: .destructive) {
                if runner.completedRounds > 0 {
                    runner.finish()
                } else {
                    onQuit()
                }
            }
        } message: {
            Text(runner.completedRounds > 0 ? "oog keep \(runner.completedRounds) round." : "nothing save yet.")
        }
    }

    // MARK: Header

    private var roundHeader: some View {
        VStack(spacing: 13) {
            HStack(spacing: 8) {
                ForEach(0..<runner.session.rounds, id: \.self) { index in
                    Circle()
                        .fill(dotColor(index))
                        .frame(width: 7, height: 7)
                        .scaleEffect(index == runner.round - 1 ? 1.3 : 1)
                        .animation(OogoMotion.pop, value: runner.round)
                }
            }

            HStack(spacing: 6) {
                TinyLabel(text: "round", size: 12)
                Text("\(runner.round)")
                    .font(OogoFont.semibold(12.5))
                    .monospacedDigit()
                    .tracking(1.4)
                    .foregroundStyle(OogoColor.ink)
                    .contentTransition(.numericText())
                Text("/ \(runner.session.rounds)")
                    .font(OogoFont.regular(12.5))
                    .monospacedDigit()
                    .tracking(1.4)
                    .foregroundStyle(OogoColor.secondaryText)
            }
        }
    }

    private func dotColor(_ index: Int) -> Color {
        if index == runner.round - 1 { return OogoColor.red }
        return index < runner.round - 1 ? OogoColor.ink : OogoColor.mist
    }

    // MARK: Movement

    private var movementBlock: some View {
        VStack(spacing: 0) {
            // Oog shows the move. Takes whatever height the screen can spare, up to a point.
            OogAnimationView(movement: runner.currentMovement, isPaused: runner.isPaused)
                .frame(maxWidth: 300, maxHeight: 300)
                .frame(minHeight: 120)
                .id(runner.currentMovement.id)
                .transition(.opacity)
                .padding(.bottom, 10)

            TinyLabel(text: runner.currentMovement.pattern.label, size: 12)

            Text(runner.currentMovement.name)
                .font(OogoFont.heavy(42))
                .oogoTracking(42)
                .foregroundStyle(OogoColor.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.55)
                .padding(.top, 14)
                .padding(.horizontal, 24)
                .id(runner.currentMovement.id)

            HStack(spacing: 10) {
                if runner.currentMovement.usesBell {
                    OogoValuePill(
                        value: "\(store.weightValue(store.bellWeight))",
                        unit: store.weightUnit.label.uppercased()
                    )
                }
                OogoValuePill(value: runner.currentMovement.reps, unit: runner.currentMovement.repsLabel)
            }
            .padding(.top, 20)

            Text(nextLine)
                .font(OogoFont.regular(15))
                .foregroundStyle(OogoColor.secondaryText)
                .padding(.top, 22)
                .contentTransition(.opacity)
                .opacity(isShowingCues ? 0 : 1)
        }
    }

    private var nextLine: String {
        if let next = runner.nextMovement { return "next: \(next.name.lowercased())" }
        return runner.round == runner.session.rounds ? "last round. give all." : "last move. finish strong."
    }

    // MARK: Rest

    private var restBlock: some View {
        VStack(spacing: 0) {
            TinyLabel(text: "rest", size: 12)

            ZStack {
                OogoRing(progress: runner.restProgress, lineWidth: 4, color: OogoColor.red)
                    .frame(width: 208, height: 208)
                VStack(spacing: 2) {
                    Text(runner.restText)
                        .font(OogoFont.timer(58))
                        .oogoTracking(58)
                        .foregroundStyle(OogoColor.ink)
                        .contentTransition(.numericText(countsDown: true))
                    Text("breathe. oog wait.")
                        .font(OogoFont.caption)
                        .foregroundStyle(OogoColor.secondaryText)
                }
            }
            .padding(.top, 18)

            Text("round \(min(runner.round + 1, runner.session.rounds)) come.")
                .font(OogoFont.regular(15))
                .monospacedDigit()
                .foregroundStyle(OogoColor.secondaryText)
                .padding(.top, 18)
        }
    }

    private var statusPill: some View {
        Group {
            if runner.isPaused {
                OogoMetaPill(text: "paused", systemImage: "pause.fill", isDark: true)
            } else {
                HStack(spacing: 7) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 13, weight: .medium))
                    Text(runner.elapsedText)
                        .font(OogoFont.medium(15))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .foregroundStyle(OogoColor.secondaryText)
                .padding(.horizontal, 18)
                .frame(height: 38)
                .background { Capsule().fill(OogoColor.cloud) }
            }
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 16) {
            OogoCircleButton(
                systemImage: "arrow.left",
                caption: "back",
                isEnabled: runner.canGoBack,
                firesHaptic: false
            ) {
                withAnimation(OogoMotion.snap) { runner.goBack() }
            }

            OogoCircleButton(
                systemImage: runner.isPaused ? "play.fill" : "pause.fill",
                caption: runner.isPaused ? "resume" : "pause",
                firesHaptic: false
            ) {
                runner.togglePause()
            }

            OogoCircleButton(
                systemImage: isShowingCues ? "book.closed.fill" : "book.closed",
                caption: "how",
                tint: isShowingCues ? OogoColor.red : OogoColor.ink,
                isEnabled: !runner.isResting
            ) {
                showCues.toggle()
            }

            OogoCircleButton(
                systemImage: "stop.fill",
                caption: "end",
                iconSize: 15,
                tint: OogoColor.red
            ) {
                confirmEnd = true
            }
        }
    }
}

// MARK: - Form cues

/// Quiet paper card: how to set up, brace, breathe, and how slow to move.
private struct FormCueCard: View {
    let movement: Movement

    private var cues: MovementCues { MovementCueBook.cues(for: movement) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                TinyLabel(text: "how oog do it", size: 12)
                Spacer(minLength: 8)
                Text(movement.name.lowercased())
                    .font(OogoFont.regular(12.5))
                    .foregroundStyle(OogoColor.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.bottom, 13)

            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(cues.lines.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(line.label)
                            .font(OogoFont.semibold(10.5))
                            .tracking(0.9)
                            .textCase(.uppercase)
                            .foregroundStyle(OogoColor.secondaryText)
                            .frame(width: 48, alignment: .leading)
                        Text(line.text)
                            .font(OogoFont.medium(15))
                            .foregroundStyle(OogoColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }

            Rectangle()
                .fill(OogoColor.mist)
                .frame(height: 1)
                .padding(.vertical, 13)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                RedDot(size: 5)
                Text(cues.tempo)
                    .font(OogoFont.medium(14.5))
                    .foregroundStyle(OogoColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
        .id(movement.id)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Work done

struct WorkDoneView: View {
    let session: ActiveSession
    let rounds: Int
    let duration: Int
    let onDone: () -> Void

    @Environment(OogoStore.self) private var store
    @Environment(OogoSync.self) private var sync
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feel: SessionFeel = .good
    @State private var appeared: Bool = false
    @State private var bloom: Bool = false
    @State private var showShare: Bool = false
    @State private var rolledCount: Int = 0
    /// Latches on the first done tap so a fast second tap never reaches the store.
    @State private var hasLogged: Bool = false

    /// Work on the wall before this one is logged.
    private var worksBefore: Int { store.workCount }

    /// Work on the wall once this one lands. Every finished work counts.
    private var worksAfter: Int { worksBefore + 1 }

    /// Rank this work hands over, when it crosses a line.
    private var climbedRank: OogoRank? {
        let after = OogoRankBook.rank(forWorks: worksAfter)
        let before = OogoRankBook.rank(forWorks: worksBefore)
        guard let after, after.index != before?.index else { return nil }
        return after
    }

    private var posterData: WorkPosterData {
        WorkPosterData.make(
            dayType: session.dayType,
            date: Date(),
            rankName: (climbedRank ?? OogoRankBook.rank(forWorks: worksAfter))?.display,
            rounds: rounds,
            durationSeconds: duration,
            bellText: store.bellText,
            moves: session.movements.map(\.name),
            feel: feel.rawValue
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: OogoMetric.cardGap) {
                Group {
                    if let climbedRank {
                        rankUpHeadline(climbedRank)
                    } else {
                        headline
                    }
                }
                .padding(.top, 46)
                .padding(.bottom, 12)

                statRow
                    .oogoEntrance(appeared, index: 1)

                movementsCard
                    .oogoEntrance(appeared, index: 2)

                feelCard
                    .oogoEntrance(appeared, index: 3)

                HStack(spacing: 11) {
                    OogoPrimaryButton(title: "done") {
                        if !hasLogged {
                            hasLogged = true
                            let wrote = store.log(
                                sessionID: session.id,
                                dayType: session.dayType,
                                movements: session.movements,
                                rounds: rounds,
                                duration: duration,
                                feel: feel
                            )
                            // Send it up straight away so the wall is current on every phone.
                            if wrote {
                                Task { await sync.pushWork() }
                            }
                        }
                        onDone()
                    }

                    Button {
                        Haptic.tap()
                        showShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(OogoColor.ink)
                            .frame(width: OogoMetric.buttonHeight, height: OogoMetric.buttonHeight)
                            .background {
                                Circle()
                                    .fill(OogoColor.paper)
                                    .overlay { Circle().strokeBorder(OogoColor.mist, lineWidth: 1.2) }
                            }
                            .contentShape(.circle)
                    }
                    .buttonStyle(OogoPressStyle(scale: 0.9))
                    .accessibilityLabel("share work")
                }
                .padding(.top, 6)
                .oogoEntrance(appeared, index: 4)
            }
            .padding(.horizontal, OogoMetric.margin)
            .padding(.bottom, 34)
        }
        .background(OogoColor.page)
        .sheet(isPresented: $showShare) {
            WorkPosterSheet(data: posterData)
        }
        .onAppear {
            withAnimation(OogoMotion.pop.delay(0.05)) { appeared = true }
            if !reduceMotion {
                withAnimation(.easeOut(duration: 1.1).delay(0.1)) { bloom = true }
            }
            guard climbedRank != nil else { return }
            climbHaptics()
        }
    }

    /// Rank takes the headline when work crosses a line.
    private func rankUpHeadline(_ rank: OogoRank) -> some View {
        VStack(spacing: 4) {
            if let old = OogoRankBook.rank(forWorks: worksBefore) {
                Text(old.display)
                    .font(OogoFont.medium(15))
                    .foregroundStyle(OogoColor.secondaryText)
                    .strikethrough(true, color: OogoColor.secondaryText)
            } else {
                TinyLabel(text: "first work")
            }

            Text(rank.display)
                .font(OogoFont.heavy(44))
                .oogoTracking(44)
                .foregroundStyle(OogoColor.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)

            Text(OogoRankBook.praise(for: rank))
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            Text("\(worksAfter) work on wall.")
                .font(OogoFont.caption)
                .monospacedDigit()
                .foregroundStyle(OogoColor.secondaryText)
                .padding(.top, 6)
        }
        .background {
            Circle()
                .fill(OogoColor.red.opacity(reduceMotion || bloom ? 0 : 0.2))
                .frame(width: 130, height: 130)
                .scaleEffect(bloom ? 3.6 : 0.2)
                .blur(radius: 14)
                .allowsHitTesting(false)
        }
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
    }

    /// Three rising taps to mark the climb, ending on the heaviest hit.
    private func climbHaptics() {
        Haptic.prime()
        Haptic.soft(intensity: 0.45)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { Haptic.soft(intensity: 0.75) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { Haptic.done() }
    }

    /// One red spark expands behind the words, then holds still.
    private var headline: some View {
        VStack(spacing: 2) {
            Text("\(session.dayType.shortName.lowercased()) done.")
                .font(OogoFont.heavy(42))
                .oogoTracking(42)
                .foregroundStyle(OogoColor.ink)
            Text("oog proud, \(store.hoomanName).")
                .font(OogoFont.heavy(28))
                .oogoTracking(28)
                .foregroundStyle(OogoColor.secondaryText)
        }
        .background {
            Circle()
                .fill(OogoColor.red.opacity(reduceMotion || bloom ? 0 : 0.16))
                .frame(width: 120, height: 120)
                .scaleEffect(bloom ? 3.4 : 0.2)
                .blur(radius: 12)
                .allowsHitTesting(false)
        }
        .scaleEffect(appeared ? 1 : 0.94)
        .opacity(appeared ? 1 : 0)
    }

    /// Three numbers, each rolling up from nothing one after the other.
    private var statRow: some View {
        HStack(spacing: 11) {
            summaryTile(
                symbol: "figure.strengthtraining.functional",
                value: "\(rolledCount > 0 ? rounds : 0)",
                label: "round"
            )
            summaryTile(
                symbol: "stopwatch",
                value: rolledCount > 1 ? SessionRunner.timeText(duration) : SessionRunner.timeText(0),
                label: "time"
            )
            summaryTile(
                symbol: "scalemass",
                value: "\(rolledCount > 2 ? store.weightValue(store.bellWeight) : 0)",
                label: store.weightUnit.label
            )
        }
        .task {
            guard rolledCount == 0 else { return }
            for _ in 0..<3 {
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 40 : 150))
                rolledCount += 1
            }
        }
    }

    private func summaryTile(symbol: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(OogoColor.ink)
            Text(value)
                .font(OogoFont.number(23))
                .foregroundStyle(OogoColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText(countsDown: false))
                .animation(reduceMotion ? .easeOut(duration: 0.2) : OogoMotion.snap, value: value)
            Text(label)
                .font(OogoFont.caption)
                .foregroundStyle(OogoColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .oogoCard(radius: OogoRadius.smallCard)
    }

    private var movementsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TinyLabel(text: "move done")
                .padding(.bottom, 6)

            ForEach(Array(session.movements.enumerated()), id: \.element) { index, movement in
                HStack(spacing: 14) {
                    Text(movement.name)
                        .font(OogoFont.bold(18))
                        .foregroundStyle(OogoColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    Text("\(rounds)×\(movement.reps)")
                        .font(OogoFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(OogoColor.secondaryText)
                }
                .padding(.vertical, 12)

                if index < session.movements.count - 1 {
                    Rectangle()
                        .fill(OogoColor.mist)
                        .frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    private var feelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TinyLabel(text: "how feel?")
            HStack(spacing: 7) {
                ForEach(SessionFeel.allCases) { option in
                    Button {
                        Haptic.select()
                        withAnimation(OogoMotion.snap) { feel = option }
                    } label: {
                        Text(option.rawValue)
                            .font(OogoFont.semibold(15))
                            .foregroundStyle(feel == option ? Color.white : OogoColor.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(feel == option ? OogoColor.ink : OogoColor.cloud)
                            }
                            .contentShape(.capsule)
                    }
                    .buttonStyle(OogoPressStyle(scale: 0.93))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }
}

// MARK: - Log sheet

struct SessionLogSheet: View {
    @Environment(OogoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var shared: SessionLog?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    TinyLabel(text: "history")
                    Text("all work")
                        .font(OogoFont.heavy(28))
                        .oogoTracking(28)
                        .foregroundStyle(OogoColor.ink)
                }
                Spacer()
                OogoCloseButton { dismiss() }
            }
            .padding(.horizontal, OogoMetric.margin)
            .padding(.top, 22)
            .padding(.bottom, 16)

            if store.recentSessions.isEmpty {
                VStack(spacing: 5) {
                    Text("no work yet.")
                        .font(OogoFont.bold(20))
                        .foregroundStyle(OogoColor.ink)
                    Text("wall empty. go fix.")
                        .font(OogoFont.caption)
                        .foregroundStyle(OogoColor.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 9) {
                        ForEach(store.recentSessions) { entry in
                            Button {
                                Haptic.tap()
                                shared = entry
                            } label: {
                                LogRow(entry: entry)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .oogoCard(radius: OogoRadius.smallCard)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(OogoPressStyle(scale: 0.99))
                        }
                    }
                    .padding(.horizontal, OogoMetric.margin)
                    .padding(.bottom, 30)
                }
            }
        }
        .background(OogoColor.page)
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .sheet(item: $shared) { entry in
            WorkPosterSheet(
                data: WorkPosterData.make(
                    dayType: entry.dayType,
                    date: entry.date,
                    rankName: store.rank?.display,
                    rounds: entry.rounds,
                    durationSeconds: entry.durationSeconds,
                    bellText: store.weightText(entry.bellWeight),
                    moves: entry.movementNames,
                    feel: entry.feel
                )
            )
        }
    }
}

/// Date block, day type, duration — used in the log sheet and profile.
struct LogRow: View {
    let entry: SessionLog

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(entry.date.formatted(.dateTime.day()))
                    .font(OogoFont.number(21))
                    .foregroundStyle(OogoColor.ink)
                Text(entry.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(OogoFont.semibold(11))
                    .tracking(0.8)
                    .foregroundStyle(OogoColor.secondaryText)
            }
            .frame(width: 34)

            Rectangle()
                .fill(OogoColor.mist)
                .frame(width: 1, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.dayType.title.lowercased())
                    .font(OogoFont.bold(17))
                    .foregroundStyle(OogoColor.ink)
                Text(entry.movementNames.joined(separator: " · ").lowercased())
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 13, weight: .regular))
                Text(SessionRunner.minutesText(entry.durationSeconds))
                    .font(OogoFont.regular(15))
                    .monospacedDigit()
            }
            .foregroundStyle(OogoColor.secondaryText)

            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(OogoColor.ink.opacity(0.3))
        }
    }
}
