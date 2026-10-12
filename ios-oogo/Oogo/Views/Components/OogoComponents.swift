//
//  OogoComponents.swift
//  Oogo
//
//  Shared building blocks: wordmark, top bar, buttons, chips, cards, rings, grids.
//

import SwiftUI

// MARK: - Wordmark

/// The oogo wordmark, drawn from geometric rings so it stays crisp at any size.
struct OogoWordmark: View {
    var diameter: CGFloat = 26
    var color: Color = OogoColor.ink

    private var lineWidth: CGFloat { diameter * 0.265 }

    var body: some View {
        HStack(alignment: .top, spacing: diameter * 0.1) {
            ring
            ring
            gGlyph
            ring
        }
        .frame(height: diameter * 1.4, alignment: .top)
        .accessibilityLabel("oogo")
    }

    private var ring: some View {
        Circle()
            .strokeBorder(color, lineWidth: lineWidth)
            .frame(width: diameter, height: diameter)
    }

    private var gGlyph: some View {
        Circle()
            .strokeBorder(color, lineWidth: lineWidth)
            .frame(width: diameter, height: diameter)
            .overlay {
                Path { path in
                    let d = diameter
                    path.move(to: CGPoint(x: d - lineWidth / 2, y: d * 0.52))
                    path.addLine(to: CGPoint(x: d - lineWidth / 2, y: d * 1.10))
                    path.addQuadCurve(
                        to: CGPoint(x: d * 0.44, y: d * 1.38),
                        control: CGPoint(x: d - lineWidth / 2, y: d * 1.38)
                    )
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
    }
}

// MARK: - Top bar

struct OogoTopBar: View {
    var onBell: (() -> Void)?
    var hasUnread: Bool = true

    var body: some View {
        HStack(alignment: .center) {
            OogoWordmark(diameter: 20)
            Spacer(minLength: 0)
            if let onBell {
                Button {
                    onBell()
                } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(OogoColor.ink)
                        .overlay(alignment: .topTrailing) {
                            if hasUnread {
                                Circle()
                                    .fill(OogoColor.red)
                                    .frame(width: 7, height: 7)
                                    .offset(x: 3, y: -2)
                            }
                        }
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(.rect)
                }
                .buttonStyle(OogoPressStyle(scale: 0.9))
                .accessibilityLabel("oog say")
            }
        }
        .padding(.horizontal, OogoMetric.margin)
        .padding(.top, 4)
    }
}

// MARK: - Small parts

struct RedDot: View {
    var size: CGFloat = 6

    var body: some View {
        Circle()
            .fill(OogoColor.red)
            .frame(width: size, height: size)
    }
}

/// Red dot that breathes when work is waiting, and holds still when it is not.
struct BreathingDot: View {
    var size: CGFloat = 7
    var isBreathing: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded: Bool = false

    var body: some View {
        Circle()
            .fill(OogoColor.red)
            .frame(width: size, height: size)
            .scaleEffect(isExpanded ? 1.28 : 1)
            .opacity(isExpanded ? 1 : 0.78)
            .onAppear {
                guard isBreathing, !reduceMotion else { return }
                withAnimation(OogoMotion.breathe) { isExpanded = true }
            }
            .onChange(of: isBreathing) { _, newValue in
                guard !reduceMotion else { return }
                if newValue {
                    withAnimation(OogoMotion.breathe) { isExpanded = true }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) { isExpanded = false }
                }
            }
    }
}

/// Uppercase tracked label used above values.
struct TinyLabel: View {
    let text: String
    var size: CGFloat = 11.5
    var color: Color = OogoColor.secondaryText

    var body: some View {
        Text(text.uppercased())
            .font(OogoFont.semibold(size))
            .tracking(1.5)
            .foregroundStyle(color)
    }
}

// MARK: - Waving palm

/// A palm that waves once on appear, and again when tapped.
struct WavingPalm: View {
    var size: CGFloat = 30

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var waveCount: Int = 0

    var body: some View {
        Button {
            Haptic.tick()
            waveCount += 1
        } label: {
            Text("👋")
                .font(.system(size: size))
                .rotationEffect(.degrees(-8), anchor: .bottomLeading)
                .modifier(WaveKeyframes(trigger: waveCount, isEnabled: !reduceMotion))
                .frame(width: size * 1.5, height: size * 1.5)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("oog wave")
        .onAppear {
            guard !reduceMotion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { waveCount += 1 }
        }
    }
}

/// Three-beat wave, driven by a changing trigger value.
private struct WaveKeyframes: ViewModifier {
    let trigger: Int
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.phaseAnimator(
                [0.0, 1.0, -1.0, 0.7, 0.0],
                trigger: trigger
            ) { view, phase in
                view
                    .rotationEffect(.degrees(14 * phase), anchor: .bottom)
                    .offset(y: phase == 0 ? 0 : -1.5)
            } animation: { _ in
                .spring(response: 0.22, dampingFraction: 0.5)
            }
        } else {
            content
        }
    }
}

// MARK: - Rolling number

/// Number that rolls up when it changes, with even-width digits.
struct RollingNumber: View {
    let value: Int
    var size: CGFloat = 26
    var suffix: String?
    var color: Color = OogoColor.ink

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text("\(value)")
                .font(OogoFont.number(size))
                .foregroundStyle(color)
                .contentTransition(.numericText(value: Double(value)))
                .animation(OogoMotion.snap, value: value)
            if let suffix {
                Text(suffix)
                    .font(OogoFont.medium(size * 0.5))
                    .foregroundStyle(OogoColor.secondaryText)
            }
        }
    }
}

// MARK: - Ring

/// Thin progress ring. Used for the week goal and the rest countdown.
struct OogoRing: View {
    let progress: Double
    var lineWidth: CGFloat = 5
    var trackColor: Color = OogoColor.mist
    var color: Color = OogoColor.ink

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(OogoMotion.soft, value: progress)
        }
    }
}

// MARK: - Buttons

struct OogoPrimaryButton: View {
    let title: String
    var systemImage: String? = "arrow.right"
    var isEnabled: Bool = true
    /// Set false when the action fires its own feedback, so nothing hits twice.
    var firesHaptic: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            if firesHaptic { Haptic.firm() }
            action()
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(OogoFont.bodyStrong)
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundStyle(isEnabled ? Color.white : OogoColor.secondaryText.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: OogoMetric.buttonHeight)
            .background {
                Capsule(style: .continuous)
                    .fill(isEnabled ? OogoColor.ink : OogoColor.disabled)
                    .shadow(color: Color.black.opacity(isEnabled ? 0.18 : 0), radius: 16, x: 0, y: 8)
            }
            .contentShape(.capsule)
        }
        .buttonStyle(OogoPressStyle())
        .disabled(!isEnabled)
    }
}

struct OogoSecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(OogoFont.bodyStrong)
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(OogoColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: OogoMetric.buttonHeight)
            .background {
                Capsule(style: .continuous)
                    .fill(OogoColor.paper)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(OogoColor.ink, lineWidth: 1.6)
                    }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(OogoPressStyle())
    }
}

/// Round icon button used in the work runner and sheet headers.
struct OogoCircleButton: View {
    let systemImage: String
    var caption: String?
    var diameter: CGFloat = 56
    var iconSize: CGFloat = 17
    var tint: Color = OogoColor.ink
    var isEnabled: Bool = true
    /// Set false when the action fires its own feedback, so nothing hits twice.
    var firesHaptic: Bool = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button {
                if firesHaptic { Haptic.tap() }
                action()
            } label: {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(isEnabled ? tint : OogoColor.disabled)
                    .frame(width: diameter, height: diameter)
                    .background {
                        Circle()
                            .fill(OogoColor.paper)
                            .overlay { Circle().strokeBorder(OogoColor.mist, lineWidth: 1.2) }
                    }
                    .contentShape(.circle)
            }
            .buttonStyle(OogoPressStyle(scale: 0.9))
            .disabled(!isEnabled)

            if let caption {
                Text(caption)
                    .font(OogoFont.regular(13))
                    .foregroundStyle(isEnabled ? OogoColor.secondaryText : OogoColor.disabled)
            }
        }
        .accessibilityLabel(caption ?? systemImage)
    }
}

/// Small close button for sheet headers. Dismissal stays silent.
struct OogoCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(OogoColor.ink)
                .frame(width: 34, height: 34)
                .background { Circle().fill(OogoColor.cloud) }
                .contentShape(.circle)
        }
        .buttonStyle(OogoPressStyle(scale: 0.9))
        .accessibilityLabel("close")
    }
}

// MARK: - Chips

struct OogoChip: View {
    let title: String
    let isSelected: Bool
    var showsDot: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.select()
            action()
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(OogoFont.semibold(15.5))
                    .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 14)
                    .frame(height: OogoMetric.chipHeight)
                    .frame(maxWidth: .infinity)
                    .background {
                        Capsule(style: .continuous)
                            .fill(isSelected ? OogoColor.ink : OogoColor.cloud)
                    }
                if showsDot {
                    RedDot(size: 5)
                        .opacity(isSelected ? 1 : 0)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(OogoPressStyle(scale: 0.94))
    }
}

/// Small metadata pill on cloud, e.g. `35 min`.
struct OogoMetaPill: View {
    let text: String
    var systemImage: String?
    var isDark: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
            }
            Text(text)
                .font(OogoFont.medium(14.5))
                .monospacedDigit()
        }
        .foregroundStyle(isDark ? Color.white : OogoColor.ink)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background {
            Capsule(style: .continuous).fill(isDark ? OogoColor.ink : OogoColor.cloud)
        }
    }
}

/// Value pill with a lighter trailing unit, e.g. **16** KG.
struct OogoValuePill: View {
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 5) {
            Text(value)
                .font(OogoFont.bold(15.5))
                .monospacedDigit()
                .foregroundStyle(OogoColor.ink)
                .contentTransition(.numericText())
            Text(unit)
                .font(OogoFont.regular(15))
                .foregroundStyle(OogoColor.secondaryText)
        }
        .padding(.horizontal, 15)
        .frame(height: 38)
        .background { Capsule(style: .continuous).fill(OogoColor.cloud) }
    }
}

// MARK: - Segmented day picker

struct DaySegmentedPicker: View {
    @Binding var selection: DayType
    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DayType.allCases) { day in
                Button {
                    guard selection != day else { return }
                    Haptic.select()
                    withAnimation(OogoMotion.snap) {
                        selection = day
                    }
                } label: {
                    Text(day.shortName)
                        .font(OogoFont.semibold(17))
                        .foregroundStyle(selection == day ? Color.white : OogoColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            if selection == day {
                                Capsule(style: .continuous)
                                    .fill(OogoColor.ink)
                                    .matchedGeometryEffect(id: "daySegment", in: indicator)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule(style: .continuous)
                .fill(OogoColor.paper)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(OogoColor.mist, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 5)
        }
    }
}

// MARK: - Stepper card

struct OogoStepperCard: View {
    let label: String
    let value: Int
    var unit: String?
    var canDecrement: Bool = true
    var canIncrement: Bool = true
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TinyLabel(text: label)
            HStack(spacing: 6) {
                stepButton("minus", isEnabled: canDecrement, action: onDecrement)
                RollingNumber(value: value, size: 30, suffix: unit)
                    .frame(minWidth: 62)
                stepButton("plus", isEnabled: canIncrement, action: onIncrement)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .oogoCard(radius: OogoRadius.smallCard)
    }

    private func stepButton(_ symbol: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptic.tick()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isEnabled ? OogoColor.ink : OogoColor.disabled)
                .frame(width: 38, height: 38)
                .background { Circle().fill(OogoColor.cloud) }
                .contentShape(.circle)
        }
        .buttonStyle(OogoPressStyle(scale: 0.88))
        .disabled(!isEnabled)
    }
}

// MARK: - Cave wall

enum CaveWallCellState {
    case empty
    case filled
    case record
}

/// Consistency grid, rows of days ending today. Rows fade in one after another.
struct CaveWallGrid: View {
    let days: [Date]
    let state: (Date) -> CaveWallCellState
    var columns: Int = 17

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared: Bool = false

    private var rows: [[Date]] {
        stride(from: 0, to: days.count, by: columns).map { start in
            Array(days[start..<min(start + columns, days.count)])
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 5) {
                    ForEach(Array(row.enumerated()), id: \.element.timeIntervalSince1970) { column, day in
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .fill(fill(for: state(day)))
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(hasAppeared ? 1 : 0.4)
                            .opacity(hasAppeared ? 1 : 0)
                            .animation(
                                reduceMotion
                                    ? .easeOut(duration: 0.25)
                                    : OogoMotion.pop.delay(Double(rowIndex) * 0.06 + Double(column) * 0.012),
                                value: hasAppeared
                            )
                    }
                }
            }
        }
        .onAppear { hasAppeared = true }
        .accessibilityLabel("cave wall")
    }

    private func fill(for state: CaveWallCellState) -> Color {
        switch state {
        case .empty: return OogoColor.mist.opacity(0.7)
        case .filled: return OogoColor.ink
        case .record: return OogoColor.red
        }
    }
}

// MARK: - Stat tile

struct OogoStatTile: View {
    let symbol: String
    let label: String
    let value: Int
    var suffix: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(OogoColor.ink)
            RollingNumber(value: value, size: 27, suffix: suffix)
            Text(label)
                .font(OogoFont.caption)
                .foregroundStyle(OogoColor.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .oogoCard(radius: OogoRadius.smallCard)
    }
}

// MARK: - Headings

struct SectionHeading: View {
    let text: String

    var body: some View {
        Text(text)
            .font(OogoFont.heading)
            .oogoTracking(21)
            .foregroundStyle(OogoColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Screen title in the oogo display face, with an optional red period.
struct ScreenTitle: View {
    let text: String
    var size: CGFloat = 34
    var showsRedDot: Bool = false
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .bottom, spacing: 5) {
                Text(text)
                    .font(OogoFont.heavy(size))
                    .oogoTracking(size)
                    .foregroundStyle(OogoColor.ink)
                if showsRedDot {
                    Circle()
                        .fill(OogoColor.red)
                        .frame(width: size * 0.13, height: size * 0.13)
                        .padding(.bottom, size * 0.09)
                }
            }
            if let subtitle {
                Text(subtitle)
                    .font(OogoFont.subtitle)
                    .foregroundStyle(OogoColor.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Movement row

/// A movement inside a card: pattern label, name, rep stepper. Tap name or list button to choose.
struct MovementSlotRow: View {
    let pattern: MovementPattern
    let movement: Movement
    let repsText: String
    /// Bell text for bell moves, nil for bodyweight.
    let bellText: String?
    let canRepDown: Bool
    let canRepUp: Bool
    var showsDivider: Bool = false
    let onPick: () -> Void
    let onReps: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    Haptic.firm()
                    onPick()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        TinyLabel(text: pattern.label)
                        Text(movement.name)
                            .font(OogoFont.title)
                            .oogoTracking(27)
                            .foregroundStyle(OogoColor.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .contentTransition(.opacity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(OogoPressStyle(scale: 0.99))
                .accessibilityLabel("\(pattern.label): \(movement.name). Choose other move.")

                Button {
                    Haptic.firm()
                    onPick()
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OogoColor.ink)
                        .frame(width: 46, height: 46)
                        .background { Circle().fill(OogoColor.cloud) }
                        .contentShape(.circle)
                }
                .buttonStyle(OogoPressStyle(scale: 0.88))
                .accessibilityLabel("see all \(pattern.label) move")
            }

            HStack(spacing: 10) {
                RepStepper(
                    text: repsText,
                    unit: movement.repsLabel,
                    canDecrease: canRepDown,
                    canIncrease: canRepUp,
                    onChange: onReps
                )
                if let bellText {
                    Text(bellText)
                        .font(OogoFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(OogoColor.secondaryText)
                } else {
                    Text("body only")
                        .font(OogoFont.caption)
                        .foregroundStyle(OogoColor.secondaryText)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(OogoColor.mist)
                    .frame(height: 1)
            }
        }
    }
}

/// Inline minus / value / plus control for one movement's rep count.
struct RepStepper: View {
    let text: String
    let unit: String
    let canDecrease: Bool
    let canIncrease: Bool
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            stepButton("minus", direction: -1, isEnabled: canDecrease)

            VStack(spacing: 0) {
                Text(text)
                    .font(OogoFont.semibold(15.5))
                    .monospacedDigit()
                    .foregroundStyle(OogoColor.ink)
                    .contentTransition(.numericText())
            }
            .frame(minWidth: 62)

            stepButton("plus", direction: 1, isEnabled: canIncrease)
        }
        .padding(.horizontal, 4)
        .frame(height: 38)
        .background { Capsule().fill(OogoColor.cloud) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text) \(unit)")
    }

    private func stepButton(_ symbol: String, direction: Int, isEnabled: Bool) -> some View {
        Button {
            guard isEnabled else { return }
            Haptic.tick()
            withAnimation(OogoMotion.snap) { onChange(direction) }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isEnabled ? OogoColor.ink : OogoColor.disabled)
                .frame(width: 32, height: 32)
                .background { Circle().fill(OogoColor.paper.opacity(isEnabled ? 1 : 0.5)) }
                .contentShape(.circle)
        }
        .buttonStyle(OogoPressStyle(scale: 0.86))
        .disabled(!isEnabled)
        .accessibilityLabel(direction > 0 ? "More" : "Less")
    }
}

// MARK: - Search field

/// Quiet find field, shown only when a list is long.
struct OogoSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OogoColor.secondaryText)
            TextField(placeholder, text: $text)
                .font(OogoFont.body)
                .foregroundStyle(OogoColor.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
            if !text.isEmpty {
                Button {
                    Haptic.tick()
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(OogoColor.secondaryText.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("clear")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background {
            Capsule(style: .continuous)
                .fill(OogoColor.cloud)
        }
    }
}

// MARK: - Settings list

/// One row inside the profile settings card.
struct OogoSettingsRow: View {
    let systemImage: String
    let title: String
    var badge: Bool = false
    var detail: String?
    var showsDivider: Bool = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button {
                Haptic.tap()
                action()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(OogoColor.ink)
                        .frame(width: 26, alignment: .center)
                        .overlay(alignment: .topTrailing) {
                            if badge {
                                RedDot(size: 6).offset(x: 3, y: -2)
                            }
                        }
                    Text(title)
                        .font(OogoFont.body)
                        .foregroundStyle(OogoColor.ink)
                    Spacer(minLength: 8)
                    if let detail {
                        Text(detail)
                            .font(OogoFont.regular(16))
                            .foregroundStyle(OogoColor.secondaryText)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OogoColor.ink.opacity(0.4))
                }
                .padding(.vertical, 16)
                .contentShape(.rect)
            }
            .buttonStyle(OogoPressStyle(scale: 0.99))

            if showsDivider {
                Rectangle()
                    .fill(OogoColor.mist)
                    .frame(height: 1)
                    .padding(.leading, 42)
            }
        }
    }
}

// MARK: - Entrance animation

private struct OogoEntrance: ViewModifier {
    let isVisible: Bool
    let index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 18)
            .animation(
                reduceMotion ? .easeOut(duration: 0.2) : OogoMotion.soft.delay(Double(index) * 0.055),
                value: isVisible
            )
    }
}

extension View {
    func oogoEntrance(_ isVisible: Bool, index: Int) -> some View {
        modifier(OogoEntrance(isVisible: isVisible, index: index))
    }
}
