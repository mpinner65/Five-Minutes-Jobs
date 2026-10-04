import SwiftUI

struct ContentView: View {

    var body: some View {

        TabView {

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
        }
    }
}

// MARK: - Preview

#Preview {     
    ContentView()
}
