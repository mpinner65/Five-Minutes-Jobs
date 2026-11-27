import SwiftUI
import SwiftData

struct JobsView: View {

    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Jobs

    @Query(
        sort: \Job.createdAt,
        order: .reverse
    )
    private var jobs: [Job]

    // MARK: - State

    @State private var showingAddJob = false
    @State private var selectedRoom = ""
    @State private var easyOnly = false
    @State private var searchText = ""
    @State private var selectedSort: JobSortOrder = .recommended
    @State private var pendingDeletion: [Job] = []
    @State private var showingDeleteConfirmation = false
    @State private var saveError: String?


    @State private var selectedStatus:
        JobStatusFilter = .all

    @State private var selectedCategory:
        JobCategory?

    // MARK: - Body

    var body: some View {

        Group {

            if jobs.isEmpty {

                emptyState

            } else {

                jobsList
            }
        }
        .navigationTitle("Jobs")
        .searchable(
            text: $searchText,
            prompt: "Search Jobs"
        )
        .toolbar {

            ToolbarItem(
                placement: .primaryAction
            ) {

                Button {

                    showingAddJob = true

                } label: {

                    Image(
                        systemName: "plus"
                    )
                }
            }
        }
        .confirmationDialog(
            pendingDeletion.count == 1 ? "Delete this job?" : "Delete these jobs?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { confirmDeletion() }
            Button("Cancel", role: .cancel) { pendingDeletion = [] }
        } message: {
            Text("This permanently deletes the selected jobs and cannot be undone.")
        }
        .alert("Couldn’t Save Changes", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
        .sheet(
            isPresented: $showingAddJob
        ) {

            NavigationStack {

                AddJobView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState:
        some View {

        ContentUnavailableView {

            Label(
                "No Jobs Yet",
                systemImage: "checklist"
            )

        } description: {

            Text(
                "Create your own jobs or start with a collection of useful small tasks."
            )

        } actions: {

            VStack(spacing: 12) {

                Button {

                    showingAddJob = true

                } label: {

                    Label(
                        "Add Your First Job",
                        systemImage: "plus"
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )

                Button {

                    addStarterJobs()

                } label: {

                    Label(
                        "Add Starter Jobs",
                        systemImage:
                            "wand.and.stars"
                    )
                }
                .buttonStyle(
                    .bordered
                )
            }
        }
    }

    // MARK: - Jobs List

    private var jobsList:
        some View {

        let visibleJobs = filteredJobs

        return List {

            Section {

                filterControls
            }

            Section {

                if visibleJobs.isEmpty {

                    ContentUnavailableView(
                        emptyFilterTitle,
                        systemImage:
                            emptyFilterIcon,
                        description:
                            Text(
                                emptyFilterMessage
                            )
                    )

                } else {

                    ForEach(
                        visibleJobs
                    ) { job in

                        NavigationLink {

                            JobDetailView(
                                job: job
                            )

                        } label: {

                            jobRow(
                                job
                            )
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                toggleFavourite(job)
                            } label: {
                                Label(job.isFavourite ? "Unfavourite" : "Favourite",
                                      systemImage: job.isFavourite ? "star.slash" : "star.fill")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Confirmation owns the destructive action; swiping never deletes.
                            Button {
                                pendingDeletion = [job]
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                            Button {
                                toggleArchive(job)
                            } label: {
                                Label(job.isArchived ? "Restore" : "Archive",
                                      systemImage: job.isArchived ? "archivebox" : "archivebox.fill")
                            }
                            .tint(.orange)
                        }
                    }
                    .onDelete(
                        perform:
                            deleteFilteredJobs
                    )
                }
            } header: {
                HStack {
                    Text(resultsSummary(count: visibleJobs.count))
                    Spacer()
                    Menu {
                        Picker("Sort Jobs", selection: $selectedSort) {
                            ForEach(JobSortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Label(selectedSort.rawValue, systemImage: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Sort Jobs: \(selectedSort.rawValue)")
                }
                .textCase(nil)
            }
        }
    }

    private func resultsSummary(count: Int) -> String {
        let category = selectedCategory.map { "\($0.rawValue) " } ?? ""
        return "\(count) \(category)\(count == 1 ? "Job" : "Jobs")"
    }

    // MARK: - Filters

    private var filterControls:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Toggle("Easy Jobs Only", isOn: $easyOnly)
            Picker("Room", selection: $selectedRoom) {
                Text("Any Room").tag("")
                ForEach(JobRooms.all, id: \.self) { Text($0).tag($0) }
            }

            // MARK: Status Filters

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 8) {

                    ForEach(
                        JobStatusFilter.allCases
                    ) { status in

                        Button {

                            withAnimation(
                                .easeInOut(
                                    duration: 0.2
                                )
                            ) {

                                selectedStatus =
                                    status
                            }

                        } label: {

                            HStack(spacing: 6) {

                                Image(
                                    systemName:
                                        status.icon
                                )

                                Text(
                                    status.title
                                )

                                Text(
                                    "\(count(for: status))"
                                )
                                .font(
                                    .caption2.bold()
                                )
                                .padding(
                                    .horizontal,
                                    6
                                )
                                .padding(
                                    .vertical,
                                    2
                                )
                                .background(
                                    selectedStatus ==
                                        status
                                    ? Color.white
                                        .opacity(0.22)
                                    : Color.secondary
                                        .opacity(0.14)
                                )
                                .clipShape(
                                    Capsule()
                                )
                            }
                            .font(
                                .subheadline
                                    .weight(
                                        .medium
                                    )
                            )
                            .padding(
                                .horizontal,
                                13
                            )
                            .padding(
                                .vertical,
                                8
                            )
                            .foregroundStyle(
                                selectedStatus ==
                                    status
                                ? Color.white
                                : Color.primary
                            )
                            .background {

                                Capsule()
                                    .fill(
                                        selectedStatus ==
                                            status
                                        ? Color
                                            .accentColor
                                        : Color
                                            .secondary
                                            .opacity(
                                                0.12
                                            )
                                    )
                            }
                        }
                        .buttonStyle(
                            .plain
                        )
                    }
                }
            }

            // MARK: Category

            HStack {

                Menu {

                    Button {

                        selectedCategory = nil

                    } label: {

                        Label(
                            "All Categories",
                            systemImage:
                                "square.grid.2x2"
                        )
                    }

                    Divider()

                    ForEach(
                        JobCategory.allCases
                    ) { category in

                        Button {

                            selectedCategory =
                                category

                        } label: {

                            Label(
                                category.rawValue,
                                systemImage:
                                    category.icon
                            )
                        }
                    }

                } label: {

                    Label(
                        selectedCategory?
                            .rawValue ??
                            "All Categories",
                        systemImage:
                            "line.3.horizontal.decrease.circle"
                    )
                }

                Spacer()

                if filtersAreActive {

                    Button {

                        withAnimation {

                            clearFilters()
                        }

                    } label: {

                        Label(
                            "Clear",
                            systemImage:
                                "xmark.circle.fill"
                        )
                    }
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .font(
                .subheadline
            )
        }
        .padding(
            .vertical,
            4
        )
    }

    // MARK: - Job Row

    private func jobRow(_ job: Job) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(job.title)
                    .font(.headline)
                CategoryBadge(categoryName: job.category)
                HStack(spacing: 8) {
                    Label("\(job.estimatedMinutes) min", systemImage: "clock")
                    if job.repeatRule != .once {
                        Label(job.repeatRule.rawValue,
                              systemImage: job.repeatRule.icon)
                    }
                    if job.priority >= 3 {
                        Label("High priority", systemImage: "exclamationmark.circle.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if matches(job, status: .completed), job.repeatRule != .once {
                    nextDueInformation(for: job)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 8) {
                statusView(for: job)
                favouriteButton(for: job)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func nextDueInformation(for job: Job) -> some View {
        if let dueDate = job.nextDueDate {
            Label {
                Text(nextDueDescription(dueDate))
            } icon: {
                Image(systemName: "calendar")
            }
            .accessibilityLabel("Next due \(dueDate.formatted(date: .abbreviated, time: .shortened))")
        }
    }

    private func nextDueDescription(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Due today at \(date.formatted(date: .omitted, time: .shortened))"
        }
        if calendar.isDateInTomorrow(date) { return "Due tomorrow" }
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if days > 1 { return "Due in \(days) days" }
        return "Due \(date.formatted(date: .abbreviated, time: .shortened))"
    }

    // MARK: - Favourite Button

    private func favouriteButton(
        for job: Job
    ) -> some View {

        Button {

            toggleFavourite(
                job
            )

        } label: {

            Image(
                systemName:
                    job.isFavourite
                    ? "star.fill"
                    : "star"
            )
            .font(.body)
            .foregroundStyle(
                job.isFavourite
                ? Color.yellow
                : Color.secondary
            )
            .frame(
                width: 30,
                height: 30
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            .borderless
        )
        .accessibilityLabel(
            job.isFavourite
            ? "Remove from favourites"
            : "Add to favourites"
        )
    }

    // MARK: - Toggle Favourite

    private func toggleFavourite(_ job: Job) {
        let previousValue = job.isFavourite
        job.isFavourite.toggle()
        do {
            try modelContext.save()
        } catch {
            job.isFavourite = previousValue
            saveError = "Couldn’t update favourites. \(error.localizedDescription)"
        }
    }

    private func toggleArchive(_ job: Job) {
        let previousValue = job.isArchived
        job.isArchived.toggle()
        do {
            try modelContext.save()
        } catch {
            job.isArchived = previousValue
            saveError = "Couldn’t \(previousValue ? "restore" : "archive") this job. \(error.localizedDescription)"
        }
    }

    // MARK: - Status

    private func statusView(for job: Job) -> some View {
        let status: JobStatusFilter = job.isArchived ? .archived
            : matches(job, status: .overdue) ? .overdue
            : matches(job, status: .ready) ? .ready : .completed
        let color: Color = status == .archived ? .secondary
            : status == .overdue ? .red : status == .ready ? .green : .blue

        return VStack(alignment: .trailing, spacing: 3) {
            Label(status.title.uppercased(), systemImage: status.icon)
                .font(.caption2.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(color.opacity(0.12), in: Capsule())
            if status == .overdue, job.daysOverdue > 0 {
                Text("\(job.daysOverdue)d overdue")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Filtered Jobs

    private var filteredJobs:
        [Job] {

        let matchingJobs =
            jobs.filter { job in

                let matchesSearch =
                    searchText.isEmpty ||
                    job.title
                        .localizedCaseInsensitiveContains(
                            searchText
                        )

                let matchesCategory =
                    selectedCategory == nil ||
                    job.category ==
                        selectedCategory?
                            .rawValue

                let matchesStatus =
                    matches(
                        job,
                        status:
                            selectedStatus
                    )

                return
                    (selectedRoom.isEmpty || job.room == selectedRoom) &&
                    (!easyOnly || job.effort == .easy) &&
                    matchesSearch &&
                    matchesCategory &&
                    matchesStatus
            }

        // Original query order provides a stable newest-first tie-breaker.
        let queryPositions = Dictionary(uniqueKeysWithValues:
            jobs.enumerated().map { ($0.element.persistentModelID, $0.offset) })
        return matchingJobs.sorted { lhs, rhs in
            switch selectedSort {
            case .recommended:
                let leftRank = recommendationRank(lhs)
                let rightRank = recommendationRank(rhs)
                if leftRank != rightRank { return leftRank < rightRank }
                if lhs.isFavourite != rhs.isFavourite { return lhs.isFavourite }
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                if lhs.estimatedMinutes != rhs.estimatedMinutes {
                    return lhs.estimatedMinutes < rhs.estimatedMinutes
                }
            case .favourites:
                if lhs.isFavourite != rhs.isFavourite { return lhs.isFavourite }
            case .priority:
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            case .shortest:
                if lhs.estimatedMinutes != rhs.estimatedMinutes {
                    return lhs.estimatedMinutes < rhs.estimatedMinutes
                }
            case .longest:
                if lhs.estimatedMinutes != rhs.estimatedMinutes {
                    return lhs.estimatedMinutes > rhs.estimatedMinutes
                }
            case .newest:
                break
            }
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            return (queryPositions[lhs.persistentModelID] ?? 0)
                < (queryPositions[rhs.persistentModelID] ?? 0)
        }
    }

    private func recommendationRank(_ job: Job) -> Int {
        if job.isArchived { return 3 }
        if matches(job, status: .overdue) { return 0 }
        if matches(job, status: .ready) { return 1 }
        return 2
    }

    // MARK: - Status Matching

    private func matches(
        _ job: Job,
        status: JobStatusFilter
    ) -> Bool {

        switch status {

        case .all:

            return true

        case .favourites:

            return job.isFavourite

        case .ready:

            // Available now, but not overdue.

            return
                job.isAvailable &&
                !job.isOverdue &&
                !job.isArchived

        case .overdue:

            // Repeating job that has passed
            // its next due date.

            return
                job.isOverdue &&
                !job.isArchived

        case .completed:

            // "Done" represents jobs that are
            // currently finished or waiting.
            //
            // One-off:
            // Completed once and no longer available.
            //
            // Repeating:
            // Completed and waiting until its
            // next due date.
            //
            // Ready and overdue jobs are excluded.

            return
                job.lastCompletedAt != nil &&
                !job.isAvailable &&
                !job.isOverdue &&
                !job.isArchived

        case .archived:

            return job.isArchived
        }
    }
    // MARK: - Filter Counts

    private func count(
        for status: JobStatusFilter
    ) -> Int {

        jobs.filter { job in

            let matchesCategory =
                selectedCategory == nil ||
                job.category ==
                    selectedCategory?
                        .rawValue

            let matchesSearch =
                searchText.isEmpty ||
                job.title
                    .localizedCaseInsensitiveContains(
                        searchText
                    )

            return
                (selectedRoom.isEmpty || job.room == selectedRoom) &&
                (!easyOnly || job.effort == .easy) &&
                matchesCategory &&
                matchesSearch &&
                matches(
                    job,
                    status: status
                )
        }
        .count
    }

    // MARK: - Empty Filter State

    private var emptyFilterTitle:
        String {

        switch selectedStatus {

        case .favourites:
            return "No Favourite Jobs"

        case .ready:
            return "No Ready Jobs"

        case .overdue:
            return "Nothing Overdue"

        case .completed:
            return "No Completed Jobs"

        case .archived:
            return "No Archived Jobs"

        case .all:
            return "No Matching Jobs"
        }
    }

    private var emptyFilterIcon:
        String {

        switch selectedStatus {

        case .favourites:
            return "star"

        case .ready:
            return "bolt"

        case .overdue:
            return "exclamationmark.circle"

        case .completed:
            return "checkmark.circle"

        case .archived:
            return "archivebox"

        case .all:
            return "magnifyingglass"
        }
    }

    private var emptyFilterMessage:
        String {

        if !searchText.isEmpty ||
            selectedCategory != nil {

            return
                "Try changing your search or filters."
        }

        switch selectedStatus {

        case .favourites:
            return
                "Tap the star on a job to add it to your favourites."

        case .ready:
            return
                "You don't have any jobs ready right now."

        case .overdue:
            return
                "You're all caught up."

        case .completed:
            return
                "Complete a job and it will appear here."

        case .archived:
            return
                "Archived jobs will appear here."

        case .all:
            return
                "Try changing your search or filters."
        }
    }

    // MARK: - Active Filters

    private var filtersAreActive:
        Bool {

        !selectedRoom.isEmpty || easyOnly ||
        !searchText.isEmpty ||
        selectedStatus != .all ||
        selectedCategory != nil
    }

    // MARK: - Clear Filters

    private func clearFilters() {

        selectedRoom = ""
        easyOnly = false
        searchText = ""
        selectedStatus = .all
        selectedCategory = nil
    }

    // MARK: - Starter Jobs

    private func addStarterJobs() {

        StarterJobs.add(
            to: modelContext
        )
    }

    // MARK: - Delete

    private func deleteFilteredJobs(offsets: IndexSet) {
        let visibleJobs = filteredJobs
        pendingDeletion = offsets.compactMap { index in
            visibleJobs.indices.contains(index) ? visibleJobs[index] : nil
        }
        showingDeleteConfirmation = !pendingDeletion.isEmpty
    }

    private func confirmDeletion() {
        let selectedJobs = pendingDeletion
        pendingDeletion = []
        do {
            // Commit existing edits first, so rollback only reverts this deletion.
            if modelContext.hasChanges { try modelContext.save() }
        } catch {
            saveError = "Couldn’t save existing changes. No jobs were deleted. \(error.localizedDescription)"
            return
        }
        for job in selectedJobs { modelContext.delete(job) }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveError = "Couldn’t delete the selected jobs. \(error.localizedDescription)"
        }
    }
}

private enum JobSortOrder: String, CaseIterable, Identifiable {
    case recommended = "Recommended"
    case favourites = "Favourites"
    case priority = "Priority"
    case shortest = "Shortest"
    case longest = "Longest"
    case newest = "Newest"

    var id: String { rawValue }
}

// MARK: - Job Status Filter

private enum JobStatusFilter:
    String,
    CaseIterable,
    Identifiable {

    case all
    case favourites
    case ready
    case overdue
    case completed
    case archived

    var id: String {

        rawValue
    }

    var title: String {

        switch self {

        case .all:
            return "All"

        case .favourites:
            return "Favourites"

        case .ready:
            return "Ready"

        case .overdue:
            return "Overdue"

        case .completed:
            return "Done"

        case .archived:
            return "Archived"
        }
    }

    var icon: String {

        switch self {

        case .all:
            return "tray.full"

        case .favourites:
            return "star.fill"

        case .ready:
            return "bolt.fill"

        case .overdue:
            return
                "exclamationmark.circle.fill"

        case .completed:
            return
                "checkmark.circle.fill"

        case .archived:
            return
                "archivebox.fill"
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        JobsView()
    }
    .modelContainer(
        for: [
            Job.self,
            JobCompletion.self
        ],
        inMemory: true
    )
}
