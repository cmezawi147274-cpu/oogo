//
//  CampView.swift
//  Oogo
//
//  Home. Resume strip, today at a glance, week ring, cave wall.
//

import SwiftUI

struct CampView: View {
    let onStart: () -> Void
    let onResume: (WorkSnapshot) -> Void
    let onBell: () -> Void

    @Environment(OogoStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wallRange: CaveWallRange = .month
    @State private var appeared: Bool = false
    @State private var isBreathing: Bool = false

    private var today: DayType { store.todayDayType }
    private var isRest: Bool { today == .feast }
    private var needsWork: Bool { !isRest && !store.didTrainToday }

    var body: some View {
        VStack(spacing: 0) {
            OogoTopBar(onBell: onBell)

            ScrollView(showsIndicators: false) {
                VStack(spacing: OogoMetric.cardGap) {
                    greeting
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    if let work = store.unfinishedWork {
                        resumeStrip(work)
                            .oogoEntrance(appeared, index: 0)
                    }

                    todayCard
                        .oogoEntrance(appeared, index: 1)

                    if store.shouldSuggestHeavierBell, let next = store.nextBellUp {
                        bellNudge(next)
                            .oogoEntrance(appeared, index: 2)
                    }

                    weekCard
                        .oogoEntrance(appeared, index: 3)

                    caveWallCard
                        .oogoEntrance(appeared, index: 4)
                }
                .padding(.horizontal, OogoMetric.margin)
                .padding(.bottom, OogoMetric.navClearance)
                .animation(OogoMotion.soft, value: store.unfinishedWork)
            }
        }
        .background(OogoColor.page)
        .onAppear {
            guard !appeared else { return }
            withAnimation(OogoMotion.soft.delay(0.04)) { appeared = true }
        }
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("oii \(store.hoomanName)")
                    .font(OogoFont.heavy(38))
                    .oogoTracking(38)
                    .foregroundStyle(OogoColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                WavingPalm(size: 28)
                    .offset(y: -2)
            }
            Text(subtitleText)
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitleText: String {
        if store.unfinishedWork != nil { return "work wait for you." }
        if isRest { return "today rest. body build." }
        return store.didTrainToday ? "work done today. nice." : "plan ready. go when ready."
    }

    // MARK: - Resume

    private func resumeStrip(_ work: WorkSnapshot) -> some View {
        Button {
            Haptic.firm()
            onResume(work)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(OogoColor.ink)
                        .frame(width: 40, height: 40)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("finish work?")
                        .font(OogoFont.bold(18))
                        .foregroundStyle(OogoColor.ink)
                    Text("\(work.dayType.shortName.lowercased()) · round \(work.round) of \(work.rounds)")
                        .font(OogoFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(OogoColor.secondaryText)
                }
                Spacer(minLength: 0)
                Button {
                    Haptic.tick()
                    withAnimation(OogoMotion.soft) { store.clearProgress() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(OogoColor.secondaryText)
                        .frame(width: 32, height: 32)
                        .background { Circle().fill(OogoColor.cloud) }
                        .contentShape(.circle)
                }
                .buttonStyle(OogoPressStyle(scale: 0.88))
                .accessibilityLabel("drop work")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard(radius: OogoRadius.smallCard)
            .contentShape(.rect)
        }
        .buttonStyle(OogoPressStyle(scale: 0.99))
        .transition(.opacity.combined(with: .offset(y: -10)))
    }

    // MARK: - Today card

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                TinyLabel(text: "today")
                BreathingDot(size: 6, isBreathing: needsWork)
            }

            Text(isRest ? "rest day" : today.title.lowercased())
                .font(OogoFont.heavy(36))
                .oogoTracking(36)
                .foregroundStyle(OogoColor.ink)
                .padding(.top, 8)

            Text(today.caveLine)
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)
                .padding(.top, 3)

            if isRest {
                restBody
            } else {
                workBody
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    private var workBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(OogoColor.mist)
                .frame(height: 1)
                .padding(.vertical, 16)

            HStack(spacing: 10) {
                TinyLabel(text: "train")
                Text(today.patterns.map(\.caveWord).joined(separator: " · "))
                    .font(OogoFont.bodyStrong)
                    .foregroundStyle(OogoColor.ink)
            }

            HStack(spacing: 8) {
                OogoMetaPill(text: "\(store.rounds) round")
                OogoMetaPill(text: store.bellText)
                OogoMetaPill(text: "\(today.estimatedMinutes) min", systemImage: "clock")
            }
            .padding(.top, 14)

            OogoPrimaryButton(title: store.didTrainToday ? "work again" : "start work") {
                onStart()
            }
            .scaleEffect(isBreathing ? 1.012 : 1)
            .padding(.top, 18)
            .onAppear {
                guard needsWork, !reduceMotion else { return }
                withAnimation(OogoMotion.breathe) { isBreathing = true }
            }
            .onChange(of: needsWork) { _, wants in
                guard !reduceMotion else { return }
                withAnimation(wants ? OogoMotion.breathe : OogoMotion.snap) { isBreathing = wants }
            }
        }
    }

    private var restBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                OogoMetaPill(text: "no work", systemImage: "moon")
                if let next = store.nextTrainingDay {
                    OogoMetaPill(
                        text: "next \(next.type.shortName.lowercased()) \(next.date.formatted(.dateTime.weekday(.abbreviated)).lowercased())"
                    )
                }
            }
            .padding(.top, 16)

            OogoSecondaryButton(title: "loose work", systemImage: "arrow.right") {
                onStart()
            }
            .padding(.top, 18)
        }
    }

    // MARK: - Bell nudge

    private func bellNudge(_ next: Int) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("bell feel light.")
                    .font(OogoFont.bold(18))
                    .foregroundStyle(OogoColor.ink)
                Text("go \(store.weightText(next))?")
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
            }
            Spacer(minLength: 0)
            Button {
                Haptic.tick()
                withAnimation(OogoMotion.soft) { store.dismissBellNudge() }
            } label: {
                Text("no")
                    .font(OogoFont.semibold(15))
                    .foregroundStyle(OogoColor.secondaryText)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background { Capsule().fill(OogoColor.cloud) }
                    .contentShape(.capsule)
            }
            .buttonStyle(OogoPressStyle(scale: 0.93))

            Button {
                Haptic.firm()
                withAnimation(OogoMotion.snap) { store.acceptHeavierBell() }
            } label: {
                Text("yes")
                    .font(OogoFont.semibold(15))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .frame(height: 40)
                    .background { Capsule().fill(OogoColor.ink) }
                    .contentShape(.capsule)
            }
            .buttonStyle(OogoPressStyle(scale: 0.93))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .oogoCard(radius: OogoRadius.smallCard)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Week

    private var weekCard: some View {
        HStack(spacing: 18) {
            ZStack {
                OogoRing(progress: store.weekProgress, lineWidth: 6)
                    .frame(width: 62, height: 62)
                Text("\(store.workThisWeek)")
                    .font(OogoFont.number(22))
                    .foregroundStyle(OogoColor.ink)
                    .contentTransition(.numericText(value: Double(store.workThisWeek)))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(store.workThisWeek) of \(store.weekTarget) work done")
                    .font(OogoFont.bold(18))
                    .monospacedDigit()
                    .foregroundStyle(OogoColor.ink)
                Text(weekLine)
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                RollingNumber(value: store.streak, size: 24)
                TinyLabel(text: "streak")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard(radius: OogoRadius.smallCard)
    }

    private var weekLine: String {
        let left = store.weekTarget - store.workThisWeek
        if left <= 0 { return "week done. oog proud." }
        return left == 1 ? "one more this week." : "\(left) more this week."
    }

    // MARK: - Cave wall

    private var caveWallCard: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text("cave wall")
                    .font(OogoFont.heading)
                    .oogoTracking(21)
                    .foregroundStyle(OogoColor.ink)
                Spacer(minLength: 8)
                Menu {
                    ForEach(CaveWallRange.allCases) { range in
                        Button(range.title) {
                            Haptic.select()
                            withAnimation(OogoMotion.snap) { wallRange = range }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(wallRange.title)
                            .font(OogoFont.medium(15))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(OogoColor.secondaryText)
                }
            }

            Text("show up. get strong.")
                .font(OogoFont.caption)
                .foregroundStyle(OogoColor.secondaryText)

            CaveWallGrid(days: store.caveWallDays(count: wallRange.dayCount), state: cellState)
                .padding(.top, 14)
                .id(wallRange)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    private func cellState(_ day: Date) -> CaveWallCellState {
        guard store.didTrain(on: day) else { return .empty }
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return .record }
        let record = store.sessions.first { session in
            calendar.isDate(session.date, inSameDayAs: day) && session.bellWeight >= store.heaviestBell
        }
        return record != nil ? .record : .filled
    }
}

// MARK: - Cave wall range

enum CaveWallRange: String, CaseIterable, Identifiable {
    case month
    case quarter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: return "this month"
        case .quarter: return "3 months"
        }
    }

    var dayCount: Int {
        switch self {
        case .month: return 68
        case .quarter: return 119
        }
    }
}
