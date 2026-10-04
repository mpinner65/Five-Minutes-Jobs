import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultJobMinutes") private var defaultJobMinutes = 5
    @AppStorage("dailyJobGoal") private var dailyJobGoal = 3
    @AppStorage("disabledJobCategories") private var disabledCategoriesData = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 18
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue

    private var enabledCategoryCount: Int {
        let disabled = Set(disabledCategoriesData.split(separator: "|").map(String.init))
        return JobCategory.allCases.filter { !disabled.contains($0.rawValue) }.count
    }

    private var reminderSummary: String {
        guard notificationsEnabled else { return "Off" }
        let date = Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now)
        return date.map { "On · \($0.formatted(date: .omitted, time: .shortened))" } ?? "On"
    }

    var body: some View {
        List {
            Section {
                NavigationLink { DefaultTimeView() } label: {
                    settingsRow("Default Time", icon: "clock", value: "\(defaultJobMinutes) min")
                }
                NavigationLink { DailyGoalSettingsView() } label: {
                    settingsRow("Daily Goal", icon: "target", value: dailyJobGoal == 1 ? "1 job" : "\(dailyJobGoal) jobs")
                }
                NavigationLink { CategorySettingsView() } label: {
                    settingsRow("Categories", icon: "square.grid.2x2", value: "\(enabledCategoryCount) of \(JobCategory.allCases.count) enabled")
                }
            } header: { Text("Jobs") } footer: {
                Text("Choose your starting time, daily target, and the categories used for job suggestions.")
            }
            Section {
                NavigationLink { NotificationSettingsView() } label: {
                    settingsRow("Notifications", icon: "bell.fill", value: reminderSummary)
                }
            } header: { Text("Reminders") } footer: {
                Text("Reminder delivery also depends on notification access in iPhone Settings.")
            }
            Section("Appearance") {
                NavigationLink { AppearanceSettingsView() } label: {
                    settingsRow("Appearance", icon: "circle.lefthalf.filled",
                                value: AppAppearance(rawValue: appAppearance)?.title ?? "System")
                }
            }
            Section("App") {
                NavigationLink { AboutView() } label: {
                    Label("About Five Minute Jobs", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
    }

    private func settingsRow(_ title: String, icon: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
            Text(value).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

#Preview { NavigationStack { SettingsView() } }
