//
//  OnboardingView.swift
//  Oogo
//
//  First run. Oog meets hooman, learns kit and days, builds plan.
//

import SwiftUI

/// The steps oog walks the hooman through, in order.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case gate
    case name
    case goals
    case gear
    case bells
    case days
    case time
    case nudge
    case reveal
    case commit

    var id: Int { rawValue }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var back: OnboardingStep? { rawValue > 0 ? OnboardingStep(rawValue: rawValue - 1) : nil }

    /// How far along the thin line at the top sits.
    var progress: Double {
        Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}

struct OnboardingView: View {
    let onDone: () -> Void

    @Environment(OogoStore.self) private var store
    @Environment(AuthManager.self) private var auth
    @Environment(OogoSync.self) private var sync
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: OnboardingStep = .welcome
    @State private var isGoingBack: Bool = false
    @State private var name: String = ""
    @State private var bells: Set<Int> = [16, 24]
    @State private var unit: WeightUnit = .kg
    @State private var days: Int = 3
    @State private var customBell: String = ""
    @State private var isAddingBell: Bool = false
    @State private var revealTicks: Int = 0
    @State private var isPlanReady: Bool = false
    @State private var showPaywall: Bool = false
    @State private var nudgeTime: Date = Date()
    @State private var isAskingNudge: Bool = false

    @FocusState private var isNamingFocused: Bool

    var body: some View {
        ZStack {
            OogoColor.page.ignoresSafeArea()

            if step == .commit {
                // Full bleed. No chrome, no progress line, nothing to look at but the stone.
                CommitView(onBack: goBack, onDone: sealCommit)
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    header

                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    footer
                }
                .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(onFinish: finish)
        }
        .alert("how heavy bell?", isPresented: $isAddingBell) {
            TextField("kg", text: $customBell)
                .keyboardType(.numberPad)
            Button("oog remember") { addCustomBell() }
            Button("no", role: .cancel) { customBell = "" }
        } message: {
            Text("oog write on wall. number in kg.")
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                goBack()
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
            .opacity(step.back == nil ? 0 : 1)
            .disabled(step.back == nil)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(OogoColor.mist)
                    Capsule()
                        .fill(OogoColor.ink)
                        .frame(width: max(6, proxy.size.width * step.progress))
                }
            }
            .frame(height: 4)
            .animation(OogoMotion.soft, value: step)
        }
        .padding(.horizontal, OogoMetric.margin)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .opacity(step == .welcome ? 0 : 1)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch step {
            case .welcome: welcomeStep
            case .gate: GateView(onSignedIn: handleSignedIn)
            case .name: nameStep
            case .goals: goalsStep
            case .gear: gearStep
            case .bells: bellsStep
            case .days: daysStep
            case .time: timeStep
            case .nudge: nudgeStep
            case .reveal: revealStep
            case .commit: EmptyView()
            }
        }
        .transition(stepTransition)
    }

    private var stepTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let forward = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
        let backward = AnyTransition.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
        return isGoingBack ? backward : forward
    }

    @ViewBuilder
    private var footer: some View {
        // The wall carries its own two doors; commit is full bleed.
        if step != .commit, step != .gate {
            stepFooter
        }
    }

    private var stepFooter: some View {
        VStack(spacing: 10) {
            OogoPrimaryButton(
                title: buttonTitle,
                systemImage: step == .nudge ? "bell.fill" : "arrow.right",
                isEnabled: canAdvance && !isAskingNudge
            ) {
                goNext()
            }

            if step == .nudge {
                Button {
                    Haptic.tap()
                    store.remindersOn = false
                    advance()
                } label: {
                    Text("not now")
                        .font(OogoFont.medium(15))
                        .foregroundStyle(OogoColor.secondaryText)
                        .frame(height: 18)
                        .contentShape(.rect)
                }
                .buttonStyle(OogoPressStyle(scale: 0.95))
            } else {
                Text(footnote)
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
                    .frame(height: 18)
                    .opacity(footnote.isEmpty ? 0 : 1)
            }
        }
        .padding(.horizontal, OogoMetric.margin)
        .padding(.bottom, 10)
    }

    private var buttonTitle: String {
        switch step {
        case .welcome: return "let's go"
        case .gate: return "next"
        case .name: return "oog remember"
        case .goals: return "next"
        case .gear: return "next"
        case .bells: return "next"
        case .days: return "next"
        case .time: return "next"
        case .nudge: return "let oog shout"
        case .reveal: return "oog ready. hooman ready?"
        case .commit: return "commit"
        }
    }

    private var footnote: String {
        switch step {
        case .goals: return store.goals.isEmpty ? "pick one. two most." : ""
        case .gear: return store.hasTwoBells ? "pair open double work." : "one bell do everything."
        case .bells: return bells.isEmpty ? "oog need one bell." : ""
        case .time: return "oog shout only on work day."
        default: return ""
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .gate: return auth.isSignedIn || !auth.isConfigured
        case .goals: return !store.goals.isEmpty
        case .bells: return !bells.isEmpty
        case .reveal: return isPlanReady
        case .commit: return false
        default: return true
        }
    }

    // MARK: - Step: welcome

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("oii hooman")
                    .font(OogoFont.heavy(40))
                    .oogoTracking(40)
                    .foregroundStyle(OogoColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                WavingPalm(size: 32)
                    .offset(y: -2)
            }
            .padding(.top, 26)

            VStack(alignment: .leading, spacing: 1) {
                Text("i'm oog.")
                Text("your kettlebell coach.")
            }
            .font(OogoFont.regular(19))
            .foregroundStyle(OogoColor.secondaryText)
            .padding(.top, 10)

            Spacer(minLength: 12)

            OogMascot()
                .frame(maxWidth: .infinity)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, OogoMetric.margin)
    }

    // MARK: - Step: name

    private var nameStep: some View {
        StepScaffold(title: "what oog call hooman?", subtitle: "oog shout this every morning.") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("hooman", text: $name)
                    .font(OogoFont.heavy(34))
                    .oogoTracking(34)
                    .foregroundStyle(OogoColor.ink)
                    .tint(OogoColor.red)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNamingFocused)
                    .onSubmit { goNext() }

                Rectangle()
                    .fill(isNamingFocused ? OogoColor.ink : OogoColor.mist)
                    .frame(height: 2)
                    .animation(OogoMotion.snap, value: isNamingFocused)

                Text("leave empty. oog still call hooman.")
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
            }
            .padding(.top, 8)
            .onAppear {
                guard name.isEmpty, store.hoomanName != "hooman" else { return }
                name = store.hoomanName
            }
        }
    }

    // MARK: - Step: goals

    private var goalsStep: some View {
        StepScaffold(title: "what hooman want?", subtitle: "pick up to 2. oog build round that.") {
            VStack(spacing: 9) {
                ForEach(OogoGoal.allCases) { goal in
                    ChoiceRow(
                        label: goal.label,
                        symbol: goal.symbol,
                        isSelected: store.goals.contains(goal)
                    ) {
                        withAnimation(OogoMotion.snap) { store.toggleGoal(goal) }
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Step: gear

    private var gearStep: some View {
        StepScaffold(title: "what hooman got?", subtitle: "oog only show move hooman can do.") {
            TinyLabel(text: "bell hooman lift with")

            HStack(spacing: 9) {
                ForEach([OogoGear.oneBell, OogoGear.twoBells]) { item in
                    ChoiceTile(
                        label: item.label,
                        hint: item.hint,
                        symbol: item.symbol,
                        isSelected: bellChoice == item
                    ) {
                        withAnimation(OogoMotion.snap) { store.toggleGear(item) }
                    }
                }
            }
            .padding(.top, 10)

            TinyLabel(text: "anything else?")
                .padding(.top, 22)

            VStack(spacing: 9) {
                ForEach(extraGear) { item in
                    ChoiceRow(
                        label: item.label,
                        hint: item.hint,
                        symbol: item.symbol,
                        isSelected: store.gear.contains(item)
                    ) {
                        withAnimation(OogoMotion.snap) { store.toggleGear(item) }
                    }
                }
            }
            .padding(.top, 10)

            Text("bell enough. rest just give oog more move.")
                .font(OogoFont.caption)
                .foregroundStyle(OogoColor.secondaryText)
                .padding(.top, 14)
        }
    }

    /// Which bell tile reads as picked: two bell wins when owned.
    private var bellChoice: OogoGear { store.hasTwoBells ? .twoBells : .oneBell }

    private var extraGear: [OogoGear] {
        OogoGear.allCases.filter { !$0.isBell }
    }

    // MARK: - Step: bells

    private var bellsStep: some View {
        StepScaffold(title: bellsTitle, subtitle: bellsSubtitle) {
            HStack(spacing: 8) {
                ForEach(WeightUnit.allCases) { option in
                    OogoChip(title: option.label, isSelected: unit == option) {
                        withAnimation(OogoMotion.snap) { unit = option }
                    }
                }
                Spacer(minLength: 0)
                Text(bellSummary)
                    .font(OogoFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(OogoColor.secondaryText)
                    .contentTransition(.numericText(value: Double(bells.count)))
                    .animation(OogoMotion.snap, value: bells.count)
            }
            .padding(.bottom, 14)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 9)], spacing: 9) {
                ForEach(bellChoices, id: \.self) { weight in
                    BellTile(
                        text: bellLabel(weight),
                        isSelected: bells.contains(weight)
                    ) {
                        withAnimation(OogoMotion.snap) { toggleBell(weight) }
                    }
                }

                Button {
                    Haptic.tap()
                    isAddingBell = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("odd bell")
                            .font(OogoFont.semibold(15))
                    }
                    .foregroundStyle(OogoColor.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        RoundedRectangle(cornerRadius: OogoRadius.smallCard, style: .continuous)
                            .strokeBorder(OogoColor.mist, style: StrokeStyle(lineWidth: 1.4, dash: [5, 5]))
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(OogoPressStyle(scale: 0.96))
            }
        }
        .onAppear {
            if bells.isEmpty {
                bells = store.ownedBells
                unit = store.weightUnit
            }
        }
    }

    private var bellsTitle: String { "what bell hooman have?" }

    private var bellsSubtitle: String { "tap every bell on hooman floor. pick many." }

    private var bellChoices: [Int] {
        Set(OogoStore.bellCatalog).union(bells).sorted()
    }

    private var bellSummary: String {
        bells.isEmpty ? "no bell yet" : "\(bells.count) bell"
    }

    private func bellLabel(_ kilograms: Int) -> String {
        let value = unit == .kg ? kilograms : Int((Double(kilograms) * 2.20462).rounded())
        return "\(value) \(unit.label)"
    }

    private func toggleBell(_ weight: Int) {
        Haptic.select()
        if bells.contains(weight) {
            bells.remove(weight)
        } else {
            bells.insert(weight)
        }
    }

    private func addCustomBell() {
        let digits = customBell.filter(\.isNumber)
        customBell = ""
        guard let value = Int(digits), value >= 4, value <= 100 else { return }
        let kilograms = max(4, unit == .kg ? value : Int((Double(value) / 2.20462).rounded()))
        Haptic.firm()
        withAnimation(OogoMotion.snap) { bells.insert(kilograms) }
    }

    // MARK: - Step: days

    private var daysStep: some View {
        StepScaffold(title: "how many day hooman work?", subtitle: "rest day not lazy. rest day build.") {
            HStack(spacing: 9) {
                ForEach([3, 4, 5], id: \.self) { option in
                    DayCountTile(count: option, isSelected: days == option) {
                        Haptic.select()
                        withAnimation(OogoMotion.snap) { days = option }
                    }
                }
            }

            WeekStrip(daysPerWeek: days)
                .padding(.top, 18)

            VStack(alignment: .leading, spacing: 5) {
                Text(daysLine)
                Text("* hunt = front chain. chest, shoulder, arm, front leg. push and squat.")
                    .fixedSize(horizontal: false, vertical: true)
                Text("* gather = back chain. back, butt, hamstring, middle. pull, hinge, swing.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(OogoFont.caption)
            .foregroundStyle(OogoColor.secondaryText)
            .padding(.top, 14)
        }
    }

    private var daysLine: String {
        switch days {
        case 4: return "four day. hunt*, gather*, hunt, gather."
        case 5: return "five day. big week. oog watch."
        default: return "three day. plenty. start here."
        }
    }

    // MARK: - Step: time

    private var timeStep: some View {
        StepScaffold(title: "when hooman work?", subtitle: "oog grunt at this hour. one time, every work day.") {
            HStack(spacing: 9) {
                ForEach(NudgePreset.allCases) { preset in
                    PresetTile(
                        label: preset.label,
                        symbol: preset.symbol,
                        detail: preset.detail,
                        isSelected: isPreset(preset)
                    ) {
                        setPreset(preset)
                    }
                }
            }

            DatePicker("", selection: $nudgeTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            Text("hooman change hour any time on hooman page.")
                .font(OogoFont.caption)
                .foregroundStyle(OogoColor.secondaryText)
        }
        .onAppear { nudgeTime = store.nudgeTime }
    }

    private func isPreset(_ preset: NudgePreset) -> Bool {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: nudgeTime)
        return parts.hour == preset.hour && parts.minute == 0
    }

    private func setPreset(_ preset: NudgePreset) {
        Haptic.select()
        guard let date = Calendar.current.date(
            bySettingHour: preset.hour,
            minute: 0,
            second: 0,
            of: Date()
        ) else { return }
        withAnimation(OogoMotion.snap) { nudgeTime = date }
    }

    // MARK: - Step: nudge

    private var nudgeStep: some View {
        StepScaffold(title: "oog shout at \(timeText)?", subtitle: "one grunt on work day. oog never shout twice.") {
            VStack(alignment: .leading, spacing: 15) {
                nudgeLine("bell", "one grunt, work day only.")
                nudgeLine("moon.zzz", "rest day quiet. hooman sleep.")
                nudgeLine("checkmark.circle", "work done already? oog say nothing.")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()

            Text("hooman say no now, oog keep hour anyway. turn on later on hooman page.")
                .font(OogoFont.caption)
                .foregroundStyle(OogoColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
        }
    }

    private func nudgeLine(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(OogoColor.ink)
                .frame(width: 22)
            Text(text)
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var timeText: String {
        nudgeTime.formatted(.dateTime.hour().minute())
    }

    /// Asks the phone once, then walks on either way.
    private func askNudge() {
        isAskingNudge = true
        Task {
            let granted = await NudgeService.requestPermission()
            store.remindersOn = granted
            if granted { Haptic.success() }
            isAskingNudge = false
            advance()
        }
    }

    // MARK: - Step: reveal

    private var revealStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isPlanReady ? "plan ready, \(finalName)." : "oog build plan…")
                .font(OogoFont.heavy(34))
                .oogoTracking(34)
                .foregroundStyle(OogoColor.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(revealLines.enumerated()), id: \.offset) { index, line in
                    HStack(spacing: 12) {
                        Image(systemName: revealTicks > index ? "checkmark" : "circle.dotted")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(revealTicks > index ? OogoColor.red : OogoColor.disabled)
                            .frame(width: 18)
                        Text(line)
                            .font(OogoFont.body)
                            .foregroundStyle(revealTicks > index ? OogoColor.ink : OogoColor.secondaryText)
                    }
                    .opacity(revealTicks > index ? 1 : 0.45)
                }
            }
            .padding(.top, 22)

            if isPlanReady {
                planCard
                    .padding(.top, 26)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, OogoMetric.margin)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : OogoMotion.soft, value: isPlanReady)
        .animation(OogoMotion.snap, value: revealTicks)
        .task(id: step) {
            guard step == .reveal, revealTicks == 0 else { return }
            for _ in revealLines.indices {
                try? await Task.sleep(for: .milliseconds(480))
                revealTicks += 1
                Haptic.soft(intensity: 0.5)
            }
            try? await Task.sleep(for: .milliseconds(260))
            isPlanReady = true
            Haptic.success()
        }
    }

    private var revealLines: [String] {
        ["count bell…", "pick move…", "set day…"]
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TinyLabel(text: "hooman plan")

            Text(days == 3 ? "hunt · gather · hunt" : "hunt · gather")
                .font(OogoFont.heavy(26))
                .oogoTracking(26)
                .foregroundStyle(OogoColor.ink)
                .padding(.top, 8)

            Text(store.goals.first?.planLine ?? "swing bell. get strong.")
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)
                .padding(.top, 3)

            Rectangle()
                .fill(OogoColor.mist)
                .frame(height: 1)
                .padding(.vertical, 16)

            VStack(spacing: 11) {
                planRow("work day", "\(days) each week")
                planRow("bell", bells.isEmpty ? "one bell" : "\(bells.count) on wall")
                planRow("one work", "about 30 min")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    private func planRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(OogoFont.body)
                .foregroundStyle(OogoColor.secondaryText)
            Spacer(minLength: 8)
            Text(value)
                .font(OogoFont.bold(17))
                .monospacedDigit()
                .foregroundStyle(OogoColor.ink)
        }
    }

    private var finalName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces).lowercased()
        return trimmed.isEmpty ? "hooman" : trimmed
    }

    // MARK: - Flow

    /// Hooman held the stone. Remember it, then hand over to the price.
    private func sealCommit() {
        store.hasCommitted = true
        showPaywall = true
    }

    private func goNext() {
        isNamingFocused = false
        guard canAdvance else { return }

        // Hooman already known to oog walks straight past the wall. So does every
        // hooman when this build has no sign-in to offer.
        if step == .welcome, auth.isSignedIn || !auth.isConfigured {
            skip(to: .name)
            return
        }
        if step == .name { store.hoomanName = finalName }
        if step == .bells {
            store.weightUnit = unit
            store.setOwnedBells(bells)
        }
        if step == .days {
            store.daysPerWeek = days
            store.applyGoalsToRest()
        }
        if step == .time {
            store.nudgeTime = nudgeTime
        }
        if step == .nudge {
            askNudge()
            return
        }
        // Commitment happens once. Hooman who already held the stone walks past it.
        if step == .reveal, store.hasCommitted {
            showPaywall = true
            return
        }
        advance()
    }

    private func advance() {
        isGoingBack = false
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : OogoMotion.soft) {
            step = step.next ?? step
        }
    }

    private func goBack() {
        isNamingFocused = false
        // Once signed in the wall is done with. Stepping back skips it.
        if step == .name, auth.isSignedIn || !auth.isConfigured {
            isGoingBack = true
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : OogoMotion.soft) {
                step = .welcome
            }
            return
        }
        isGoingBack = true
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : OogoMotion.soft) {
            step = step.back ?? step
        }
    }

    private func skip(to destination: OnboardingStep) {
        isGoingBack = false
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : OogoMotion.soft) {
            step = destination
        }
    }

    /// Sign-in landed. A hooman oog already knows keeps their old plan and walks
    /// straight in; a new one goes on to the questions.
    private func handleSignedIn(isReturning: Bool) {
        guard isReturning else {
            advance()
            return
        }
        if store.isMember {
            finish()
        } else {
            showPaywall = true
        }
    }

    private func finish() {
        store.hasOnboarded = true
        showPaywall = false
        // First answers go up now, so a new phone finds them waiting.
        Task { await sync.pushPlan() }
        onDone()
    }
}

// MARK: - Step scaffold

/// One question, one grey line, then the choices. Same bones on every step.
private struct StepScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(OogoFont.heavy(32))
                    .oogoTracking(32)
                    .foregroundStyle(OogoColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)

                Text(subtitle)
                    .font(OogoFont.subtitle)
                    .foregroundStyle(OogoColor.secondaryText)
                    .padding(.top, 6)
                    .padding(.bottom, 22)

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, OogoMetric.margin)
            .padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Mascot

/// Oog himself. Only ever shown when he says hello.
struct OogMascot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating: Bool = false

    var body: some View {
        Image("OogWave")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 320)
            .offset(y: isFloating ? -6 : 0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: isFloating)
            .accessibilityLabel("oog waving")
            .onAppear { isFloating = true }
    }
}

// MARK: - Pickable pieces

private struct ChoiceRow: View {
    let label: String
    var hint: String?
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.select()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(OogoFont.bold(17.5))
                        .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                    if let hint {
                        Text(hint)
                            .font(OogoFont.regular(12.5))
                            .foregroundStyle(isSelected ? Color.white.opacity(0.6) : OogoColor.secondaryText)
                    }
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
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

private struct ChoiceTile: View {
    let label: String
    var hint: String?
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.select()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(isSelected ? OogoColor.red : OogoColor.ink)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(OogoFont.bold(16))
                        .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let hint {
                        Text(hint)
                            .font(OogoFont.regular(12.5))
                            .foregroundStyle(isSelected ? Color.white.opacity(0.6) : OogoColor.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 104)
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
        .buttonStyle(OogoPressStyle(scale: 0.97))
    }
}

private struct BellTile: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(OogoFont.bold(17))
                .monospacedDigit()
                .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
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
        .buttonStyle(OogoPressStyle(scale: 0.95))
    }
}

/// Hours most hoomans train at, so the wheel stays optional.
private enum NudgePreset: String, CaseIterable, Identifiable {
    case sunUp
    case midday
    case sunDown

    var id: String { rawValue }

    var hour: Int {
        switch self {
        case .sunUp: return 7
        case .midday: return 12
        case .sunDown: return 18
        }
    }

    var label: String {
        switch self {
        case .sunUp: return "sun up"
        case .midday: return "midday"
        case .sunDown: return "sun down"
        }
    }

    var detail: String {
        switch self {
        case .sunUp: return "7:00"
        case .midday: return "12:00"
        case .sunDown: return "18:00"
        }
    }

    var symbol: String {
        switch self {
        case .sunUp: return "sunrise"
        case .midday: return "sun.max"
        case .sunDown: return "sunset"
        }
    }
}

private struct PresetTile: View {
    let label: String
    let symbol: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isSelected ? OogoColor.red : OogoColor.ink)
                Text(label)
                    .font(OogoFont.semibold(14))
                    .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(detail)
                    .font(OogoFont.regular(12.5))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white.opacity(0.65) : OogoColor.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
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
        .buttonStyle(OogoPressStyle(scale: 0.96))
    }
}

private struct DayCountTile: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(count)")
                    .font(OogoFont.number(34))
                    .foregroundStyle(isSelected ? Color.white : OogoColor.ink)
                Text("day")
                    .font(OogoFont.medium(13))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.7) : OogoColor.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
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
        .buttonStyle(OogoPressStyle(scale: 0.96))
    }
}

/// Live week made of the chosen day count, so the choice is felt.
private struct WeekStrip: View {
    let daysPerWeek: Int

    private var week: [(letter: String, type: DayType)] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: Date())
        let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let letters = ["m", "t", "w", "t", "f", "s", "s"]
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return (letters[offset], OogoStore.dayType(for: date, daysPerWeek: daysPerWeek))
        }
    }

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 7) {
                    Text(day.letter)
                        .font(OogoFont.semibold(12))
                        .foregroundStyle(OogoColor.secondaryText)
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(fill(day.type))
                        .frame(height: 52)
                        .overlay {
                            Text(mark(day.type))
                                .font(OogoFont.semibold(11))
                                .foregroundStyle(day.type == .feast ? OogoColor.secondaryText : Color.white)
                        }
                }
            }
        }
        .animation(OogoMotion.snap, value: daysPerWeek)
    }

    private func fill(_ type: DayType) -> Color {
        switch type {
        case .hunt: return OogoColor.ink
        case .gather: return OogoColor.red
        case .feast: return OogoColor.cloud
        }
    }

    private func mark(_ type: DayType) -> String {
        switch type {
        case .hunt: return "h"
        case .gather: return "g"
        case .feast: return "rest"
        }
    }
}
