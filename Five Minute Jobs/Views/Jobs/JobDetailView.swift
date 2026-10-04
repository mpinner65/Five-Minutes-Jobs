import SwiftUI
import SwiftData

struct JobDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let job: Job

    @State private var showingEditJob = false
    @State private var activeAlert: DetailAlert?
    @State private var isCompletingJob = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Text(job.title)
                            .font(.title2.bold())
                        Spacer()
                        if job.isFavourite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .accessibilityLabel("Favourite")
                        }
                    }
                    CategoryBadge(categoryName: job.category)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 20) { overviewLabels }
                        VStack(alignment: .leading, spacing: 8) { overviewLabels }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    statusBadge
                }
                .padding(.vertical, 8)
            }

            Section {
                Button(action: completeJob) {
                    Label("Complete Job", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
                .disabled(!job.isAvailable || isCompletingJob)
            } footer: {
                Text(completionExplanation)
            }

            Section("Details") {
                LabeledContent("Time", value: "\(job.estimatedMinutes) minutes")
                LabeledContent("Category", value: job.category)
                LabeledContent("Priority", value: priorityName)
                LabeledContent("Repeat", value: job.repeatRule.rawValue)
            }

            Section("Status") {
                LabeledContent("Availability") { statusBadge }
                LabeledContent("Favourite", value: job.isFavourite ? "Yes" : "No")
                if job.isOverdue {
                    LabeledContent("Overdue") {
                        Text(job.daysOverdue == 1 ? "1 day" : "\(job.daysOverdue) days")
                            .foregroundStyle(.red)
                    }
                }
                if job.repeatRule != .once, let dueDate = job.nextDueDate {
                    LabeledContent("Next Due") {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(dueDescription(dueDate))
                            Text(dueDate, format: .dateTime.day().month().year().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                if let completedAt = job.lastCompletedAt {
                    LabeledContent("Last Completed") {
                        Text(completedAt, format: .dateTime.day().month().year().hour().minute())
                    }
                } else {
                    LabeledContent("Last Completed", value: "Never")
                }
            }

            if !job.notes.isEmpty {
                Section("Notes") { Text(job.notes) }
            }

            Section("Manage Job") {
                Button {
                    showingEditJob = true
                } label: {
                    Label("Edit Job", systemImage: "pencil")
                }
                Button(action: toggleFavourite) {
                    Label(job.isFavourite ? "Remove from Favourites" : "Add to Favourites",
                          systemImage: job.isFavourite ? "star.slash" : "star")
                }
                Button(action: toggleArchive) {
                    Label(job.isArchived ? "Restore Job" : "Archive Job",
                          systemImage: job.isArchived ? "arrow.uturn.backward" : "archivebox")
                }
                Button(role: .destructive) {
                    activeAlert = .delete
                } label: {
                    Label("Delete Job", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Job")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditJob = true }
            }
        }
        .sheet(isPresented: $showingEditJob) {
            NavigationStack { EditJobView(job: job) }
        }
        .alert(activeAlert?.title ?? "Job", isPresented: Binding(
            get: { activeAlert != nil },
            set: { if !$0 { activeAlert = nil } }
        ), presenting: activeAlert) { alert in
            switch alert {
            case .delete:
                Button("Delete", role: .destructive, action: deleteJob)
                Button("Cancel", role: .cancel) { activeAlert = nil }
            case .error, .completed:
                Button("OK", role: .cancel) { activeAlert = nil }
            }
        } message: { alert in
            Text(alert.message(jobTitle: job.title))
        }
    }

    private var overviewLabels: some View {
        Group {
            Label("\(job.estimatedMinutes) min", systemImage: "clock")
            Label(job.repeatRule.rawValue, systemImage: job.repeatRule.icon)
        }
    }

    private var status: DetailStatus {
        if job.isArchived { return .archived }
        if job.isOverdue { return .overdue }
        if job.isAvailable { return .ready }
        return .done
    }

    private var statusBadge: some View {
        Label(status.rawValue, systemImage: status.icon)
            .font(.caption.bold())
            .foregroundStyle(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(status.color.opacity(0.12), in: Capsule())
    }

    private var completionExplanation: String {
        if job.isArchived { return "Restore this job to make it available again when due." }
        if !job.isAvailable {
            return job.repeatRule == .once
                ? "This one-off job is already complete."
                : "This job is complete and waiting until its next due date."
        }
        return job.repeatRule == .once
            ? "Completing this one-off job records it in your history and archives it."
            : "Completing this job records it in your history and schedules its next repeat."
    }

    private var priorityName: String {
        switch job.priority {
        case 0: return "Low"
        case 2: return "High"
        case 3: return "Urgent"
        default: return "Normal"
        }
    }

    private func dueDescription(_ date: Date) -> String {
        let calendar = Calendar.current
        if job.lastCompletedAt == nil { return "Ready now" }
        if calendar.isDateInToday(date) {
            return "Due today at \(date.formatted(date: .omitted, time: .shortened))"
        }
        if calendar.isDateInTomorrow(date) { return "Due tomorrow" }
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if days > 1 { return "Due in \(days) days" }
        if days < 0 { return "Overdue" }
        return "Due now"
    }

    private func toggleFavourite() {
        let previousValue = job.isFavourite
        job.isFavourite.toggle()
        do {
            try modelContext.save()
        } catch {
            job.isFavourite = previousValue
            activeAlert = .error("Couldn’t update favourites. \(error.localizedDescription)")
        }
    }

    private func toggleArchive() {
        let previousValue = job.isArchived
        job.isArchived.toggle()
        do {
            try modelContext.save()
        } catch {
            job.isArchived = previousValue
            activeAlert = .error("Couldn’t \(previousValue ? "restore" : "archive") this job. \(error.localizedDescription)")
        }
    }

    private func completeJob() {
        guard job.isAvailable, !isCompletingJob else { return }
        isCompletingJob = true
        defer { isCompletingJob = false }

        // Establish a saved baseline so rollback cannot discard unrelated edits.
        do {
            if modelContext.hasChanges { try modelContext.save() }
        } catch {
            activeAlert = .error("Couldn’t save existing changes. This job was not completed. \(error.localizedDescription)")
            return
        }

        let completedAt = Date.now
        let completion = JobCompletion(
            jobTitle: job.title,
            category: job.category,
            estimatedMinutes: job.estimatedMinutes,
            completedAt: completedAt
        )
        modelContext.insert(completion)
        job.lastCompletedAt = completedAt
        // Match the app's existing Today screen behaviour.
        if job.repeatRule == .once { job.isArchived = true }

        do {
            try modelContext.save()
            activeAlert = .completed(job.repeatRule == .once
                ? "Completion saved to your history. This one-off job is now archived."
                : "Completion saved to your history. This job will be ready again at its next due date.")
        } catch {
            modelContext.rollback()
            activeAlert = .error("Couldn’t complete this job. Please try again. \(error.localizedDescription)")
        }
    }

    private func deleteJob() {
        do {
            if modelContext.hasChanges { try modelContext.save() }
        } catch {
            activeAlert = .error("Couldn’t save existing changes. This job was not deleted. \(error.localizedDescription)")
            return
        }
        modelContext.delete(job)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            activeAlert = .error("Couldn’t delete this job. \(error.localizedDescription)")
        }
    }
}

private enum DetailStatus: String {
    case ready = "READY"
    case overdue = "OVERDUE"
    case done = "DONE"
    case archived = "ARCHIVED"

    var icon: String {
        switch self {
        case .ready: return "bolt.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .done: return "checkmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }

    var color: Color {
        switch self {
        case .ready: return .green
        case .overdue: return .red
        case .done: return .blue
        case .archived: return .secondary
        }
    }
}

private enum DetailAlert {
    case delete
    case error(String)
    case completed(String)

    var title: String {
        switch self {
        case .delete: return "Delete Job?"
        case .error: return "Couldn’t Save Changes"
        case .completed: return "Job Completed"
        }
    }

    func message(jobTitle: String) -> String {
        switch self {
        case .delete:
            return "This permanently deletes \(jobTitle). Your existing completion history will remain."
        case .error(let message), .completed(let message):
            return message
        }
    }
}
