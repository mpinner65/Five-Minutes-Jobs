import SwiftUI
import SwiftData

struct ContentView: View {

    @Query private var jobs: [Job]
    @State private var linkedJob: Job?
    @State private var selectedTab = 0

    var body: some View {

        TabView(selection: $selectedTab) {

            // MARK: - Today

            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label(
                    "Today",
                    systemImage: "bolt.fill"
                )
            }

            .tag(0)

            // MARK: - Jobs

            NavigationStack {
                JobsView()
            }
            .tabItem {
                Label(
                    "Jobs",
                    systemImage: "checklist"
                )
            }

            .tag(1)

            // MARK: - Progress

            NavigationStack {
                JobProgressView()
            }
            .tabItem {
                Label(
                    "Progress",
                    systemImage: "chart.bar.fill"
                )
            }

            .tag(2)

            // MARK: - Settings

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(
                    "Settings",
                    systemImage: "gearshape.fill"
                )
            }
            .tag(3)
        }
        .background { WidgetSnapshotPublisher() }
        .onOpenURL { url in
            guard url.scheme == "fiveminutejobs" else { return }
            selectedTab = 0
            if url.host == "job", let id = UUID(uuidString: url.lastPathComponent) {
                linkedJob = jobs.first { $0.featureID == id && !$0.isArchived && $0.isAvailable }
            }
        }
        .sheet(item: $linkedJob) { job in
            NavigationStack {
                JobDetailView(job: job)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { linkedJob = nil } } }
            }
        }
    }
}

// MARK: - Preview

#Preview {     
    ContentView()
}
