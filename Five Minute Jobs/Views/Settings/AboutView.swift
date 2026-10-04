import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 14) {
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 54))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                    Text("Five Minute Jobs")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("Turn spare minutes into small wins.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section("About Five Minute Jobs") {
                Text("Make useful progress in the time you have. Choose a few spare minutes, get a job suggestion, and record a small win.")
                    .foregroundStyle(.secondary)
            }

            Section("How It Works") {
                explanationRow("Choose Your Time", icon: "clock",
                               text: "Pick how much time you have. Suggestions come from available jobs that fit that time and your enabled categories.")
                explanationRow("Make It Your Own", icon: "slider.horizontal.3",
                               text: "Add your own jobs, mark favourites, and set priorities to help shape your suggestions.")
                explanationRow("Keep Building Momentum", icon: "chart.bar",
                               text: "Record completed jobs, work towards your daily goal, and follow your history and streaks in Progress.")
            }

            Section {
                explanationRow("One-off Jobs", icon: "1.circle",
                               text: "Completing a one-off job archives it and keeps a record in your completion history.")
                explanationRow("Repeating Jobs", icon: "arrow.clockwise",
                               text: "Repeating jobs become available again after their selected interval, measured from the last completion.")
            } header: {
                Text("Job Completion")
            } footer: {
                Text("Minute totals use each job's estimated time; they are not a record of time tracked.")
            }

            Section("App Information") {
                LabeledContent("Version", value: metadataValue(for: "CFBundleShortVersionString"))
                LabeledContent("Build", value: metadataValue(for: "CFBundleVersion"))
            }
        }
        .navigationTitle("About")
    }

    private func explanationRow(_ title: String, icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }

    private func metadataValue(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Unavailable"
        }
        return value
    }
}

#Preview {
    NavigationStack { AboutView() }
}
