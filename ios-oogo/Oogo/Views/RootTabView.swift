//
//  RootTabView.swift
//  Oogo
//
//  Floating bottom navigation: Camp / Train / Method / Profile.
//

import SwiftUI

enum OogoTab: String, CaseIterable, Identifiable {
    case camp
    case train
    case method
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .camp: return "camp"
        case .train: return "build"
        case .method: return "way"
        case .profile: return "hooman"
        }
    }

    var symbol: String {
        switch self {
        case .camp: return "tent"
        case .train: return "dumbbell"
        case .method: return "book"
        case .profile: return "person"
        }
    }

    var selectedSymbol: String {
        switch self {
        case .camp: return "tent.fill"
        case .train: return "dumbbell.fill"
        case .method: return "book.fill"
        case .profile: return "person.fill"
        }
    }
}

struct RootTabView: View {
    @Environment(OogoStore.self) private var store

    @Environment(\.scenePhase) private var scenePhase

    @State private var tab: OogoTab = .camp
    @State private var trainDay: DayType = .gather
    /// The calendar day `trainDay` was last synced for.
    @State private var trainDayAnchor: Date = .distantPast
    @State private var activeSession: ActiveSession?
    @State private var showPaywall: Bool = false
    @State private var showNotes: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            OogoColor.page.ignoresSafeArea()

            Group {
                switch tab {
                case .camp:
                    CampView(
                        onStart: startToday,
                        onResume: { snapshot in activeSession = store.session(resuming: snapshot) },
                        onBell: { showNotes = true }
                    )
                case .train:
                    TrainView(day: $trainDay, onStart: startSession, onBell: { showNotes = true })
                case .method:
                    MethodView(onBell: { showNotes = true })
                case .profile:
                    ProfileView(onUpgrade: { showPaywall = true }, onBell: { showNotes = true })
                }
            }
            .transition(.opacity)

            OogoBottomNav(selection: $tab)
        }
        .fullScreenCover(item: $activeSession) { session in
            SessionFlowView(session: session)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showNotes) {
            NotesSheet()
        }
        .onAppear {
            syncTrainDay(force: true)
            NudgeInbox.shared.onOpenWork = {
                syncTrainDay(force: true)
                withAnimation(OogoMotion.soft) { tab = .train }
            }
        }
        .onChange(of: tab) { _, newTab in
            if newTab == .train { syncTrainDay() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { syncTrainDay() }
        }
        .onChange(of: store.daysPerWeek) { _, _ in syncTrainDay(force: true) }
    }

    /// Build tab always opens on whatever today is. Hooman can still switch by hand,
    /// and that choice sticks until the calendar rolls over.
    private func syncTrainDay(force: Bool = false) {
        let today = Calendar.current.startOfDay(for: Date())
        guard force || today != trainDayAnchor else { return }
        trainDayAnchor = today
        trainDay = store.todayDayType
    }

    private func startToday() {
        startSession(store.todayDayType)
    }

    /// Rest days run the short loose-work pair; work days run the full plan.
    private func startSession(_ day: DayType) {
        let isRest = day == .feast
        activeSession = ActiveSession(
            dayType: day,
            movements: store.movements(for: day),
            rounds: isRest ? 2 : store.rounds,
            restSeconds: store.restSeconds
        )
    }
}

// MARK: - Bottom navigation

struct OogoBottomNav: View {
    @Binding var selection: OogoTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(OogoTab.allCases) { tab in
                Button {
                    guard selection != tab else { return }
                    Haptic.select()
                    withAnimation(OogoMotion.soft) { selection = tab }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: selection == tab ? tab.selectedSymbol : tab.symbol)
                            .font(.system(size: 22, weight: selection == tab ? .medium : .regular))
                            .foregroundStyle(selection == tab ? OogoColor.ink : OogoColor.secondaryText.opacity(0.6))
                            .frame(height: 26)
                            .symbolEffect(.bounce, value: selection == tab)
                            .scaleEffect(selection == tab ? 1.04 : 1)
                        Text(tab.title)
                            .font(selection == tab ? OogoFont.semibold(12.5) : OogoFont.medium(12.5))
                            .foregroundStyle(selection == tab ? OogoColor.ink : OogoColor.secondaryText.opacity(0.8))
                        RedDot(size: 5)
                            .opacity(selection == tab ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .contentShape(.rect)
                }
                .buttonStyle(OogoPressStyle(scale: 0.93))
                .accessibilityLabel(tab.title)
            }
        }
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: OogoRadius.nav, style: .continuous)
                .fill(OogoColor.paper)
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)
                .overlay {
                    RoundedRectangle(cornerRadius: OogoRadius.nav, style: .continuous)
                        .strokeBorder(OogoColor.mist, lineWidth: 1)
                }
        }
        .padding(.horizontal, 14)
    }
}

// MARK: - Notes

/// Quiet nudges built from real state. No chatter.
struct NotesSheet: View {
    @Environment(OogoStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var notes: [(String, String)] {
        var items: [(String, String)] = []
        let today = store.todayDayType

        if let climbed = store.rankNote {
            items.append(("hooman now \(climbed).", "\(store.workCount) work on wall. \(store.rankDetail)"))
        }
        if today == .feast {
            if let next = store.nextTrainingDay {
                items.append(("rest day. body build now.", "loose work still count. next work \(next.type.shortName.lowercased()) on \(next.date.formatted(.dateTime.weekday(.wide)).lowercased())."))
            }
        } else if store.didTrainToday {
            items.append(("work done today.", "eat. sleep. come back."))
        } else {
            items.append(("\(today.title.lowercased()) wait.", "\(store.rounds) round. \(store.bellText)."))
        }

        if store.workThisWeek < store.weekTarget {
            let left = store.weekTarget - store.workThisWeek
            items.append(("\(left) work left this week.", "\(store.workThisWeek) of \(store.weekTarget) done."))
        } else {
            items.append(("week done.", "oog proud of hooman."))
        }

        if store.streak >= 3 {
            items.append(("\(store.streak) work in row.", "keep go. no stop."))
        }
        if store.shouldSuggestHeavierBell, let next = store.nextBellUp {
            items.append(("bell feel light.", "try \(store.weightText(next)). one thing only."))
        }
        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("oog say")
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
                VStack(spacing: 10) {
                    ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                        HStack(alignment: .top, spacing: 14) {
                            RedDot(size: 6)
                                .padding(.top, 7)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(note.0)
                                    .font(OogoFont.bold(17.5))
                                    .foregroundStyle(OogoColor.ink)
                                Text(note.1)
                                    .font(OogoFont.caption)
                                    .foregroundStyle(OogoColor.secondaryText)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .oogoCard(radius: OogoRadius.smallCard)
                    }
                }
                .padding(.horizontal, OogoMetric.margin)
                .padding(.bottom, 30)
            }
        }
        .background(OogoColor.page)
        .presentationDetents([.height(340), .large])
        .presentationContentInteraction(.scrolls)
    }
}
