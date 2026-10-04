import SwiftUI
import SwiftData
import Charts

struct JobProgressView: View {
    @AppStorage("dailyJobGoal") private var dailyJobGoal = 3
    @Query(sort: \JobCompletion.completedAt, order: .reverse)
    private var completions: [JobCompletion]

    @State private var historyRange: ProgressHistoryRange = .allTime
    @State private var historyCategory: String?
    @State private var historySearch = ""
    @State private var historyLimit = 20

    private var calendar: Calendar { Calendar.current }
    private var effectiveDailyGoal: Int { max(1, dailyJobGoal) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryGrid
                    dailyGoalSummary
                    streakSummary
                    weeklyActivity
                    categorySection
                    completionHistory
                }
                .frame(maxWidth: 700, alignment: .leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Progress")
        .onChange(of: historyRange) { _, _ in historyLimit = 20 }
        .onChange(of: historyCategory) { _, _ in historyLimit = 20 }
        .onChange(of: historySearch) { _, _ in historyLimit = 20 }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Today", value: "\(todayCompletions.count)", subtitle: "jobs", icon: "checkmark.circle.fill")
            StatCard(title: "Today", value: "\(minutes(in: todayCompletions))", subtitle: "estimated minutes", icon: "clock.fill")
            StatCard(title: "This Week", value: "\(weekCompletions.count)", subtitle: "jobs", icon: "calendar")
            StatCard(title: "This Week", value: "\(minutes(in: weekCompletions))", subtitle: "estimated minutes", icon: "clock.fill")
            StatCard(title: "All Time", value: "\(completions.count)", subtitle: "jobs", icon: "trophy.fill")
            StatCard(title: "All Time", value: "\(minutes(in: completions))", subtitle: "estimated minutes", icon: "clock.fill")
        }
    }

    private var dailyGoalSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Goal").font(.headline)
                Spacer()
                Text("\(todayCompletions.count) of \(effectiveDailyGoal) jobs")
                    .font(.subheadline.bold())
            }
            ProgressView(value: min(Double(todayCompletions.count) / Double(effectiveDailyGoal), 1))
                .tint(todayCompletions.count >= effectiveDailyGoal ? Color.green : Color.accentColor)
                .accessibilityLabel("Today's daily goal")
                .accessibilityValue("\(todayCompletions.count) of \(effectiveDailyGoal) jobs completed")
            let remaining = max(effectiveDailyGoal - todayCompletions.count, 0)
            Text(remaining == 0 ? "Daily goal complete!" : remaining == 1
                 ? "1 more job to reach today's goal." : "\(remaining) more jobs to reach today's goal.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var streakSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                StreakCard(title: "Current Streak", value: currentStreak,
                           subtitle: currentStreak == 1 ? "day" : "days", icon: "flame.fill")
                StreakCard(title: "Best Streak", value: bestStreak,
                           subtitle: bestStreak == 1 ? "day" : "days", icon: "trophy.fill")
            }
            Text("Streaks count consecutive days with at least \(effectiveDailyGoal) completed jobs, using your current daily goal.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var weeklyActivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last 7 Days").font(.title2.bold())
            let days = lastSevenDays
            if days.allSatisfy({ $0.count == 0 }) {
                ContentUnavailableView(
                    "No Activity in the Last 7 Days", systemImage: "chart.bar",
                    description: Text("Complete a job to start filling your weekly chart.")
                )
            } else {
                Chart {
                    ForEach(days) { day in
                        BarMark(x: .value("Day", day.date, unit: .day), y: .value("Jobs", day.count))
                            .cornerRadius(5)
                            .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                            .accessibilityValue("\(day.count) completed jobs")
                    }
                    RuleMark(y: .value("Daily Goal", effectiveDailyGoal))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 5]))
                        .foregroundStyle(.secondary)
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Goal: \(effectiveDailyGoal)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) {
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Categories · All Time").font(.title2.bold())
            if categoryStats.isEmpty {
                Text("Complete some jobs to see your category breakdown.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(categoryStats, id: \.category) { item in
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            CategoryBadge(categoryName: item.category)
                            Spacer()
                            categoryTotals(item)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            CategoryBadge(categoryName: item.category)
                            categoryTotals(item)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func categoryTotals(_ item: CategoryActivity) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(item.count == 1 ? "1 job" : "\(item.count) jobs").font(.headline)
            Text("\(item.minutes) estimated min").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var completionHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Completion History").font(.title2.bold())
            historyControls
            let matches = filteredHistory
            Text("\(matches.count) \(matches.count == 1 ? "job" : "jobs") · \(minutes(in: matches)) estimated min")
                .font(.subheadline.weight(.medium))
            if matches.isEmpty {
                ContentUnavailableView {
                    Label(completions.isEmpty ? "Nothing Completed Yet" : "No Matching Completions",
                          systemImage: "checkmark.circle")
                } description: {
                    Text(completions.isEmpty ? "Jobs you complete will appear here."
                         : "Try another date range, category, or search.")
                } actions: {
                    if historyFiltersAreActive {
                        Button("Clear History Filters", action: clearHistoryFilters)
                    }
                }
            } else {
                let visible = Array(matches.prefix(historyLimit))
                let days = Dictionary(grouping: visible) { calendar.startOfDay(for: $0.completedAt) }
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(days.keys.sorted(by: >), id: \.self) { date in
                        Text(date, format: .dateTime.weekday(.wide).day().month().year())
                            .font(.subheadline.bold())
                            .padding(.top, 14)
                            .padding(.bottom, 6)
                        ForEach(days[date] ?? []) { completion in
                            historyRow(completion)
                            Divider()
                        }
                    }
                }
                if matches.count > visible.count {
                    Button("Show More (\(matches.count - visible.count) remaining)") {
                        historyLimit += 20
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var historyControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { historyMenus }
                VStack(alignment: .leading, spacing: 10) { historyMenus }
            }
            TextField("Search completion history", text: $historySearch)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .accessibilityLabel("Search completion history")
            if historyFiltersAreActive {
                Button("Clear History Filters", action: clearHistoryFilters)
                    .font(.subheadline)
            }
        }
    }

    private var historyMenus: some View {
        Group {
            Picker("Date Range", selection: $historyRange) {
                ForEach(ProgressHistoryRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.menu)
            Picker("Category", selection: $historyCategory) {
                Text("All Categories").tag(nil as String?)
                ForEach(historyCategories, id: \.self) { category in
                    Text(category).tag(Optional(category))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func historyRow(_ completion: JobCompletion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(completion.jobTitle).font(.headline)
                Spacer()
                Label("DONE", systemImage: "checkmark.circle.fill")
                    .font(.caption2.bold()).foregroundStyle(.green)
            }
            CategoryBadge(categoryName: completion.category)
            HStack {
                Label("\(completion.estimatedMinutes) min", systemImage: "clock")
                Spacer()
                Text(completion.completedAt, format: .dateTime.hour().minute())
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }

    private func minutes(in items: [JobCompletion]) -> Int {
        items.reduce(0) { $0 + $1.estimatedMinutes }
    }

    private var todayCompletions: [JobCompletion] {
        completions.filter { calendar.isDateInToday($0.completedAt) }
    }

    private var weekCompletions: [JobCompletion] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return completions.filter { $0.completedAt >= interval.start && $0.completedAt < interval.end }
    }

    private var successfulDays: Set<Date> {
        let grouped = Dictionary(grouping: completions) { calendar.startOfDay(for: $0.completedAt) }
        return Set(grouped.filter { $0.value.count >= effectiveDailyGoal }.map(\.key))
    }

    private var currentStreak: Int {
        let days = successfulDays
        let today = calendar.startOfDay(for: .now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        var date: Date
        if days.contains(today) { date = today }
        else if days.contains(yesterday) { date = yesterday }
        else { return 0 }
        var streak = 0
        while days.contains(date) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return streak
    }

    private var bestStreak: Int {
        let days = successfulDays.sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1
        var running = 1
        for index in 1..<days.count {
            let difference = calendar.dateComponents([.day], from: days[index - 1], to: days[index]).day ?? 0
            running = difference == 1 ? running + 1 : 1
            best = max(best, running)
        }
        return best
    }

    private var lastSevenDays: [DayActivity] {
        let today = calendar.startOfDay(for: .now)
        let grouped = Dictionary(grouping: completions) { calendar.startOfDay(for: $0.completedAt) }
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else { return nil }
            return DayActivity(date: date, count: grouped[date]?.count ?? 0)
        }
    }

    private var categoryStats: [CategoryActivity] {
        Dictionary(grouping: completions, by: \.category).map { category, items in
            CategoryActivity(category: category, count: items.count, minutes: minutes(in: items))
        }.sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.category.localizedStandardCompare($1.category) == .orderedAscending
        }
    }

    private var historyCategories: [String] {
        Array(Set(completions.map(\.category))).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var historyFiltersAreActive: Bool {
        historyRange != .allTime || historyCategory != nil
            || !historySearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func clearHistoryFilters() {
        historyRange = .allTime
        historyCategory = nil
        historySearch = ""
        historyLimit = 20
    }

    private var filteredHistory: [JobCompletion] {
        let search = historySearch.trimmingCharacters(in: .whitespacesAndNewlines)
        return completions.filter { completion in
            matchesHistoryRange(completion.completedAt)
                && (historyCategory == nil || completion.category == historyCategory)
                && (search.isEmpty || completion.jobTitle.localizedCaseInsensitiveContains(search)
                    || completion.category.localizedCaseInsensitiveContains(search))
        }
    }

    private func matchesHistoryRange(_ date: Date) -> Bool {
        let now = Date.now
        switch historyRange {
        case .allTime: return true
        case .today: return calendar.isDate(date, inSameDayAs: now)
        case .lastSevenDays:
            let today = calendar.startOfDay(for: now)
            guard let start = calendar.date(byAdding: .day, value: -6, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: today) else { return false }
            return date >= start && date < end
        case .thisWeek, .thisMonth:
            let component: Calendar.Component = historyRange == .thisWeek ? .weekOfYear : .month
            guard let interval = calendar.dateInterval(of: component, for: now) else { return false }
            return date >= interval.start && date < interval.end
        }
    }
}

private enum ProgressHistoryRange: String, CaseIterable, Identifiable {
    case allTime = "All Time"
    case today = "Today"
    case lastSevenDays = "Last 7 Days"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    var id: String { rawValue }
}

private struct DayActivity: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
}

private struct CategoryActivity {
    let category: String
    let count: Int
    let minutes: Int
}

// MARK: - Streak Card

private struct StreakCard: View {

    let title: String
    let value: Int
    let subtitle: String
    let icon: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Image(
                    systemName: icon
                )
                .foregroundStyle(
                    Color.accentColor
                )

                Spacer()

                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Text("\(value)")
                .font(
                    .system(
                        size: 32,
                        weight: .bold,
                        design: .rounded
                    )
                )

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            Color.secondary.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }
}

// MARK: - Stat Card

private struct StatCard: View {

    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Image(systemName: icon)
                    .foregroundStyle(
                        Color.accentColor
                    )

                Spacer()

                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Text(value)
                .font(
                    .system(
                        size: 32,
                        weight: .bold,
                        design: .rounded
                    )
                )

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            Color.secondary.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }
}

#Preview {

    NavigationStack {
        JobProgressView()
    }
    .modelContainer(
        for: [
            Job.self,
            JobCompletion.self
        ],
        inMemory: true
    )
}
