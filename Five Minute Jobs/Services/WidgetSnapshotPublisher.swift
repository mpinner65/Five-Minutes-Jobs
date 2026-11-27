import SwiftUI
import SwiftData
import WidgetKit

private struct WidgetJobSnapshot: Codable {
    let id: UUID
    let title: String
    let minutes: Int
    let category: String
    let availableAt: Date
    let priority: Int
    let favourite: Bool
}

struct WidgetSnapshotPublisher: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var jobs: [Job]
    @AppStorage("disabledJobCategories") private var disabledCategories = ""
    @AppStorage("lowEnergyMode") private var lowEnergy = false
    @AppStorage("suggestionRoom") private var room = ""
    private let group = "group.com.mattpinner.FiveMinuteJobs"

    private var fingerprint: String {
        jobs.map { job in
            [job.featureID?.uuidString ?? "", job.title, String(job.estimatedMinutes), job.category,
             String(job.isArchived), String(job.isFavourite), String(job.priority),
             String(job.createdAt.timeIntervalSince1970), String(job.lastCompletedAt?.timeIntervalSince1970 ?? 0),
             job.repeatType, job.effort.rawValue, job.room].joined(separator: "|")
        }.sorted().joined(separator: "\n") + disabledCategories + String(lowEnergy) + room
    }

    var body: some View {
        Color.clear.frame(width: 0, height: 0)
            .task(id: fingerprint) { publish() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .inactive { publish() }
            }
    }

    private func publish() {
        // IDs are optional so old stores can migrate; assign once and save before exporting.
        do {
            // Flush pending edits before sharing; a failed save keeps the previous widget data.
            if context.hasChanges { try context.save() }
            var assignedIDs: [Job] = []
            for job in jobs where job.featureID == nil {
                job.featureID = UUID()
                assignedIDs.append(job)
            }
            if !assignedIDs.isEmpty {
                do { try context.save() }
                catch {
                    for job in assignedIDs { job.featureID = nil }
                    return
                }
            }
            let disabled = Set(disabledCategories.split(separator: "|").map(String.init))
            let snapshots = jobs.compactMap { job -> WidgetJobSnapshot? in
                guard !job.isArchived, job.estimatedMinutes <= 5, job.estimatedMinutes > 0,
                      !disabled.contains(job.category), (!lowEnergy || job.effort == .easy),
                      (room.isEmpty || job.room == room), let id = job.featureID else { return nil }
                if job.repeatRule == .once && job.lastCompletedAt != nil { return nil }
                return WidgetJobSnapshot(id: id, title: job.title, minutes: job.estimatedMinutes,
                    category: job.category, availableAt: job.lastCompletedAt == nil ? .distantPast : (job.nextDueDate ?? .now),
                    priority: job.priority, favourite: job.isFavourite)
            }
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
                .appendingPathComponent("ready-jobs.json") else { return }
            let data = try JSONEncoder().encode(snapshots)
            if (try? Data(contentsOf: url)) != data {
                try data.write(to: url, options: .atomic)
                WidgetCenter.shared.reloadTimelines(ofKind: "FiveMinuteReadyJob")
            }
        } catch {
            // Keep the last saved snapshot on failure; never export uncommitted model edits.
            return
        }
    }
}
