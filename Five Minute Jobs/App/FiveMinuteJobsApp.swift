import SwiftUI
import SwiftData

@main
struct FiveMinuteJobsApp: App {

    // MARK: - Appearance

    @AppStorage("appAppearance")
    private var appAppearance =
        AppAppearance.system.rawValue

    // MARK: - Onboarding

    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding =
        false

    // MARK: - Starter Jobs

    @AppStorage("hasLoadedStarterJobs")
    private var hasLoadedStarterJobs =
        false

    // MARK: - SwiftData

    var sharedModelContainer:
        ModelContainer = {

        let schema = Schema([
            Job.self,
            JobCompletion.self
        ])

        let configuration =
            ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

        do {

            return try ModelContainer(
                for: schema,
                configurations: [
                    configuration
                ]
            )

        } catch {

            fatalError(
                "Could not create ModelContainer: \(error)"
            )
        }
    }()

    // MARK: - Body

    var body: some Scene {

        WindowGroup {

            Group {

                if hasCompletedOnboarding {

                    ContentView()

                } else {

                    WelcomeView {

                        withAnimation {
                            hasCompletedOnboarding =
                                true
                        }
                    }
                }
            }
            .preferredColorScheme(
                selectedColorScheme
            )
            .task {
                loadStarterJobsIfNeeded()
            }
        }
        .modelContainer(
            sharedModelContainer
        )
    }

    // MARK: - Starter Jobs

    @MainActor
    private func loadStarterJobsIfNeeded() {

        guard !hasLoadedStarterJobs
        else {
            return
        }

        let context =
            sharedModelContainer
                .mainContext

        StarterJobs.add(
            to: context
        )

        hasLoadedStarterJobs =
            true
    }

    // MARK: - Selected Colour Scheme

    private var selectedColorScheme:
        ColorScheme? {

        let appearance =
            AppAppearance(
                rawValue:
                    appAppearance
            ) ?? .system

        return appearance
            .colorScheme
    }
}
