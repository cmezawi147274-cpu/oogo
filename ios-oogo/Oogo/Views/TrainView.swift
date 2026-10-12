//
//  TrainView.swift
//  Oogo
//
//  Build work: day type, movement slots, rounds, bell, rest.
//

import SwiftUI

struct TrainView: View {
    @Binding var day: DayType
    let onStart: (DayType) -> Void
    let onBell: () -> Void

    @Environment(OogoStore.self) private var store
    @State private var editingPattern: MovementPattern?
    @State private var appeared: Bool = false

    private let restOptions: [Int] = [30, 45, 60, 75]

    var body: some View {
        VStack(spacing: 0) {
            OogoTopBar(onBell: onBell)

            ScrollView(showsIndicators: false) {
                VStack(spacing: OogoMetric.cardGap) {
                    ScreenTitle(
                        text: "build work",
                        size: 34,
                        subtitle: subtitleText
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    DaySegmentedPicker(selection: $day)
                        .oogoEntrance(appeared, index: 0)

                    if day == .feast {
                        feastCard
                            .oogoEntrance(appeared, index: 1)
                            .transition(.opacity.combined(with: .offset(y: 12)))
                    } else {
                        movesCard
                            .oogoEntrance(appeared, index: 1)

                        HStack(spacing: 11) {
                            OogoStepperCard(
                                label: "round",
                                value: store.rounds,
                                canDecrement: store.rounds > 1,
                                canIncrement: store.rounds < 20,
                                onDecrement: { store.rounds = max(1, store.rounds - 1) },
                                onIncrement: { store.rounds = min(20, store.rounds + 1) }
                            )
                            OogoStepperCard(
                                label: "bell",
                                value: store.weightValue(store.bellWeight),
                                unit: store.weightUnit.label,
                                canDecrement: store.canStepBellDown,
                                canIncrement: store.canStepBellUp,
                                onDecrement: { store.stepBellDown() },
                                onIncrement: { store.stepBellUp() }
                            )
                        }
                        .oogoEntrance(appeared, index: 2)

                        restCard
                            .oogoEntrance(appeared, index: 3)

                        OogoPrimaryButton(title: "start work") {
                            onStart(day)
                        }
                        .padding(.top, 4)
                        .oogoEntrance(appeared, index: 4)
                    }
                }
                .padding(.horizontal, OogoMetric.margin)
                .padding(.bottom, OogoMetric.navClearance)
                .animation(OogoMotion.snap, value: day)
            }
        }
        .background(OogoColor.page)
        .sheet(item: $editingPattern) { pattern in
            MovementPickerSheet(pattern: pattern)
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(OogoMotion.soft.delay(0.04)) { appeared = true }
        }
    }

    private var subtitleText: String {
        day == store.todayDayType ? "this today work. change if want." : "\(day.shortName.lowercased()) work."
    }

    /// What a feast-day hooman jumps into when they insist on working.
    private var nextWorkDay: DayType {
        if let next = store.nextTrainingDay, next.type != .feast { return next.type }
        return .hunt
    }

    // MARK: - Moves

    private var movesCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(day.patterns.enumerated()), id: \.element) { index, pattern in
                let movement = store.movement(for: pattern)
                MovementSlotRow(
                    pattern: pattern,
                    movement: movement,
                    repsText: store.repsText(for: movement),
                    bellText: movement.usesBell ? store.bellText : nil,
                    canRepDown: store.canRepDown(movement),
                    canRepUp: store.canRepUp(movement),
                    showsDivider: index < day.patterns.count - 1,
                    onPick: { editingPattern = pattern },
                    onReps: { direction in store.stepReps(movement, by: direction) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    // MARK: - Rest timer

    private var restCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TinyLabel(text: "rest between round")
            HStack(spacing: 8) {
                ForEach(restOptions, id: \.self) { option in
                    OogoChip(title: "\(option) sec", isSelected: store.restSeconds == option) {
                        withAnimation(OogoMotion.snap) { store.restSeconds = option }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    // MARK: - Feast

    private var feastCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TinyLabel(text: "feast day")
            Text("no work today.")
                .font(OogoFont.heavy(30))
                .oogoTracking(30)
                .foregroundStyle(OogoColor.ink)
                .padding(.top, 8)
            Text("eat. sleep. walk slow.")
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)
                .padding(.top, 4)

            Rectangle()
                .fill(OogoColor.mist)
                .frame(height: 1)
                .padding(.vertical, 16)

            TinyLabel(text: "loose work")
            VStack(alignment: .leading, spacing: 6) {
                ForEach(MovementLibrary.feastPair) { movement in
                    HStack(spacing: 10) {
                        RedDot(size: 5)
                        Text(movement.name.lowercased())
                            .font(OogoFont.body)
                            .foregroundStyle(OogoColor.ink)
                        Spacer(minLength: 0)
                        Text("\(store.repsText(for: movement)) \(movement.repsLabel)")
                            .font(OogoFont.caption)
                            .monospacedDigit()
                            .foregroundStyle(OogoColor.secondaryText)
                    }
                }
            }
            .padding(.top, 10)

            OogoSecondaryButton(title: "train anyway", systemImage: nil) {
                withAnimation(OogoMotion.snap) { day = nextWorkDay }
            }
            .padding(.top, 20)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }
}

// MARK: - Movement picker

struct MovementPickerSheet: View {
    let pattern: MovementPattern

    @Environment(OogoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var options: [Movement] {
        let all = store.options(for: pattern)
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all }
        return all.filter { $0.name.localizedStandardContains(trimmed) }
    }

    private var showsSearch: Bool {
        store.options(for: pattern).count > 12
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    TinyLabel(text: pattern.label)
                    Text("pick move")
                        .font(OogoFont.heavy(28))
                        .oogoTracking(28)
                        .foregroundStyle(OogoColor.ink)
                    Text("\(store.options(for: pattern).count) move hooman can do.")
                        .font(OogoFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(OogoColor.secondaryText)
                }
                Spacer()
                OogoCloseButton { dismiss() }
            }
            .padding(.horizontal, OogoMetric.margin)
            .padding(.top, 22)
            .padding(.bottom, showsSearch ? 14 : 16)

            if showsSearch {
                OogoSearchField(placeholder: "find move", text: $query)
                    .padding(.horizontal, OogoMetric.margin)
                    .padding(.bottom, 14)
            }

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 9) {
                    ForEach(options) { movement in
                        row(movement)
                    }

                    if options.isEmpty {
                        VStack(spacing: 5) {
                            Text("oog not know that move.")
                                .font(OogoFont.bold(18))
                                .foregroundStyle(OogoColor.ink)
                            Text("try other word.")
                                .font(OogoFont.caption)
                                .foregroundStyle(OogoColor.secondaryText)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.horizontal, OogoMetric.margin)
                .padding(.bottom, 30)
                .animation(OogoMotion.snap, value: options.count)
            }
        }
        .background(OogoColor.page)
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
    }

    private func row(_ movement: Movement) -> some View {
        let isSelected = store.movement(for: pattern).id == movement.id
        return Button {
            Haptic.select()
            store.select(movement)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(movement.name)
                        .font(OogoFont.bold(18))
                        .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(store.repsText(for: movement)) \(movement.repsLabel)\(movement.usesBell ? " · bell" : " · body only")")
                        .font(OogoFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? Color.white.opacity(0.72) : OogoColor.secondaryText)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: OogoRadius.smallCard, style: .continuous)
                    .fill(isSelected ? OogoColor.ink : OogoColor.paper)
                    .overlay {
                        RoundedRectangle(cornerRadius: OogoRadius.smallCard, style: .continuous)
                            .strokeBorder(isSelected ? Color.clear : OogoColor.mist, lineWidth: 1)
                    }
            }
            .contentShape(.rect)
        }
        .buttonStyle(OogoPressStyle(scale: 0.98))
    }
}
