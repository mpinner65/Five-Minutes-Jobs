import SwiftUI
import WidgetKit

private struct SavedJob: Codable {
    let id: UUID
    let title: String
    let minutes: Int
    let category: String
    let availableAt: Date
    let priority: Int
    let favourite: Bool
}
struct ReadyJobEntry: TimelineEntry {
    let date: Date
    let id: UUID?
    let title: String
    let subtitle: String
}
struct ReadyJobProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadyJobEntry {
        ReadyJobEntry(date: .now, id: nil, title: "A small win is waiting", subtitle: "Five Minute Jobs")
    }
    func getSnapshot(in context: Context, completion: @escaping (ReadyJobEntry) -> Void) {
        completion(entry(at: .now, jobs: load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadyJobEntry>) -> Void) {
        let jobs = load()
        let now = Date.now
        let end = now.addingTimeInterval(86400)
        let futureDates = Set(jobs.map(\.availableAt).filter { $0 > now && $0 <= end }).sorted()
        let entries = ([now] + futureDates).map { entry(at: $0, jobs: jobs) }
        completion(Timeline(entries: entries, policy: .after(end)))
    }
    private func load() -> [SavedJob] {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mattpinner.FiveMinuteJobs")?
            .appendingPathComponent("ready-jobs.json"), let data = try? Data(contentsOf: url),
            let jobs = try? JSONDecoder().decode([SavedJob].self, from: data) else { return [] }
        return jobs
    }
    private func entry(at date: Date, jobs: [SavedJob]) -> ReadyJobEntry {
        let ready = jobs.filter { $0.availableAt <= date }.sorted {
            if $0.favourite != $1.favourite { return $0.favourite }
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            return $0.id.uuidString < $1.id.uuidString
        }
        if let job = ready.first {
            return ReadyJobEntry(date: date, id: job.id, title: job.title, subtitle: "\(job.minutes) min · \(job.category)")
        }
        return ReadyJobEntry(date: date, id: nil, title: "Room for a small win", subtitle: "Open the app to find or add a job.")
    }
}
struct ReadyJobWidgetView: View {
    let entry: ReadyJobEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Five Minute Jobs", systemImage: "bolt.fill").font(.caption.bold()).foregroundStyle(.blue)
            Text(entry.title).font(.headline).lineLimit(3)
            Text(entry.subtitle).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(entry.id == nil ? "Open Five Minute Jobs" : "View Job →").font(.caption.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: entry.id.map { "fiveminutejobs://job/\($0.uuidString)" } ?? "fiveminutejobs://today"))
        .privacySensitive()
    }
}
@main
struct ReadyJobWidget: Widget {
    let kind = "FiveMinuteReadyJob"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadyJobProvider()) { ReadyJobWidgetView(entry: $0) }
            .configurationDisplayName("A Five-Minute Job")
            .description("One ready job that fits five minutes. Tap to open it in the app.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
