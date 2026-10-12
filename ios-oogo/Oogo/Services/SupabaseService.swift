//
//  SupabaseService.swift
//  Oogo
//
//  Supabase client plus the row shapes oogo keeps in the cloud.
//

import Foundation
import Supabase

/// Shared Supabase client. Signed-out reads run as `anon`; signed-in requests
/// carry the Rork Auth JWT so RLS can match on `user_id()`.
nonisolated enum Backend {
    static let client: SupabaseClient = {
        let url = URL(string: Config.EXPO_PUBLIC_SUPABASE_URL)
            ?? URL(string: "https://unset.supabase.co")!
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.EXPO_PUBLIC_SUPABASE_ANON_KEY,
            options: .init(
                auth: .init(
                    accessToken: {
                        // nil when signed out — never substitute "" or the anon key.
                        AuthToken.currentAccess()
                    }
                )
            )
        )
    }()
}

// MARK: - Profile

nonisolated struct ProfileUpsert: Encodable, Sendable {
    let id: String
    let email: String?
    let name: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Work session

/// One finished work, as it sits in the cloud.
nonisolated struct WorkSessionRow: Codable, Sendable {
    let clientId: UUID
    let performedAt: Date
    let dayType: String
    let movementNames: [String]
    let rounds: Int
    let bellWeight: Int
    let durationSeconds: Int
    let feel: String?
    let isSeed: Bool

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case performedAt = "performed_at"
        case dayType = "day_type"
        case movementNames = "movement_names"
        case rounds
        case bellWeight = "bell_weight"
        case durationSeconds = "duration_seconds"
        case feel
        case isSeed = "is_seed"
    }

    /// Back to the app's own log shape.
    var log: SessionLog {
        SessionLog(
            id: clientId,
            date: performedAt,
            dayType: DayType(rawValue: dayType) ?? .hunt,
            movementNames: movementNames,
            rounds: rounds,
            bellWeight: bellWeight,
            durationSeconds: durationSeconds,
            feel: feel ?? SessionFeel.good.rawValue,
            isSeed: isSeed ? true : nil
        )
    }
}

/// Insert shape — carries the owner so RLS can check it.
nonisolated struct WorkSessionInsert: Encodable, Sendable {
    let userId: String
    let clientId: UUID
    let performedAt: Date
    let dayType: String
    let movementNames: [String]
    let rounds: Int
    let bellWeight: Int
    let durationSeconds: Int
    let feel: String
    let isSeed: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case clientId = "client_id"
        case performedAt = "performed_at"
        case dayType = "day_type"
        case movementNames = "movement_names"
        case rounds
        case bellWeight = "bell_weight"
        case durationSeconds = "duration_seconds"
        case feel
        case isSeed = "is_seed"
    }

    nonisolated init(userId: String, log: SessionLog) {
        self.userId = userId
        clientId = log.id
        performedAt = log.date
        dayType = log.dayType.rawValue
        movementNames = log.movementNames
        rounds = log.rounds
        bellWeight = log.bellWeight
        durationSeconds = log.durationSeconds
        feel = log.feel
        isSeed = log.isSeed == true
    }
}

// MARK: - Plan and kit

nonisolated struct PlanRow: Codable, Sendable {
    let hoomanName: String?
    let rounds: Int
    let bellWeight: Int
    let restSeconds: Int
    let daysPerWeek: Int
    let weightUnit: String
    let ownedBells: [Int]
    let gear: [String]
    let goals: [String]
    let selections: [String: String]
    let repOverrides: [String: Int]
    let remindersOn: Bool
    let nudgeHour: Int
    let nudgeMinute: Int
    let hasCommitted: Bool

    enum CodingKeys: String, CodingKey {
        case hoomanName = "hooman_name"
        case rounds
        case bellWeight = "bell_weight"
        case restSeconds = "rest_seconds"
        case daysPerWeek = "days_per_week"
        case weightUnit = "weight_unit"
        case ownedBells = "owned_bells"
        case gear
        case goals
        case selections
        case repOverrides = "rep_overrides"
        case remindersOn = "reminders_on"
        case nudgeHour = "nudge_hour"
        case nudgeMinute = "nudge_minute"
        case hasCommitted = "has_committed"
    }
}

nonisolated struct PlanUpsert: Encodable, Sendable {
    let userId: String
    let hoomanName: String
    let rounds: Int
    let bellWeight: Int
    let restSeconds: Int
    let daysPerWeek: Int
    let weightUnit: String
    let ownedBells: [Int]
    let gear: [String]
    let goals: [String]
    let selections: [String: String]
    let repOverrides: [String: Int]
    let remindersOn: Bool
    let nudgeHour: Int
    let nudgeMinute: Int
    let hasCommitted: Bool
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case hoomanName = "hooman_name"
        case rounds
        case bellWeight = "bell_weight"
        case restSeconds = "rest_seconds"
        case daysPerWeek = "days_per_week"
        case weightUnit = "weight_unit"
        case ownedBells = "owned_bells"
        case gear
        case goals
        case selections
        case repOverrides = "rep_overrides"
        case remindersOn = "reminders_on"
        case nudgeHour = "nudge_hour"
        case nudgeMinute = "nudge_minute"
        case hasCommitted = "has_committed"
        case updatedAt = "updated_at"
    }
}

// MARK: - Membership

nonisolated struct MembershipRow: Codable, Sendable {
    let isMember: Bool
    let plan: String?
    let memberSince: Date?

    enum CodingKeys: String, CodingKey {
        case isMember = "is_member"
        case plan
        case memberSince = "member_since"
    }
}

nonisolated struct MembershipUpsert: Encodable, Sendable {
    let userId: String
    let isMember: Bool
    let memberSince: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isMember = "is_member"
        case memberSince = "member_since"
        case updatedAt = "updated_at"
    }
}
