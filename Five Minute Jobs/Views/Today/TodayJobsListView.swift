import SwiftUI
import SwiftData

// The list reads live models, so completing or archiving a job updates the sheet.
enum TodayJobListKind {
    case ready
    case overdue

    var title: String { self == .ready ? "Ready Jobs" : "Overdue Jobs" }
}

struct TodayJobsListView: View {
    let kind: TodayJobListKind

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Job.createdAt, order: .reverse) private var jobs: [Job]
    @AppStorage("disabledJobCategories") private var disabledCategoriesData = ""

    private var visibleJobs: [Job] {
        let disabled = Set(disabledCategoriesData.split(separator: "|").map(String.init))
        return jobs.filter { job in
            job.isAvailable && !job.isArchived && !disabled.contains(job.category)
                && (kind == .overdue ? job.isOverdue : !job.isOverdue)
        }.sorted { lhs, rhs in
            if kind == .overdue, lhs.daysOverdue != rhs.daysOverdue {
                return lhs.daysOverdue > rhs.daysOverdue
            }
            if lhs.isFavourite != rhs.isFavourite { return lhs.isFavourite }
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return lhs.createdAt > rhs.createdAt
        }
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                let currentJobs = visibleJobs
                Group {
                    if currentJobs.isEmpty {
                        ContentUnavailableView(
                            kind == .overdue ? "Nothing Overdue" : "No Ready Jobs",
                            systemImage: "checkmark.circle",
                            description: Text(kind == .overdue
                                ? "You're caught up. Jobs in enabled categories that become overdue will appear here."
                                : "No jobs in enabled categories are ready without being overdue. Check the Overdue list or wait until a repeating job is due.")
                        )
                    } else {
                        List {
                            Section {
                                ForEach(currentJobs) { job in
                                    NavigationLink { JobDetailView(job: job) } label: {
                                        jobRow(job)
                                    }
                                }
                            } header: {
                                Text(currentJobs.count == 1 ? "1 Job" : "\(currentJobs.count) Jobs")
                                    .textCase(nil)
                            }
                        }
                    }
                }
            }
            .navigationTitle(kind.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func jobRow(_ job: Job) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(job.title).font(.headline)
                if job.isFavourite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Favourite")
                }
                Spacer()
                Label(job.isOverdue ? "OVERDUE" : "READY",
                      systemImage: job.isOverdue ? "exclamationmark.circle.fill" : "bolt.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(job.isOverdue ? Color.red : Color.green)
            }
            CategoryBadge(categoryName: job.category)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { metadata(job) }
                VStack(alignment: .leading, spacing: 5) { metadata(job) }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if job.isOverdue {
                Text(job.daysOverdue == 1 ? "1 day overdue" : "\(job.daysOverdue) days overdue")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func metadata(_ job: Job) -> some View {
        Group {
            Label("\(job.estimatedMinutes) min", systemImage: "clock")
            Label(job.repeatRule.rawValue, systemImage: job.repeatRule.icon)
        }
    }
}

#Preview {
    TodayJobsListView(kind: .ready)
        .modelContainer(for: [Job.self, JobCompletion.self], inMemory: true)
}
