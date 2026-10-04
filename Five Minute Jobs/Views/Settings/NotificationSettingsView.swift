import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct NotificationSettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Query(sort: \Job.createdAt) private var jobs: [Job]

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 18
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("disabledJobCategories") private var disabledCategoriesData = ""

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isBusy = false
    @State private var needsReminderRefresh = false
    @State private var queuedPermissionRequest = false
    @State private var hasScheduledReminder = false
    @State private var testScheduledAt: Date?
    @State private var notificationError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Daily Reminder", isOn: Binding(
                    get: { notificationsEnabled },
                    set: { enabled in
                        notificationsEnabled = enabled
                        testScheduledAt = nil
                        Task { await updateReminder(requestPermission: enabled) }
                    }
                ))
                .disabled(isBusy)
                if isBusy {
                    ProgressView("Updating notifications…")
                } else {
                    Label(reminderStatusText, systemImage: hasScheduledReminder && notificationPermissionGranted
                          ? "checkmark.circle.fill" : "bell")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: { Text("Reminder") } footer: {
                Text("One reminder each day. Its message uses the available jobs in your enabled categories when the reminder is updated.")
            }

            if notificationsEnabled {
                Section {
                    DatePicker("Time", selection: reminderDateBinding, displayedComponents: .hourAndMinute)
                        .disabled(isBusy)
                } header: { Text("Reminder Time") } footer: {
                    Text("Changes save automatically. If an update fails, the previous reminder may remain scheduled.")
                }
            }

            Section("Notification Access") {
                LabeledContent("Permission", value: authorizationStatusText)
                if authorizationStatus == .denied {
                    Label("Enable notifications for Five Minute Jobs in iPhone Settings.",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                if authorizationStatus == .provisional {
                    Text("Notifications are delivered quietly. You can change their presentation in iPhone Settings.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Open iPhone Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                if notificationsEnabled && authorizationStatus == .notDetermined {
                    Button("Allow Notifications") {
                        Task { await updateReminder(requestPermission: true) }
                    }
                    .disabled(isBusy)
                }
                if notificationsEnabled && notificationPermissionGranted {
                    Button("Retry Reminder Update") {
                        Task { await updateReminder(requestPermission: false) }
                    }
                    .disabled(isBusy)
                }
            }

            if notificationsEnabled && notificationPermissionGranted {
                Section {
                    Button {
                        Task { await sendTestNotification() }
                    } label: {
                        Label("Send Test Notification", systemImage: "bell.badge.fill")
                    }
                    .disabled(isBusy)
                    if let date = testScheduledAt {
                        Label("Test scheduled for \(date.formatted(date: .omitted, time: .shortened)).",
                              systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(.green)
                    }
                } header: { Text("Test") } footer: {
                    Text("After tapping, leave Five Minute Jobs or lock your iPhone. The test is scheduled about 5 seconds later.")
                }
            }
        }
        .navigationTitle("Notifications")
        .task { await updateReminder(requestPermission: false) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await updateReminder(requestPermission: false) } }
        }
        .alert("Couldn't Update Notifications", isPresented: Binding(
            get: { notificationError != nil },
            set: { if !$0 { notificationError = nil } }
        )) {
            Button("OK", role: .cancel) { notificationError = nil }
        } message: {
            Text(notificationError ?? "Please try again.")
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderHour = components.hour ?? 18
            reminderMinute = components.minute ?? 0
            Task { await updateReminder(requestPermission: false) }
        }
    }

    private var notificationPermissionGranted: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private var authorizationStatusText: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Requested"
        case .denied: return "Denied"
        case .authorized: return "Allowed"
        case .provisional: return "Quiet Delivery"
        case .ephemeral: return "Temporary"
        @unknown default: return "Unknown"
        }
    }

    private var reminderStatusText: String {
        if !notificationsEnabled { return "Daily reminder is off." }
        if !notificationPermissionGranted { return "Reminder is enabled but needs notification access." }
        return hasScheduledReminder ? "A daily reminder is scheduled." : "No daily reminder is scheduled. Try updating again."
    }

    private var availableJobs: [Job] {
        let disabled = Set(disabledCategoriesData.split(separator: "|").map(String.init))
        return jobs.filter { $0.isAvailable && !$0.isArchived && !disabled.contains($0.category) }
    }

    @MainActor
    private func updateReminder(requestPermission: Bool) async {
        guard !isBusy else {
            needsReminderRefresh = true
            queuedPermissionRequest = queuedPermissionRequest || requestPermission
            return
        }
        isBusy = true
        defer { finishOperation() }
        let service = NotificationService.shared
        authorizationStatus = await service.authorizationStatus()

        if !notificationsEnabled {
            service.cancelDailyReminder()
            service.cancelTestNotification()
            testScheduledAt = nil
            hasScheduledReminder = await service.hasDailyReminder()
            return
        }

        do {
            // Opening the screen never triggers a permission prompt.
            if requestPermission && authorizationStatus == .notDetermined {
                _ = try await service.requestPermissionChecked()
                authorizationStatus = await service.authorizationStatus()
            }
            guard notificationPermissionGranted else {
                service.cancelDailyReminder()
                service.cancelTestNotification()
                testScheduledAt = nil
                hasScheduledReminder = await service.hasDailyReminder()
                return
            }
            // Check the preference again after waiting for the system prompt.
            guard notificationsEnabled else {
                service.cancelDailyReminder()
                hasScheduledReminder = await service.hasDailyReminder()
                return
            }
            let available = availableJobs
            try await service.scheduleDailyReminderChecked(
                hour: reminderHour, minute: reminderMinute,
                availableJobs: available.count,
                fiveMinuteJobs: available.filter { $0.estimatedMinutes <= 5 }.count
            )
            hasScheduledReminder = await service.hasDailyReminder()
        } catch {
            hasScheduledReminder = await service.hasDailyReminder()
            notificationError = "Your preferences are saved, but the notification update failed. Try again. \(error.localizedDescription)"
        }
    }

    @MainActor
    private func finishOperation() {
        isBusy = false
        if needsReminderRefresh {
            let requestPermission = queuedPermissionRequest
            needsReminderRefresh = false
            queuedPermissionRequest = false
            Task { await updateReminder(requestPermission: requestPermission) }
        }
    }

    @MainActor
    private func sendTestNotification() async {
        guard !isBusy, notificationsEnabled else { return }
        isBusy = true
        defer { finishOperation() }
        testScheduledAt = nil
        let service = NotificationService.shared
        authorizationStatus = await service.authorizationStatus()
        guard notificationPermissionGranted else {
            notificationError = "Notification access is unavailable. Check iPhone Settings and try again."
            return
        }
        do {
            try await service.sendTestNotificationChecked()
            testScheduledAt = .now.addingTimeInterval(5)
        } catch {
            notificationError = "The test could not be scheduled. \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack { NotificationSettingsView() }
        .modelContainer(for: Job.self, inMemory: true)
}
