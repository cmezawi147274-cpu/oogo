//
//  OogoSync.swift
//  Oogo
//
//  Carries the cave wall between phones. Union merge, never destructive.
//

import Foundation
import Observation
import Supabase

/// Where the last sync got to, so the hooman page can say something true.
enum SyncState: Equatable {
    case idle
    case working
    case done(Date)
    case failed(String)
}

@Observable
final class OogoSync {
    private let store: OogoStore
    private let auth: AuthManager

    private(set) var state: SyncState = .idle
    /// Guards against two syncs running at once (sign-in + foreground together).
    private var isRunning: Bool = false

    /// True once a sync has found a plan already waiting in the sky, meaning
    /// oog has met this hooman before and need not ask the questions again.
    private(set) var foundExistingPlan: Bool = false

    /// The sync in flight, so a second caller waits on it instead of skipping.
    private var running: Task<Void, Never>?

    /// A plan push asked for while another carry held the line. One flag however
    /// many times it is asked, drained the moment the line frees up — a plan ask
    /// is never dropped, and the push always reads the newest local plan.
    private var planPushPending: Bool = false

    init(store: OogoStore, auth: AuthManager = .shared) {
        self.store = store
        self.auth = auth
    }

    var lastSynced: Date? {
        if case .done(let date) = state { return date }
        return nil
    }

    /// Short line for the hooman page.
    var caveLine: String {
        switch state {
        case .idle: return auth.isSignedIn ? "wall not carried yet." : "wall live on this phone only."
        case .working: return "oog carry wall…"
        case .done(let date): return "wall safe. last carry \(date.formatted(.dateTime.hour().minute()))."
        case .failed: return "oog drop wall. try again."
        }
    }

    /// Pull the cloud, fold it into the phone, push back whatever the cloud lacks.
    /// Callers that arrive mid-sync wait for the one already running rather than
    /// walking away — the sign-in wall needs a real answer, not an early return.
    func sync() async {
        if let running {
            await running.value
            // A caller that only waited still has to check the queue: the sync it
            // waited on may have been asked for a plan carry while it worked.
            await drainPendingPlanPush()
            return
        }
        guard auth.user != nil, !isRunning else { return }

        // Clearing the handle and draining the queue both live INSIDE the task.
        // sync() is called from a .task view modifier, which SwiftUI cancels when
        // the view goes away — anything written after `await task.value` below
        // would simply never run, parking a queued plan ask for good.
        let task = Task {
            await performSync()
            running = nil
            await drainPendingPlanPush()
        }
        running = task
        await task.value
    }

    private func performSync() async {
        guard let user = auth.user else { return }
        isRunning = true
        state = .working
        defer { isRunning = false }

        do {
            try await upsertProfile(user)
            try await syncSessions(userId: user.id)
            try await syncPlan(userId: user.id)
            try await syncMembership(userId: user.id)
            state = .done(Date())
        } catch {
            print("[OogoSync] sync failed: \(error)")
            state = .failed(error.localizedDescription)
        }
    }

    /// Push only — used after finishing work so the wall is current straight away.
    func pushWork() async {
        guard let user = auth.user, !isRunning else { return }
        isRunning = true

        do {
            try await syncSessions(userId: user.id)
            state = .done(Date())
        } catch {
            print("[OogoSync] push work failed: \(error)")
        }

        isRunning = false
        await drainPendingPlanPush()
    }

    /// Push membership the moment the hooman pays, so it follows them everywhere.
    func pushMembership() async {
        guard let user = auth.user, store.isMember, !isRunning else { return }
        isRunning = true

        do {
            try await Backend.client
                .from("membership")
                .upsert(
                    MembershipUpsert(
                        userId: user.id,
                        isMember: true,
                        memberSince: store.memberSince,
                        updatedAt: Date()
                    )
                )
                .execute()
        } catch {
            print("[OogoSync] push membership failed: \(error)")
        }

        isRunning = false
        await drainPendingPlanPush()
    }

    /// Push the plan after the hooman changes kit or days.
    /// Arriving mid-carry no longer means walking away: the ask is remembered and
    /// run the moment the line frees up, so onboarding answers always land.
    func pushPlan() async {
        guard auth.user != nil else {
            print("[OogoSync] plan ask ignored: no hooman signed in")
            return
        }
        guard !isRunning else {
            planPushPending = true
            print("[OogoSync] plan ask queued behind running carry")
            return
        }
        await runPlanPush()
    }

    /// Writes the plan as it stands on the phone right now.
    private func runPlanPush() async {
        guard let user = auth.user else { return }
        isRunning = true
        // Serviced from here: a fresh ask arriving mid-push sets the flag again.
        planPushPending = false
        var dropped = false

        do {
            try await uploadPlan(userId: user.id)
        } catch {
            print("[OogoSync] push plan failed: \(error)")
            dropped = true
        }

        isRunning = false

        // The sky refused. Keep the ask alive for the next carry rather than
        // spinning on a line that is already failing, and say so on the hooman
        // page instead of failing quietly.
        guard !dropped else {
            planPushPending = true
            state = .failed("oog drop plan. try again.")
            return
        }

        state = .done(Date())
        await drainPendingPlanPush()
    }

    /// Runs a plan push that was asked for while the line was busy. Reads the
    /// plan fresh, so the newest local state is what lands.
    private func drainPendingPlanPush() async {
        guard planPushPending, auth.user != nil, !isRunning else { return }
        print("[OogoSync] draining queued plan ask")
        await runPlanPush()
    }

    /// Removes the hooman from the sky, then from this phone, then signs them out.
    /// Cloud goes first: once the token is gone the rows are unreachable.
    /// Returns false when the sky refused, so nothing local is touched.
    func deleteAccount() async -> Bool {
        guard let user = auth.user else { return false }
        isRunning = true
        state = .working
        defer { isRunning = false }

        do {
            try await Backend.client
                .from("work_sessions")
                .delete()
                .eq("user_id", value: user.id)
                .execute()

            try await Backend.client
                .from("hooman_plan")
                .delete()
                .eq("user_id", value: user.id)
                .execute()

            try await Backend.client
                .from("membership")
                .delete()
                .eq("user_id", value: user.id)
                .execute()

            try await Backend.client
                .from("profiles")
                .delete()
                .eq("id", value: user.id)
                .execute()
        } catch {
            print("[OogoSync] delete account failed: \(error)")
            state = .failed("oog cannot forget hooman. try again.")
            return false
        }

        store.wipeEverything()
        await auth.signOut()
        foundExistingPlan = false
        // Nothing left to carry up — a queued ask must not rebuild the rows
        // that were just forgotten.
        planPushPending = false
        state = .idle
        return true
    }

    // MARK: - Pieces

    private func upsertProfile(_ user: AuthManager.User) async throws {
        try await Backend.client
            .from("profiles")
            .upsert(
                ProfileUpsert(
                    id: user.id,
                    email: user.email,
                    name: user.name,
                    avatarUrl: user.picture
                )
            )
            .execute()
    }

    private func syncSessions(userId: String) async throws {
        let remote: [WorkSessionRow] = try await Backend.client
            .from("work_sessions")
            .select("client_id,performed_at,day_type,movement_names,rounds,bell_weight,duration_seconds,feel,is_seed")
            .eq("user_id", value: userId)
            .execute()
            .value

        let unpushed = store.mergeRemoteSessions(remote.map(\.log))

        // Painted starting history is decoration on this phone only. It counts
        // for no rank and never leaves the device.
        let realWork = unpushed.filter { $0.isSeed != true }
        guard !realWork.isEmpty else { return }

        let rows = realWork.map { WorkSessionInsert(userId: userId, log: $0) }
        try await Backend.client
            .from("work_sessions")
            .upsert(rows, onConflict: "user_id,client_id")
            .execute()
    }

    private func syncPlan(userId: String) async throws {
        let remote: [PlanRow] = try await Backend.client
            .from("hooman_plan")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        // A known hooman on a new phone takes the cloud's plan. A new hooman
        // writes theirs up for the first time.
        foundExistingPlan = remote.first != nil

        guard let plan = remote.first else {
            try await uploadPlan(userId: userId)
            return
        }

        // Taking the sky's plan happens once per phone. After that the plan on
        // this phone is the truth: a routine carry must never paint older cloud
        // values back over days, goals or kit the hooman just changed here.
        guard !store.hasAdoptedCloudPlan else {
            print("[OogoSync] plan already settled on this phone — keeping local")
            return
        }

        store.applyRemotePlan(
            hoomanName: plan.hoomanName,
            rounds: plan.rounds,
            bellWeight: plan.bellWeight,
            restSeconds: plan.restSeconds,
            daysPerWeek: plan.daysPerWeek,
            weightUnit: plan.weightUnit,
            ownedBells: plan.ownedBells,
            gear: plan.gear,
            goals: plan.goals,
            selections: plan.selections,
            repOverrides: plan.repOverrides,
            remindersOn: plan.remindersOn,
            nudgeHour: plan.nudgeHour,
            nudgeMinute: plan.nudgeMinute,
            hasCommitted: plan.hasCommitted
        )
        store.markCloudPlanAdopted()
    }

    private func uploadPlan(userId: String) async throws {
        let fields = store.planFields
        try await Backend.client
            .from("hooman_plan")
            .upsert(
                PlanUpsert(
                    userId: userId,
                    hoomanName: fields.name,
                    rounds: fields.rounds,
                    bellWeight: fields.bell,
                    restSeconds: fields.rest,
                    daysPerWeek: fields.days,
                    weightUnit: fields.unit,
                    ownedBells: fields.bells,
                    gear: fields.gear,
                    goals: fields.goals,
                    selections: fields.selections,
                    repOverrides: fields.reps,
                    remindersOn: fields.reminders,
                    nudgeHour: fields.hour,
                    nudgeMinute: fields.minute,
                    hasCommitted: fields.committed,
                    updatedAt: Date()
                )
            )
            .execute()

        // The sky took this phone's plan, so this phone owns it from here on.
        // Only reached when the upsert did not throw.
        store.markCloudPlanAdopted()
    }

    private func syncMembership(userId: String) async throws {
        let remote: [MembershipRow] = try await Backend.client
            .from("membership")
            .select("is_member,plan,member_since")
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        if let membership = remote.first, membership.isMember {
            store.adoptMembership(isMember: true)
            return
        }

        // Cloud does not know this hooman paid yet — tell it.
        guard store.isMember else { return }
        try await Backend.client
            .from("membership")
            .upsert(
                MembershipUpsert(
                    userId: userId,
                    isMember: true,
                    memberSince: store.memberSince,
                    updatedAt: Date()
                )
            )
            .execute()
    }
}
