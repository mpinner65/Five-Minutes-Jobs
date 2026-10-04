import SwiftUI
import SwiftData

struct WelcomeView: View {
    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @AppStorage("hasLoadedStarterJobs") private var hasLoadedStarterJobs = false

    @State private var showingAddJob = false
    @State private var isAddingStarterJobs = false
    @State private var isContinuing = false
    @State private var starterError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: "checklist.checked")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Five Minute Jobs")
                        .font(.largeTitle.bold())
                    Text("Turn spare minutes into small wins.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 22) {
                    featureRow(icon: "clock.fill", title: "Choose Your Time",
                               description: "Start with 5, 10, 15 or 30 minutes. Change it whenever you need.")
                    featureRow(icon: "dice.fill", title: "Find a Useful Job",
                               description: "Get a suggestion that fits your time, or browse your jobs and choose one yourself.")
                    featureRow(icon: "checkmark.circle.fill", title: "Build Momentum",
                               description: "Record small wins, work towards your daily goal and see your progress grow.")
                }

                setupCard
            }
            .frame(maxWidth: 600)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(action: continueToApp) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isAddingStarterJobs || isContinuing)
                Text("You can add jobs and change your preferences anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
        }
        .sheet(isPresented: $showingAddJob) {
            NavigationStack { AddJobView() }
        }
        .alert("Couldn't Add Starter Jobs", isPresented: Binding(
            get: { starterError != nil },
            set: { if !$0 { starterError = nil } }
        )) {
            Button("OK", role: .cancel) { starterError = nil }
        } message: {
            Text(starterError ?? "Please try again.")
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(jobs.isEmpty ? "Start Your Way" : "Your Jobs Are Ready")
                .font(.headline)
            if jobs.isEmpty {
                Text("Use a collection of small starter jobs, add your own, or explore the app first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button(action: addStarterJobs) {
                    Label("Use Starter Jobs", systemImage: "wand.and.stars")
                }
                .buttonStyle(.bordered)
            } else {
                let availableCount = jobs.filter { $0.isAvailable && !$0.isArchived }.count
                Text(availableCount == 1 ? "1 job is available to explore."
                     : availableCount > 0 ? "\(availableCount) jobs are available to explore."
                     : "Your saved jobs are here. Browse them or add something new.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button { showingAddJob = true } label: {
                Label("Add Your Own Job", systemImage: "plus.circle")
            }
            .buttonStyle(.bordered)
            if isAddingStarterJobs { ProgressView("Adding starter jobs…") }
        }
        .disabled(isAddingStarterJobs || isContinuing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    @MainActor
    private func addStarterJobs() {
        guard !isAddingStarterJobs, !isContinuing else { return }
        isAddingStarterJobs = true
        defer { isAddingStarterJobs = false }
        do {
            _ = try StarterJobs.addChecked(to: modelContext)
            hasLoadedStarterJobs = true
            continueToApp()
        } catch {
            starterError = "Your starter jobs could not be saved. You can try again or add your own job. \(error.localizedDescription)"
        }
    }

    private func continueToApp() {
        guard !isContinuing else { return }
        isContinuing = true
        onContinue()
    }
}

#Preview {
    WelcomeView { }
        .modelContainer(for: [Job.self, JobCompletion.self], inMemory: true)
}
