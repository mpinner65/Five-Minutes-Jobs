import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let dailyReminderIdentifier = "daily-job-reminder"
    private let testNotificationIdentifier = "test-job-notification"
    // Order replacements and cancellation even when the system's add call suspends.
    private var pendingUpdate: Task<Void, Never>?

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestPermissionChecked() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    // Retain the original API for existing app callers.
    func requestPermission() async -> Bool {
        do { return try await requestPermissionChecked() }
        catch { print("Notification permission error: \(error)"); return false }
    }

    func scheduleDailyReminder(hour: Int, minute: Int, availableJobs: Int = 0, fiveMinuteJobs: Int = 0) async {
        do {
            try await scheduleDailyReminderChecked(hour: hour, minute: minute,
                                                  availableJobs: availableJobs, fiveMinuteJobs: fiveMinuteJobs)
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }

    func scheduleDailyReminderChecked(hour: Int, minute: Int, availableJobs: Int = 0, fiveMinuteJobs: Int = 0) async throws {
        guard (0...23).contains(hour), (0...59).contains(minute) else { throw ReminderError.invalidTime }
        let content = UNMutableNotificationContent()
        if availableJobs > 0 {
            content.title = availableJobs == 1 ? "1 job ready" : "\(availableJobs) jobs ready"
            if fiveMinuteJobs > 0 {
                content.body = fiveMinuteJobs == 1
                    ? "You have a five-minute job ready to knock over."
                    : "You have \(fiveMinuteJobs) five-minute jobs ready to knock over."
            } else {
                content.body = "Got a few minutes? Make a little progress."
            }
        } else {
            content.title = "Got a few minutes?"
            content.body = "Check Five Minute Jobs and see what's ready."
        }
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        // Reusing the identifier replaces the pending request only after a successful add.
        try await enqueue(request)
    }

    func cancelDailyReminder() {
        let previous = pendingUpdate
        let identifier = dailyReminderIdentifier
        pendingUpdate = Task {
            await previous?.value
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }

    func sendTestNotification() async {
        do { try await sendTestNotificationChecked() }
        catch { print("Failed to schedule test notification: \(error)") }
    }

    func sendTestNotificationChecked() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Five Minute Jobs"
        content.body = "Your reminders are working. Got five minutes?"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: testNotificationIdentifier, content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        try await enqueue(request)
    }

    func cancelTestNotification() {
        let previous = pendingUpdate
        let identifier = testNotificationIdentifier
        pendingUpdate = Task {
            await previous?.value
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }

    func hasDailyReminder() async -> Bool {
        await pendingUpdate?.value
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
            .contains { $0.identifier == dailyReminderIdentifier }
    }

    private func enqueue(_ request: UNNotificationRequest) async throws {
        let previous = pendingUpdate
        let update = Task { @MainActor in
            await previous?.value
            try await UNUserNotificationCenter.current().add(request)
        }
        pendingUpdate = Task { _ = try? await update.value }
        try await update.value
    }
}

private enum ReminderError: LocalizedError {
    case invalidTime
    var errorDescription: String? { "Choose a valid hour and minute for your reminder." }
}
