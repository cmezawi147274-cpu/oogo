//
//  ProfileView.swift
//  Oogo
//
//  Hooman page: identity, settings, recent logs.
//

import SwiftUI
import UIKit
import UserNotifications

enum ProfileRoute: String, Identifiable {
    case plan
    case equipment
    case notifications
    case units
    case help
    case legal
    case account

    var id: String { rawValue }
}

struct ProfileView: View {
    let onUpgrade: () -> Void
    let onBell: () -> Void

    @Environment(OogoStore.self) private var store
    @State private var route: ProfileRoute?
    @State private var showAllLogs: Bool = false
    @State private var showLadder: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            OogoTopBar(onBell: onBell)

            ScrollView(showsIndicators: false) {
                VStack(spacing: OogoMetric.cardGap) {
                    identityRow
                        .padding(.top, 14)
                        .padding(.bottom, 6)

                    settingsCard
                        .oogoEntrance(appeared, index: 0)

                    logsCard
                        .oogoEntrance(appeared, index: 1)
                }
                .padding(.horizontal, OogoMetric.margin)
                .padding(.bottom, OogoMetric.navClearance)
            }
        }
        .background(OogoColor.page)
        .sheet(item: $route) { route in
            ProfileDetailSheet(route: route)
        }
        .sheet(isPresented: $showAllLogs) {
            SessionLogSheet()
        }
        .sheet(isPresented: $showLadder) {
            RankLadderSheet()
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(OogoMotion.soft.delay(0.04)) { appeared = true }
        }
    }

    // MARK: - Identity

    private var identityRow: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text(initial)
                    .font(OogoFont.heavy(36))
                    .foregroundStyle(OogoColor.ink)
                    .frame(width: 78, height: 78)
                    .background {
                        Circle()
                            .fill(OogoColor.paper)
                            .overlay { Circle().strokeBorder(OogoColor.mist, lineWidth: 1) }
                            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.hoomanName)
                        .font(OogoFont.heavy(30))
                        .oogoTracking(30)
                        .foregroundStyle(OogoColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("in camp since \(store.memberSince.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(OogoFont.caption)
                        .foregroundStyle(OogoColor.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)
            }

            rankHero
        }
    }

    /// Rank sits right under the name. Tap opens the whole ladder.
    private var rankHero: some View {
        Button {
            Haptic.tap()
            showLadder = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TinyLabel(text: "rank")
                    Spacer(minLength: 8)
                    HStack(spacing: 4) {
                        Text("\(store.workCount)")
                            .font(OogoFont.number(15))
                            .foregroundStyle(OogoColor.ink)
                            .contentTransition(.numericText(value: Double(store.workCount)))
                        Text("work")
                            .font(OogoFont.regular(13.5))
                            .foregroundStyle(OogoColor.secondaryText)
                    }
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(store.rank?.display ?? "no rank yet")
                        .font(OogoFont.heavy(26))
                        .oogoTracking(26)
                        .foregroundStyle(store.rank == nil ? OogoColor.secondaryText : OogoColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                    if store.rank != nil {
                        RedDot(size: 6)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(OogoColor.ink.opacity(0.35))
                }

                RankBar(progress: store.rankProgress)

                Text(store.rankDetail)
                    .font(OogoFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(OogoColor.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()
            .contentShape(.rect)
        }
        .buttonStyle(OogoPressStyle(scale: 0.985))
        .accessibilityLabel("rank \(store.rank?.display ?? "none yet"). \(store.rankDetail)")
    }

    private var initial: String {
        String(store.hoomanName.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    // MARK: - Settings

    private var settingsCard: some View {
        VStack(spacing: 0) {
            OogoSettingsRow(systemImage: "calendar", title: "work plan", detail: "\(store.daysPerWeek) day") {
                route = .plan
            }
            OogoSettingsRow(systemImage: "dumbbell", title: "kit", detail: kitDetail) {
                route = .equipment
            }
            OogoSettingsRow(systemImage: "bell", title: "nudge", badge: store.remindersOn) {
                route = .notifications
            }
            OogoSettingsRow(systemImage: "ruler", title: "weight", detail: store.weightUnit.label) {
                route = .units
            }
            OogoSettingsRow(
                systemImage: "creditcard",
                title: "oogo unlimited",
                detail: store.isMember ? "in" : "out"
            ) {
                onUpgrade()
            }
            OogoSettingsRow(systemImage: "questionmark.circle", title: "how oogo work") {
                route = .help
            }
            OogoSettingsRow(systemImage: "checkmark.shield", title: "law words") {
                route = .legal
            }
            OogoSettingsRow(systemImage: "person", title: "hooman", showsDivider: false) {
                route = .account
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 2)
        .oogoCard()
    }

    private var kitDetail: String {
        let bells = store.ownedBells.count
        let extras = store.gear.filter { !$0.isBell }.count
        let bellText = bells == 1 ? "1 bell" : "\(bells) bell"
        return extras > 0 ? "\(bellText) · \(extras) more" : bellText
    }

    // MARK: - Logs

    private var logsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("last work")
                    .font(OogoFont.heading)
                    .oogoTracking(21)
                    .foregroundStyle(OogoColor.ink)
                Spacer()
                Button {
                    Haptic.tap()
                    showAllLogs = true
                } label: {
                    Text("view all")
                        .font(OogoFont.medium(15))
                        .foregroundStyle(OogoColor.secondaryText)
                }
                .buttonStyle(OogoPressStyle(scale: 0.95))
            }

            if store.recentSessions.isEmpty {
                Text("no work yet. wall empty. go fix.")
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
                    .padding(.bottom, 4)
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(store.recentSessions.prefix(2))) { entry in
                        LogRow(entry: entry)
                    }
                }
                .padding(.bottom, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }
}

// MARK: - Detail sheets

struct ProfileDetailSheet: View {
    let route: ProfileRoute

    @Environment(OogoStore.self) private var store
    @Environment(AuthManager.self) private var auth
    @Environment(OogoSync.self) private var sync
    @Environment(\.dismiss) private var dismiss
    @State private var draftName: String = ""
    @State private var confirmClear: Bool = false
    @State private var confirmDelete: Bool = false
    @State private var confirmDeleteForReal: Bool = false
    @State private var isDeleting: Bool = false
    @State private var deleteFailed: Bool = false
    @State private var nudgeStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(OogoFont.heavy(28))
                    .oogoTracking(28)
                    .foregroundStyle(OogoColor.ink)
                Spacer()
                OogoCloseButton { dismiss() }
            }
            .padding(.horizontal, OogoMetric.margin)
            .padding(.top, 22)
            .padding(.bottom, 18)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: OogoMetric.cardGap) {
                    content
                }
                .padding(.horizontal, OogoMetric.margin)
                .padding(.bottom, 34)
            }
        }
        .background(OogoColor.page)
        .presentationDetents([.height(detentHeight), .large])
        .presentationContentInteraction(.scrolls)
        .onAppear { draftName = store.hoomanName }
        .alert("wipe cave wall?", isPresented: $confirmClear) {
            Button("keep", role: .cancel) {}
            Button("wipe", role: .destructive) {
                store.clearHistory()
                Haptic.success()
            }
        }
        .alert("oog forget hooman?", isPresented: $confirmDelete) {
            Button("no, stay", role: .cancel) {}
            Button("go on", role: .destructive) { confirmDeleteForReal = true }
        } message: {
            Text("this end hooman account. not just step out.")
        }
        .alert("sure, hooman?", isPresented: $confirmDeleteForReal) {
            Button("no, stay", role: .cancel) {}
            Button("forget me", role: .destructive) { deleteAccount() }
        } message: {
            Text("every work gone. plan gone. kit gone. oog cannot get back.")
        }
        .alert("oog cannot forget hooman", isPresented: $deleteFailed) {
            Button("fine", role: .cancel) {}
        } message: {
            Text("sky not answer. hooman still here. try again later.")
        }
    }

    private var title: String {
        switch route {
        case .plan: return "work plan"
        case .equipment: return "hooman kit"
        case .notifications: return "nudge"
        case .units: return "weight"
        case .help: return "how oogo work"
        case .legal: return "law words"
        case .account: return "hooman"
        }
    }

    private var detentHeight: CGFloat {
        switch route {
        case .plan: return 420
        case .equipment: return 560
        case .notifications: return 560
        default: return 360
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .plan: planContent
        case .equipment: equipmentContent
        case .notifications: notificationsContent
        case .units: unitsContent
        case .help: helpContent
        case .legal: legalContent
        case .account: accountContent
        }
    }

    // MARK: Plan

    private var planContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("how many day hooman work in week?")
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)

            HStack(spacing: 10) {
                ForEach([3, 4, 5], id: \.self) { plan in
                    OogoChip(title: "\(plan) day", isSelected: store.daysPerWeek == plan) {
                        withAnimation(OogoMotion.snap) { store.daysPerWeek = plan }
                    }
                }
            }

            Text("today \(store.todayDayType.title.lowercased()).")
                .font(OogoFont.body)
                .foregroundStyle(OogoColor.ink)
                .padding(.top, 6)

            if let next = store.nextTrainingDay {
                Text("next work: \(next.type.shortName.lowercased()) on \(next.date.formatted(.dateTime.weekday(.wide)).lowercased()).")
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    // MARK: Equipment

    private var equipmentContent: some View {
        VStack(alignment: .leading, spacing: OogoMetric.cardGap) {
            VStack(alignment: .leading, spacing: 12) {
                Text("tap every bell hooman have.")
                    .font(OogoFont.subtitle)
                    .foregroundStyle(OogoColor.secondaryText)

                LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 4), spacing: 10) {
                    ForEach(OogoStore.bellCatalog, id: \.self) { weight in
                        OogoChip(
                            title: store.weightText(weight),
                            isSelected: store.ownedBells.contains(weight),
                            showsDot: false
                        ) {
                            withAnimation(OogoMotion.snap) { store.toggleBell(weight) }
                        }
                    }
                }

                Text("oog only load work from these bell.")
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
                    .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("hooman have two same size bell?")
                    .font(OogoFont.subtitle)
                    .foregroundStyle(OogoColor.secondaryText)

                HStack(spacing: 10) {
                    ForEach([OogoGear.oneBell, OogoGear.twoBells]) { item in
                        OogoChip(
                            title: item.label,
                            isSelected: (item == .twoBells) == store.hasTwoBells,
                            showsDot: false
                        ) {
                            withAnimation(OogoMotion.snap) { store.toggleGear(item) }
                        }
                    }
                }

                Text("two same bell open double work.")
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)

                Text("what else hooman got?")
                    .font(OogoFont.subtitle)
                    .foregroundStyle(OogoColor.secondaryText)
                    .padding(.top, 10)

                LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2), spacing: 10) {
                    ForEach(OogoGear.allCases.filter { !$0.isBell }) { item in
                        OogoChip(
                            title: item.label,
                            isSelected: store.gear.contains(item),
                            showsDot: false
                        ) {
                            withAnimation(OogoMotion.snap) { store.toggleGear(item) }
                        }
                    }
                }

                Text("no kit, no move. oog hide what hooman cannot do.")
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
                    .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()
        }
    }

    // MARK: Notifications

    private var notificationsContent: some View {
        VStack(alignment: .leading, spacing: OogoMetric.cardGap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("oog nudge hooman")
                            .font(OogoFont.body)
                            .foregroundStyle(OogoColor.ink)
                        Text("one grunt on work day. no more.")
                            .font(OogoFont.caption)
                            .foregroundStyle(OogoColor.secondaryText)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.remindersOn },
                        set: { newValue in
                            Haptic.select()
                            setNudges(on: newValue)
                        }
                    ))
                    .labelsHidden()
                    .tint(OogoColor.ink)
                }
                .padding(.vertical, 4)

                if isNudgeBlocked {
                    Rectangle()
                        .fill(OogoColor.mist)
                        .frame(height: 1)
                        .padding(.vertical, 14)

                    Text("phone keep oog quiet. hooman must open phone setting.")
                        .font(OogoFont.caption)
                        .foregroundStyle(OogoColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Haptic.tap()
                        openPhoneSettings()
                    } label: {
                        Text("open phone setting")
                            .font(OogoFont.medium(15))
                            .foregroundStyle(OogoColor.red)
                            .frame(height: 40)
                            .contentShape(.rect)
                    }
                    .buttonStyle(OogoPressStyle(scale: 0.96))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()

            VStack(alignment: .leading, spacing: 10) {
                Text("when hooman work?")
                    .font(OogoFont.subtitle)
                    .foregroundStyle(OogoColor.secondaryText)

                DatePicker(
                    "",
                    selection: Binding(
                        get: { store.nudgeTime },
                        set: { store.nudgeTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Text(nextShoutLine)
                    .font(OogoFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(OogoColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()
        }
        .task { await refreshNudgeStatus() }
    }

    private var isNudgeBlocked: Bool {
        store.remindersOn && (nudgeStatus == .denied)
    }

    private var nextShoutLine: String {
        guard store.remindersOn else { return "oog quiet. hooman work alone." }
        guard let next = store.nextNudge else { return "no shout ahead. rest day only." }
        let day = next.formatted(.dateTime.weekday(.wide)).lowercased()
        let time = next.formatted(.dateTime.hour().minute())
        return "next shout \(day), \(time)."
    }

    private func setNudges(on newValue: Bool) {
        guard newValue else {
            store.remindersOn = false
            return
        }
        Task {
            let status = await NudgeService.authorizationStatus()
            if status == .notDetermined {
                let granted = await NudgeService.requestPermission()
                store.remindersOn = granted
            } else {
                store.remindersOn = true
            }
            await refreshNudgeStatus()
        }
    }

    private func refreshNudgeStatus() async {
        nudgeStatus = await NudgeService.authorizationStatus()
    }

    private func openPhoneSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Units

    private var unitsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("weight show as")
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.secondaryText)
            HStack(spacing: 10) {
                ForEach(WeightUnit.allCases) { unit in
                    OogoChip(title: unit.label, isSelected: store.weightUnit == unit) {
                        withAnimation(OogoMotion.snap) { store.weightUnit = unit }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    // MARK: Help

    private var helpContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            helpLine("open oogo. see plan. hit start.")
            helpLine("tap move name. see all move. pick one hooman want.")
            helpLine("minus and plus set reps for that move.")
            helpLine("done button move work forward.")
            helpLine("rest day never break streak. rest build hooman.")
            Text("oog@oogo.app")
                .font(OogoFont.medium(16))
                .foregroundStyle(OogoColor.ink)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .oogoCard()
    }

    private func helpLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RedDot(size: 5).padding(.top, 7)
            Text(text)
                .font(OogoFont.subtitle)
                .foregroundStyle(OogoColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Legal

    private var legalContent: some View {
        VStack(spacing: 0) {
            OogoSettingsRow(systemImage: "doc.text", title: "terms") {}
            OogoSettingsRow(systemImage: "lock", title: "privacy", showsDivider: false) {}
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 2)
        .oogoCard()
    }

    // MARK: Account

    private var accountContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            cloudCard

            VStack(alignment: .leading, spacing: 10) {
                TinyLabel(text: "name")
                TextField("hooman", text: $draftName)
                    .font(OogoFont.bold(20))
                    .foregroundStyle(OogoColor.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(saveName)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(OogoColor.cloud)
                    }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()

            OogoPrimaryButton(title: "oog remember", firesHaptic: false) {
                saveName()
                dismiss()
            }

            Button {
                Haptic.tap()
                confirmClear = true
            } label: {
                Text("wipe cave wall")
                    .font(OogoFont.medium(16))
                    .foregroundStyle(OogoColor.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(.rect)
            }
            .buttonStyle(OogoPressStyle(scale: 0.97))

            if auth.isSignedIn {
                endHoomanButton
            }
        }
    }

    /// The real door out. Two asks before anything happens.
    private var endHoomanButton: some View {
        VStack(spacing: 6) {
            Rectangle()
                .fill(OogoColor.mist)
                .frame(height: 1)
                .padding(.bottom, 6)

            Button {
                Haptic.firm()
                confirmDelete = true
            } label: {
                HStack(spacing: 8) {
                    if isDeleting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(OogoColor.red)
                    }
                    Text(isDeleting ? "oog forgetting…" : "oog forget hooman")
                        .font(OogoFont.semibold(16))
                        .foregroundStyle(OogoColor.red)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .contentShape(.rect)
            }
            .buttonStyle(OogoPressStyle(scale: 0.97))
            .disabled(isDeleting)

            Text("end account. work, plan, kit — all gone for good.")
                .font(OogoFont.caption)
                .foregroundStyle(OogoColor.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            let didDelete = await sync.deleteAccount()
            isDeleting = false
            if didDelete {
                Haptic.done()
                dismiss()
            } else {
                Haptic.tick()
                deleteFailed = true
            }
        }
    }

    private func saveName() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.hoomanName = trimmed.isEmpty ? "hooman" : trimmed
        Haptic.success()
        Task { await sync.pushPlan() }
    }

    // MARK: Cloud

    /// Signed out: two ways in. Signed in: who, and whether the wall is safe.
    @ViewBuilder
    private var cloudCard: some View {
        if let user = auth.user {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    TinyLabel(text: "wall keeper")
                    Spacer(minLength: 8)
                    if case .working = sync.state {
                        ProgressView().controlSize(.mini)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(user.name?.lowercased() ?? "hooman")
                        .font(OogoFont.bold(19))
                        .foregroundStyle(OogoColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(user.email)
                        .font(OogoFont.caption)
                        .foregroundStyle(OogoColor.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Text(sync.caveLine)
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 9) {
                    Button {
                        Haptic.firm()
                        Task { await sync.sync() }
                    } label: {
                        Text("carry wall now")
                            .font(OogoFont.semibold(15))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 18)
                            .frame(height: 42)
                            .background { Capsule().fill(OogoColor.ink) }
                            .contentShape(.capsule)
                    }
                    .buttonStyle(OogoPressStyle(scale: 0.94))

                    Button {
                        Haptic.tick()
                        Task { await auth.signOut() }
                    } label: {
                        Text("step out")
                            .font(OogoFont.semibold(15))
                            .foregroundStyle(OogoColor.secondaryText)
                            .padding(.horizontal, 16)
                            .frame(height: 42)
                            .background { Capsule().fill(OogoColor.cloud) }
                            .contentShape(.capsule)
                    }
                    .buttonStyle(OogoPressStyle(scale: 0.94))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()
        } else {
            VStack(alignment: .leading, spacing: 13) {
                TinyLabel(text: "keep wall safe")

                Text("wall live on this phone only.")
                    .font(OogoFont.bold(19))
                    .foregroundStyle(OogoColor.ink)

                Text("hooman sign in, oog carry work to new phone.")
                    .font(OogoFont.caption)
                    .foregroundStyle(OogoColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 9) {
                    signInButton(
                        title: "go in with apple",
                        symbol: "apple.logo",
                        isDark: true,
                        provider: "apple"
                    )
                    signInButton(
                        title: "go in with google",
                        symbol: "g.circle",
                        isDark: false,
                        provider: "google"
                    )
                }
                .padding(.top, 2)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .oogoCard()
        }
    }

    private func signInButton(title: String, symbol: String, isDark: Bool, provider: String) -> some View {
        Button {
            Haptic.firm()
            Task { await auth.signIn(provider: provider) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(OogoFont.bodyStrong)
            }
            .foregroundStyle(isDark ? Color.white : OogoColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                Capsule(style: .continuous)
                    .fill(isDark ? OogoColor.ink : OogoColor.paper)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(isDark ? Color.clear : OogoColor.mist, lineWidth: 1.4)
                    }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(OogoPressStyle(scale: 0.97))
        .disabled(auth.isSigningIn)
        .opacity(auth.isSigningIn ? 0.5 : 1)
    }
}

// MARK: - Rank

/// Thin ink bar showing how far along the current rank the hooman stands.
struct RankBar: View {
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(OogoColor.mist)
                Capsule()
                    .fill(OogoColor.ink)
                    .frame(width: max(4, proxy.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 4)
        .animation(reduceMotion ? .easeInOut(duration: 0.25) : OogoMotion.pop, value: progress)
        .accessibilityHidden(true)
    }
}

/// The whole ladder. Earned ranks in ink, road ahead faded but readable.
struct RankLadderSheet: View {
    @Environment(OogoStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    TinyLabel(text: "\(store.workCount) work done")
                    Text("work ladder")
                        .font(OogoFont.heavy(28))
                        .oogoTracking(28)
                        .foregroundStyle(OogoColor.ink)
                }
                Spacer()
                OogoCloseButton { dismiss() }
            }
            .padding(.horizontal, OogoMetric.margin)
            .padding(.top, 22)
            .padding(.bottom, 14)

            ScrollViewReader { scroller in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(OogoRankBook.ranks) { rank in
                            row(rank)
                                .id(rank.index)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 8)
                                .animation(
                                    reduceMotion
                                        ? .easeOut(duration: 0.2)
                                        : OogoMotion.soft.delay(Double(min(rank.index, 12)) * 0.02),
                                    value: appeared
                                )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 4)
                    .oogoCard()
                    .padding(.horizontal, OogoMetric.margin)
                    .padding(.bottom, 30)
                }
                .onAppear {
                    let target = store.rank?.index ?? 0
                    scroller.scrollTo(target, anchor: .center)
                    appeared = true
                }
            }
        }
        .background(OogoColor.page)
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
    }

    private func row(_ rank: OogoRank) -> some View {
        let isEarned = store.workCount >= rank.works
        let isCurrent = store.rank?.index == rank.index
        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text("\(rank.works)")
                    .font(OogoFont.number(15))
                    .foregroundStyle(isEarned ? OogoColor.ink : OogoColor.secondaryText.opacity(0.55))
                    .frame(width: 44, alignment: .leading)

                Text(rank.display)
                    .font(isCurrent ? OogoFont.heavy(19) : OogoFont.bold(17.5))
                    .foregroundStyle(isEarned ? OogoColor.ink : OogoColor.secondaryText.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 8)

                if isCurrent {
                    HStack(spacing: 6) {
                        RedDot(size: 6)
                        Text("here")
                            .font(OogoFont.semibold(13))
                            .foregroundStyle(OogoColor.red)
                    }
                } else if isEarned {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(OogoColor.ink.opacity(0.35))
                }
            }
            .padding(.vertical, 14)

            if rank.index < OogoRankBook.lastIndex {
                Rectangle()
                    .fill(OogoColor.mist)
                    .frame(height: 1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
