//
//  CommitView.swift
//  Oogo
//
//  One moment, once ever. Hooman holds the stone and says yes.
//

import SwiftUI

/// Where the hold is in its life.
private enum CommitPhase {
    case idle
    case holding
    /// Ring closed, spark blooming.
    case sealed
    case good
    case go
}

/// Flat RGB pair used to blend paper into ink as the hold deepens.
private nonisolated struct InkMix {
    let red: Double
    let green: Double
    let blue: Double

    static let page = InkMix(red: 250 / 255, green: 250 / 255, blue: 249 / 255)
    static let ink = InkMix(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
    static let paper = InkMix(red: 1, green: 1, blue: 1)

    /// Walks from one tone to the other. `amount` runs 0 to 1.
    nonisolated static func blend(_ from: InkMix, _ to: InkMix, _ amount: Double) -> Color {
        let t = max(0, min(amount, 1))
        return Color(
            .sRGB,
            red: from.red + (to.red - from.red) * t,
            green: from.green + (to.green - from.green) * t,
            blue: from.blue + (to.blue - from.blue) * t,
            opacity: 1
        )
    }
}

/// The commitment moment. Paper and ink, one stone, three seconds.
struct CommitView: View {
    let onBack: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: Double = 0
    @State private var phase: CommitPhase = .idle
    @State private var holdTask: Task<Void, Never>?
    @State private var finaleTask: Task<Void, Never>?
    @State private var firedMarks: Set<Int> = []
    @State private var bloom: Bool = false

    /// How long the stone must be held.
    private static let holdSeconds: Double = 3.0
    private static let stoneSize: CGFloat = 218
    private static let ringSize: CGFloat = 242

    /// Points along the hold where oog taps back.
    private static let marks: [Double] = [0.3, 0.55, 0.75, 0.9]

    private var isFinished: Bool { phase == .good || phase == .go }

    /// How far the page has travelled from paper toward ink.
    private var darkness: Double {
        guard !reduceMotion else { return 0 }
        if phase == .sealed || isFinished { return 1 }
        return min(progress / 0.75, 1)
    }

    private var background: Color { InkMix.blend(.page, .ink, darkness) }
    private var primaryText: Color { InkMix.blend(.ink, .paper, darkness) }
    private var quietText: Color { primaryText.opacity(0.55) }
    private var stoneFill: Color { InkMix.blend(.ink, .paper, darkness) }
    private var stoneText: Color { InkMix.blend(.paper, .ink, darkness) }

    /// Copy clears out early, so the hold owns the screen.
    private var copyOpacity: Double {
        max(0, 1 - (progress / 0.28))
    }

    private var holdCaption: String {
        switch phase {
        case .idle: return "hold strong."
        case .holding:
            if progress > 0.75 { return "almost there, hooman." }
            if progress > 0.33 { return "keep holding." }
            return "hold strong."
        default: return ""
        }
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            holdScreen
                .opacity(isFinished ? 0 : 1)

            finale
                .opacity(isFinished ? 1 : 0)
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.28) : OogoMotion.soft, value: phase)
        .overlay(alignment: .topLeading) { backButton }
        .onDisappear {
            holdTask?.cancel()
            finaleTask?.cancel()
        }
    }

    // MARK: - Resting screen

    private var holdScreen: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            headline
                .opacity(copyOpacity)

            Spacer(minLength: 20)

            stone

            Text(holdCaption)
                .font(OogoFont.caption)
                .foregroundStyle(quietText)
                .frame(height: 20)
                .padding(.top, 26)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: holdCaption)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, OogoMetric.margin + 4)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOU READY, HOOMAN?")
                .font(OogoFont.heavy(38))
                .oogoTracking(38)
                .foregroundStyle(primaryText)
                .lineSpacing(-1)
                .fixedSize(horizontal: false, vertical: true)

            Text("you ready to become strongest hooman you can be?")
                .font(OogoFont.subtitle)
                .foregroundStyle(quietText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            VStack(alignment: .leading, spacing: 5) {
                Text("me show up.")
                Text("me choose hard.")
                Text("me keep word.")
            }
            .font(OogoFont.caption)
            .foregroundStyle(quietText)
            .padding(.top, 30)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 40)
    }

    // MARK: - Stone

    private var stone: some View {
        ZStack {
            Circle()
                .fill(stoneFill)
                .frame(width: Self.stoneSize, height: Self.stoneSize)

            Text("HOLD TO COMMIT")
                .font(OogoFont.heavy(16))
                .tracking(1.4)
                .foregroundStyle(stoneText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 26)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(primaryText.opacity(0.9), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: Self.ringSize, height: Self.ringSize)
                .rotationEffect(.degrees(-90))

            if progress > 0.015, progress < 1 {
                Circle()
                    .fill(OogoColor.red)
                    .frame(width: 5, height: 5)
                    .offset(y: -Self.ringSize / 2)
                    .rotationEffect(.degrees(progress * 360))
            }

            completionSpark
        }
        .frame(width: Self.ringSize, height: Self.ringSize)
        .scaleEffect(phase == .holding ? 0.972 : 1)
        .animation(reduceMotion ? .easeOut(duration: 0.2) : OogoMotion.snap, value: phase)
        .contentShape(.circle)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginHold() }
                .onEnded { _ in releaseHold() }
        )
        .accessibilityElement()
        .accessibilityLabel("hold to commit")
        .accessibilityHint("hold three second. oog take word.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { seal() }
    }

    /// One thin ring walking outward, one small red pulse. Nothing else.
    private var completionSpark: some View {
        ZStack {
            Circle()
                .strokeBorder(primaryText.opacity(bloom ? 0 : 0.7), lineWidth: 1.2)
                .frame(width: Self.ringSize, height: Self.ringSize)
                .scaleEffect(bloom ? 1.65 : 1)

            Circle()
                .fill(OogoColor.red.opacity(bloom ? 0 : 0.55))
                .frame(width: 16, height: 16)
                .scaleEffect(bloom ? 3.6 : 0.5)
        }
        .opacity(phase == .sealed ? 1 : 0)
        .allowsHitTesting(false)
    }

    // MARK: - Finale

    private var finale: some View {
        ZStack {
            Text("GOOD.")
                .font(OogoFont.heavy(58))
                .oogoTracking(58)
                .foregroundStyle(primaryText)
                .opacity(phase == .good ? 1 : 0)

            VStack(spacing: 12) {
                Text("NOW GO GET STRONG.")
                    .font(OogoFont.heavy(34))
                    .oogoTracking(34)
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)

                Text("hunt begin.")
                    .font(OogoFont.caption)
                    .foregroundStyle(quietText)
            }
            .opacity(phase == .go ? 1 : 0)
        }
        .padding(.horizontal, OogoMetric.margin + 8)
        .animation(.easeInOut(duration: 0.4), value: phase)
    }

    private var backButton: some View {
        Button {
            onBack()
        } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(OogoColor.ink)
                .frame(width: 34, height: 34)
                .background { Circle().fill(OogoColor.cloud) }
                .contentShape(.circle)
        }
        .buttonStyle(OogoPressStyle(scale: 0.9))
        .accessibilityLabel("go back")
        .padding(.leading, OogoMetric.margin)
        .padding(.top, 10)
        .opacity(phase == .idle ? 1 : 0)
        .disabled(phase != .idle)
        .animation(.easeOut(duration: 0.2), value: phase)
    }

    // MARK: - Hold

    private func beginHold() {
        guard phase == .idle else { return }
        phase = .holding
        firedMarks = []
        Haptic.prime()
        Haptic.tap()

        holdTask?.cancel()
        holdTask = Task {
            let start = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled else { return }
                let value = min(Date().timeIntervalSince(start) / Self.holdSeconds, 1)
                progress = value
                fireMarks(upTo: value)
                if value >= 1 {
                    seal()
                    return
                }
            }
        }
    }

    /// Tension gathering under the thumb: discrete pulses, never a buzz.
    private func fireMarks(upTo value: Double) {
        for (index, mark) in Self.marks.enumerated() where value >= mark && !firedMarks.contains(index) {
            firedMarks.insert(index)
            switch index {
            case 0: Haptic.soft(intensity: 0.4)
            case 1: Haptic.soft(intensity: 0.6)
            case 2: Haptic.firm()
            default: Haptic.soft(intensity: 1)
            }
        }
    }

    private func releaseHold() {
        guard phase == .holding else { return }
        holdTask?.cancel()
        phase = .idle
        firedMarks = []
        Haptic.tick()
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .easeOut(duration: 0.45)) {
            progress = 0
        }
    }

    private func seal() {
        guard phase != .sealed, !isFinished else { return }
        holdTask?.cancel()
        progress = 1
        phase = .sealed
        Haptic.done()

        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.85)) { bloom = true }
        }

        finaleTask?.cancel()
        finaleTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            phase = .good
            try? await Task.sleep(for: .milliseconds(1150))
            guard !Task.isCancelled else { return }
            phase = .go
            try? await Task.sleep(for: .milliseconds(1900))
            guard !Task.isCancelled else { return }
            onDone()
        }
    }
}
