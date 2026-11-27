import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @Query(sort: \JobCompletion.completedAt, order: .reverse)
    private var completions: [JobCompletion]

    @State private var activeSheet: TodaySheet?
    // Resolve selection from the live query rather than retaining a deleted model.
    @State private var selectedJobID: PersistentIdentifier?
    @State private var showingJobCompleted = false
    @State private var isCompletingJob = false
    @State private var completedJobTitle = ""
    @State private var completedJobMinutes = 0
    @State private var completedGoalWithLastJob = false
    @State private var showingCompletionError = false
    @State private var completionErrorMessage = "The job could not be completed."

    @AppStorage("defaultJobMinutes") private var defaultJobMinutes = 5
    @AppStorage("dailyJobGoal") private var dailyJobGoal = 3
    @AppStorage("disabledJobCategories") private var disabledCategoriesData = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 18
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("lowEnergyMode") private var lowEnergyMode = false
    @AppStorage("suggestionRoom") private var suggestionRoom = ""
    @State private var pauseJob: Job?
    @State private var selectedMinutes = 5
    @State private var hasAppliedDefaultTime = false

    private var timeOptions: [Int] {
        Array(Set([5, 10, 15, 30, max(1, selectedMinutes)])).sorted()
    }

    private var effectiveDailyGoal: Int { max(1, dailyJobGoal) }

    var body: some View {
        // Refresh due-time and day-boundary summaries even when no model is edited.
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    selectionCard
                    resultSection
                    resumeSection
                    compactProgress
                }
                .frame(maxWidth: 700, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            if !hasAppliedDefaultTime {
                selectedMinutes = max(1, defaultJobMinutes)
                hasAppliedDefaultTime = true
            }
        }
        .task { await refreshSmartReminder() }
        .onChange(of: lowEnergyMode) { _, _ in resetCurrentResult() }
        .onChange(of: suggestionRoom) { _, _ in resetCurrentResult() }
        .sheet(item: $pauseJob) { job in NavigationStack { PauseJobView(job: job) } }
        .onChange(of: disabledCategoriesData) { _, _ in resetCurrentResult() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .ready:
                TodayJobsListView(kind: .ready)
            case .overdue:
                TodayJobsListView(kind: .overdue)
            case .completed:
                TodayCompletionsView()
            case .add:
                NavigationStack { AddJobView() }
            }
        }
        .alert("Couldn't Complete Job", isPresented: $showingCompletionError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(completionErrorMessage)
        }
    }

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("How much time do you have?", systemImage: "clock")
                .font(.headline)
            timeSelector
            suggestionControls
            Divider()
            availabilitySummary
            if !showingJobCompleted { giveMeAJobButton }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 24))
    }

    private var suggestionControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { energyControl; roomControl }
            VStack(alignment: .leading, spacing: 10) { energyControl; roomControl }
        }
        .disabled(isCompletingJob)
    }

    private var energyControl: some View {
        Button { lowEnergyMode.toggle() } label: {
            Label("Low energy", systemImage: lowEnergyMode ? "leaf.fill" : "leaf")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(lowEnergyMode ? Color.green.opacity(0.16) : Color.secondary.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(lowEnergyMode ? Color.green : Color.primary)
        .accessibilityLabel("Low energy, easy jobs only")
        .accessibilityValue(lowEnergyMode ? "On" : "Off")
        .accessibilityAddTraits(lowEnergyMode ? .isSelected : [])
    }

    private var roomControl: some View {
        Menu {
            Picker("Room", selection: $suggestionRoom) {
                Text("Any Room").tag("")
                ForEach(JobRooms.all, id: \.self) { Text($0).tag($0) }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "house")
                Text(suggestionRoom.isEmpty ? "Any Room" : suggestionRoom)
                Image(systemName: "chevron.down").font(.caption2.bold())
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Color.secondary.opacity(0.10), in: Capsule())
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("Filter room")
        .accessibilityValue(suggestionRoom.isEmpty ? "Any Room" : suggestionRoom)
    }

    private var compactProgress: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your small wins").font(.headline)
                Spacer()
                Label("\(currentStreak)", systemImage: "flame.fill")
                    .font(.subheadline.bold()).foregroundStyle(.orange)
                    .accessibilityLabel("Current streak: \(currentStreak) days")
            }
            Text("\(completedTodayCount) of \(effectiveDailyGoal) jobs today · \(completedTodayMinutes) estimated min")
                .font(.subheadline).foregroundStyle(.secondary)
            ProgressView(value: min(Double(completedTodayCount) / Double(effectiveDailyGoal), 1))
                .tint(completedTodayCount >= effectiveDailyGoal ? .green : .accentColor)
                .accessibilityLabel("Daily goal")
                .accessibilityValue("\(completedTodayCount) of \(effectiveDailyGoal) jobs")
            HStack(spacing: 8) {
                summaryButton("Ready", count: readyJobs.count, icon: "bolt.fill", color: .accentColor) { activeSheet = .ready }
                summaryButton("Overdue", count: overdueJobs.count, icon: "exclamationmark.circle", color: overdueJobs.isEmpty ? .secondary : .orange) { activeSheet = .overdue }
                summaryButton("Done", count: completedTodayCount, icon: "checkmark.circle", color: .green) { activeSheet = .completed }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }

    private func summaryButton(_ title: String, count: Int, icon: String, color: Color,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Label("\(count)", systemImage: icon).font(.headline).foregroundStyle(color)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) \(title)")
    }

    @ViewBuilder
    private var resumeSection: some View {
        let paused = availableJobs.filter { $0.pausedAt != nil && isEligible($0) }
            .sorted { ($0.pausedAt ?? .distantPast) > ($1.pausedAt ?? .distantPast) }
        if !paused.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pick Up Where You Left Off").font(.headline)
                ForEach(paused.prefix(3)) { job in
                    Button {
                        showingJobCompleted = false
                        selectedJobID = job.persistentModelID
                    } label: {
                        VStack(alignment: .leading) {
                            Text(job.title).font(.headline)
                            Text(job.resumeStep).font(.subheadline)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Make a little progress.")
                .font(.title2.bold())
            Text("A few spare minutes can make a difference.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    @ScaledMetric(relativeTo: .body) private var timeCellWidth = 64.0

    private var timeSelector: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: timeCellWidth), spacing: 10)], spacing: 10) {
            ForEach(timeOptions, id: \.self) { minutes in
                TimeButton(minutes: minutes, isSelected: selectedMinutes == minutes) {
                    selectedMinutes = minutes
                    resetCurrentResult()
                }
                .accessibilityLabel("\(minutes) minutes")
                .accessibilityAddTraits(selectedMinutes == minutes ? .isSelected : [])
            }
        }
        .disabled(isCompletingJob)
    }

    private var availabilitySummary: some View {
        VStack(spacing: 5) {
            Text(eligibleJobs.count == 1 ? "1 job fits your time" : "\(eligibleJobs.count) jobs fit your time")
                .font(.subheadline.weight(.medium))
            if lowEnergyMode {
                Text("Easy jobs only").font(.caption).foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var giveMeAJobButton: some View {
        Button(action: pickJob) {
            Label("Give Me a Job", systemImage: "dice.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isCompletingJob)
    }

    @ViewBuilder
    private var resultSection: some View {
        if showingJobCompleted {
            jobCompletedView
        } else if let selectedJob {
            selectedJobCard(selectedJob)
        } else if jobs.isEmpty {
            ContentUnavailableView {
                Label("No Jobs Yet", systemImage: "checklist")
            } description: {
                Text("Add a few small jobs and we'll find something useful to do.")
            } actions: {
                Button("Add a Job") { activeSheet = .add }
                    .buttonStyle(.borderedProminent)
            }
        } else if eligibleJobs.isEmpty {
            noMatchingJobView
        } else {
            readyView
        }
    }

    private func selectedJobCard(_ job: Job) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                CategoryBadge(categoryName: job.category)
                Spacer()
                Label(job.isOverdue ? "OVERDUE" : "READY",
                      systemImage: job.isOverdue ? "exclamationmark.circle.fill" : "bolt.fill")
                    .font(.caption.bold())
                    .foregroundStyle(job.isOverdue ? Color.red : Color.green)
            }
            HStack {
                Text(job.title).font(.title2.bold())
                if job.isFavourite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Favourite")
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { selectedJobMetadata(job) }
                VStack(alignment: .leading, spacing: 6) { selectedJobMetadata(job) }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            if job.isOverdue {
                Text(job.daysOverdue == 1 ? "1 day overdue" : "\(job.daysOverdue) days overdue")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
            if !job.notes.isEmpty { Text(job.notes).foregroundStyle(.secondary) }
            NavigationLink { JobDetailView(job: job) } label: {
                Label("View Job Details", systemImage: "info.circle")
            }
            Button { complete(job) } label: {
                Label("Job Done", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            if !job.resumeStep.isEmpty { Label(job.resumeStep, systemImage: "arrow.turn.down.right") }
            Button("Save Next Step for Later") { pauseJob = job }
            Button("Pick Another", action: pickJob).frame(maxWidth: .infinity)
        }
        .disabled(isCompletingJob)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func selectedJobMetadata(_ job: Job) -> some View {
        Group {
            Label("\(job.estimatedMinutes) min", systemImage: "clock")
            Label(job.repeatRule.rawValue, systemImage: job.repeatRule.icon)
        }
    }

    private var noMatchingJobView: some View {
        ContentUnavailableView {
            Label(availableJobs.isEmpty ? "No Jobs Ready Right Now" : "Nothing Fits Right Now",
                  systemImage: "clock.badge.xmark")
        } description: {
            Text(noMatchingDescription)
        } actions: {
            VStack(spacing: 12) {
                if let minutes = nextSuggestedMinutes {
                    Button("Try \(minutes) Minutes") {
                        selectedMinutes = minutes
                        resetCurrentResult()
                        pickJob()
                    }
                    .buttonStyle(.borderedProminent)
                }
                if hasDisabledAvailableJobs {
                    NavigationLink("Review Categories") { CategorySettingsView() }
                }
                NavigationLink("View All Jobs") { JobsView() }
                Button("Add a Job") { activeSheet = .add }
            }
        }
    }

    private var noMatchingDescription: String {
        if lowEnergyMode || !suggestionRoom.isEmpty {
            return "No ready jobs match this time, energy and room. Try Any Room, turn off Low Energy, or add an Easy job using a quick-add template."
        }
        if hasDisabledAvailableJobs && availableJobs.isEmpty {
            return "Available jobs are in categories you've turned off. Review your categories or add a new job."
        }
        if availableJobs.isEmpty {
            return "Repeating jobs will become ready when due. You can also restore an archived job or add something new."
        }
        return "No available jobs take \(selectedMinutes) minutes or less. Choose more time or add a shorter job."
    }

    private var readyView: some View {
        Label("Choose your time. We’ll find a small win.", systemImage: "sparkles")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }

    private var jobCompletedView: some View {
        VStack(spacing: 18) {
            Image(systemName: completedGoalWithLastJob ? "trophy.fill" : "checkmark.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(completedGoalWithLastJob ? Color.yellow : Color.green)
            VStack(spacing: 6) {
                Text(completedGoalWithLastJob ? "Daily Goal Complete!" : "Job Done")
                    .font(.title2.bold())
                Text(completedJobTitle).font(.headline)
                Text(completedJobMinutes == 1
                     ? "You finished this 1-minute job."
                     : "You finished this \(completedJobMinutes)-minute job.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(completionMessage).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            VStack(spacing: 6) {
                Text("\(completedTodayCount) of \(effectiveDailyGoal) jobs today")
                    .font(.subheadline.bold())
                ProgressView(value: min(Double(completedTodayCount) / Double(effectiveDailyGoal), 1))
                    .tint(completedTodayCount >= effectiveDailyGoal ? Color.green : Color.accentColor)
            }
            Button(action: pickJob) {
                Label("Give Me Another Job", systemImage: "dice.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var completionMessage: String {
        if completedTodayCount >= effectiveDailyGoal { return "Daily goal complete! 🎉" }
        let remaining = max(effectiveDailyGoal - completedTodayCount, 0)
        return remaining == 1
            ? "Nice work — 1 more job to reach today's goal."
            : "Nice work — \(remaining) more jobs to reach today's goal."
    }

    private var selectedJob: Job? {
        jobs.first { $0.persistentModelID == selectedJobID && isEligible($0) }
    }

    private func isEligible(_ job: Job) -> Bool {
        job.isAvailable && !job.isArchived
            && job.estimatedMinutes <= selectedMinutes
            && !disabledCategories.contains(job.category)
            && (!lowEnergyMode || job.effort == .easy)
            && (suggestionRoom.isEmpty || job.room == suggestionRoom)
    }

    private func pickJob() {
        guard !isCompletingJob else { return }
        showingJobCompleted = false
        completedGoalWithLastJob = false
        let previousJob = selectedJob
        selectedJobID = JobPicker.pickJob(
            from: jobs,
            maximumMinutes: selectedMinutes,
            disabledCategories: disabledCategories,
            excluding: previousJob,
            lowEnergy: lowEnergyMode,
            room: suggestionRoom.isEmpty ? nil : suggestionRoom
        )?.persistentModelID
    }

    private func resetCurrentResult() {
        selectedJobID = nil
        showingJobCompleted = false
        completedGoalWithLastJob = false
        completedJobTitle = ""
        completedJobMinutes = 0
    }

    private func complete(_ job: Job) {
        guard !isCompletingJob, isEligible(job), selectedJobID == job.persistentModelID else { return }
        isCompletingJob = true
        defer { isCompletingJob = false }

        // Commit unrelated edits first so rollback only reverts this completion.
        do {
            if modelContext.hasChanges { try modelContext.save() }
        } catch {
            completionErrorMessage = "Couldn't save existing changes. This job was not completed. \(error.localizedDescription)"
            showingCompletionError = true
            errorHaptic()
            return
        }

        let previousCompletedCount = completedTodayCount
        let completedAt = Date.now
        let completion = JobCompletion(
            jobTitle: job.title, category: job.category,
            estimatedMinutes: job.estimatedMinutes, completedAt: completedAt
        )
        modelContext.insert(completion)
        job.lastCompletedAt = completedAt
        job.nextStep = nil
        job.pausedAt = nil
        if job.repeatRule == .once { job.isArchived = true }

        do {
            try modelContext.save()
            completedJobTitle = job.title
            completedJobMinutes = job.estimatedMinutes
            completedGoalWithLastJob = previousCompletedCount < effectiveDailyGoal
                && previousCompletedCount + 1 >= effectiveDailyGoal
            selectedJobID = nil
            withAnimation(.easeInOut(duration: 0.25)) { showingJobCompleted = true }
            completionHaptic(goalReached: completedGoalWithLastJob)
            if notificationsEnabled {
                Task { await refreshSmartReminder() }
            }
        } catch {
            modelContext.rollback()
            completionErrorMessage = "Couldn't save this completion. The job is still open so you can try again. \(error.localizedDescription)"
            showingCompletionError = true
            errorHaptic()
        }
    }

    private func completionHaptic(goalReached: Bool) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        if goalReached {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.prepare()
            impact.impactOccurred()
        }
        #endif
    }

    private func errorHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        #endif
    }

    // Available includes ready and overdue; each dashboard chip has its own exclusive set.
    private var availableJobs: [Job] {
        jobs.filter { $0.isAvailable && !$0.isArchived && !disabledCategories.contains($0.category) }
    }
    private var readyJobs: [Job] { availableJobs.filter { !$0.isOverdue } }
    private var overdueJobs: [Job] { availableJobs.filter { $0.isOverdue } }
    private var eligibleJobs: [Job] { availableJobs.filter { isEligible($0) } }
    private var hasDisabledAvailableJobs: Bool {
        jobs.contains { $0.isAvailable && !$0.isArchived && disabledCategories.contains($0.category) }
    }
    private var nextSuggestedMinutes: Int? {
        availableJobs.filter { (!lowEnergyMode || $0.effort == .easy) && (suggestionRoom.isEmpty || $0.room == suggestionRoom) }
            .map(\.estimatedMinutes).filter { $0 > selectedMinutes }.min()
    }
    private var completedToday: [JobCompletion] {
        completions.filter { Calendar.current.isDateInToday($0.completedAt) }
    }
    private var completedTodayCount: Int { completedToday.count }
    private var completedTodayMinutes: Int {
        completedToday.reduce(0) { $0 + $1.estimatedMinutes }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let groupedDays = Dictionary(grouping: completions) {
            calendar.startOfDay(for: $0.completedAt)
        }
        let successfulDays = Set(groupedDays.filter { $0.value.count >= effectiveDailyGoal }.map(\.key))
        let today = calendar.startOfDay(for: .now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        var date: Date
        if successfulDays.contains(today) { date = today }
        else if successfulDays.contains(yesterday) { date = yesterday }
        else { return 0 }
        var streak = 0
        while successfulDays.contains(date) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDay
        }
        return streak
    }

    private func refreshSmartReminder() async {
        guard notificationsEnabled else { return }
        let available = availableJobs
        await NotificationService.shared.scheduleDailyReminder(
            hour: reminderHour, minute: reminderMinute,
            availableJobs: available.count,
            fiveMinuteJobs: available.filter { $0.estimatedMinutes <= 5 }.count
        )
    }

    private var disabledCategories: Set<String> {
        Set(disabledCategoriesData.split(separator: "|").map(String.init))
    }
}

private enum TodaySheet: String, Identifiable {
    case ready, overdue, completed, add
    var id: String { rawValue }
}

#Preview {
    NavigationStack { TodayView() }
        .modelContainer(for: [Job.self, JobCompletion.self], inMemory: true)
}
