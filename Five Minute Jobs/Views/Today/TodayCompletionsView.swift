import SwiftUI
import SwiftData

struct TodayCompletionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JobCompletion.completedAt, order: .reverse)
    private var completions: [JobCompletion]

    private var completedToday: [JobCompletion] {
        completions.filter { Calendar.current.isDateInToday($0.completedAt) }
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                let today = completedToday
                Group {
                    if today.isEmpty {
                        ContentUnavailableView(
                            "Nothing Completed Yet",
                            systemImage: "checkmark.circle",
                            description: Text("Jobs you complete today will appear here with their completion time and estimated minutes.")
                        )
                    } else {
                        List {
                            Section {
                                LabeledContent("Jobs Completed", value: "\(today.count)")
                                LabeledContent("Estimated Minutes", value: "\(today.reduce(0) { $0 + $1.estimatedMinutes }) min")
                            }
                            Section("Completed Today") {
                                ForEach(today) { completion in
                                    completionRow(completion)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Done Today")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func completionRow(_ completion: JobCompletion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(completion.jobTitle).font(.headline)
                Spacer()
                Label("DONE", systemImage: "checkmark.circle.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
            }
            CategoryBadge(categoryName: completion.category)
            HStack {
                Label("\(completion.estimatedMinutes) min", systemImage: "clock")
                Spacer()
                Text(completion.completedAt, format: .dateTime.hour().minute())
                    .accessibilityLabel("Completed at \(completion.completedAt.formatted(date: .omitted, time: .shortened))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TodayCompletionsView()
        .modelContainer(for: JobCompletion.self, inMemory: true)
}
