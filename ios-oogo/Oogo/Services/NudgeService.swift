//
//  NudgeService.swift
//  Oogo
//
//  One grunt on work day, at the hour hooman picked. Never on rest day.
//

import Foundation
import UserNotifications

/// Schedules and cancels oog's daily grunt.
enum NudgeService {
    /// How many days ahead oog queues grunts. Refreshed on every launch.
    private static let horizon: Int = 21
    private static let prefix: String = "oogo.nudge."

    /// Oog never grunts the same words two work days running.
    private static let grunts: [String] = [
        "bell wait. hooman move.",
        "body ready. go swing.",
        "no think. pick bell up.",
        "work small. skip worse.",
        "tribe watch. hooman work.",
        "strong hooman start now."
    ]

    /// Asks the hooman once. Returns true when oog may shout.
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Wipes queued grunts and queues fresh ones for every work day ahead.
    static func reschedule(
        isOn: Bool,
        hour: Int,
        minute: Int,
        daysPerWeek: Int,
        hoomanName: String,
        trainedDays: Set<Date>
    ) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)

        guard isOn else { return }
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()

        for offset in 0..<horizon {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let type = OogoStore.dayType(for: day, daysPerWeek: daysPerWeek)
            guard type != .feast else { continue }
            // Work already on the wall: oog stays quiet.
            guard !trainedDays.contains(day) else { continue }
            guard let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(type.shortName.lowercased()) day, \(hoomanName)."
            content.body = offset % 3 == 0 ? type.caveLine : grunts[offset % grunts.count]
            content.sound = .default
            content.userInfo = ["oogo.route": "train"]

            var parts = calendar.dateComponents([.year, .month, .day], from: fireDate)
            parts.hour = hour
            parts.minute = minute

            let request = UNNotificationRequest(
                identifier: "\(prefix)\(offset)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            )
            try? await center.add(request)
        }
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
}

/// Catches taps on oog's grunt so the app can open on today's work.
final class NudgeInbox: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NudgeInbox()

    /// Set by the root view: jumps the hooman to the build tab.
    var onOpenWork: (() -> Void)?

    func register() {
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let isWork = response.notification.request.content.userInfo["oogo.route"] as? String == "train"
        Task { @MainActor in
            if isWork { NudgeInbox.shared.onOpenWork?() }
            completionHandler()
        }
    }
}
