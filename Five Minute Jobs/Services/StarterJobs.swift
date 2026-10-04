import Foundation
import SwiftData

struct StarterJobs {

    // Keep existing callers compatible while allowing Welcome to show save errors.
    @MainActor
    static func add(to modelContext: ModelContext) {
        do { _ = try addChecked(to: modelContext) }
        catch { print("Failed to add starter jobs: \(error)") }
    }

    @MainActor
    @discardableResult
    static func addChecked(to modelContext: ModelContext) throws -> Int {
        // Save unrelated edits before establishing a rollback baseline.
        if modelContext.hasChanges { try modelContext.save() }
        let existing = try modelContext.fetch(FetchDescriptor<Job>())
        let missing = starterJobs.filter { candidate in
            !existing.contains {
                $0.title == candidate.title && $0.category == candidate.category
                    && $0.repeatType == candidate.repeatType
            }
        }
        guard !missing.isEmpty else { return 0 }
        for job in missing { modelContext.insert(job) }
        do {
            try modelContext.save()
            return missing.count
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    // MARK: - Starter Jobs

    private static var starterJobs: [Job] {

        [
            // Cleaning

            Job(
                title: "Wipe kitchen bench",
                estimatedMinutes: 5,
                category: JobCategory.cleaning.rawValue,
                priority: 1,
                repeatType: JobRepeat.daily.rawValue
            ),

            Job(
                title: "Clean bathroom mirror",
                estimatedMinutes: 5,
                category: JobCategory.cleaning.rawValue,
                priority: 1,
                repeatType: JobRepeat.weekly.rawValue
            ),

            Job(
                title: "Clean microwave",
                estimatedMinutes: 10,
                category: JobCategory.cleaning.rawValue,
                priority: 1,
                repeatType: JobRepeat.weekly.rawValue
            ),

            Job(
                title: "Vacuum one room",
                estimatedMinutes: 10,
                category: JobCategory.cleaning.rawValue,
                priority: 1,
                repeatType: JobRepeat.weekly.rawValue
            ),

            // Home

            Job(
                title: "Clear one cluttered surface",
                estimatedMinutes: 5,
                category: JobCategory.home.rawValue,
                priority: 1,
                repeatType: JobRepeat.once.rawValue
            ),

            Job(
                title: "Tidy one drawer",
                estimatedMinutes: 10,
                category: JobCategory.home.rawValue,
                priority: 1,
                repeatType: JobRepeat.once.rawValue
            ),

            Job(
                title: "Change bed sheets",
                estimatedMinutes: 15,
                category: JobCategory.home.rawValue,
                priority: 1,
                repeatType: JobRepeat.weekly.rawValue
            ),

            // Digital

            Job(
                title: "Delete unwanted screenshots",
                estimatedMinutes: 5,
                category: JobCategory.digital.rawValue,
                priority: 0,
                repeatType: JobRepeat.weekly.rawValue
            ),

            Job(
                title: "Clear email junk",
                estimatedMinutes: 10,
                category: JobCategory.digital.rawValue,
                priority: 0,
                repeatType: JobRepeat.weekly.rawValue
            ),

            Job(
                title: "Clean Downloads folder",
                estimatedMinutes: 10,
                category: JobCategory.digital.rawValue,
                priority: 0,
                repeatType: JobRepeat.monthly.rawValue
            ),

            // Car

            Job(
                title: "Remove rubbish from car",
                estimatedMinutes: 5,
                category: JobCategory.car.rawValue,
                priority: 1,
                repeatType: JobRepeat.weekly.rawValue
            ),

            Job(
                title: "Check tyre pressures",
                estimatedMinutes: 15,
                category: JobCategory.car.rawValue,
                priority: 2,
                repeatType: JobRepeat.monthly.rawValue
            ),

            // Admin

            Job(
                title: "File one document",
                estimatedMinutes: 5,
                category: JobCategory.admin.rawValue,
                priority: 1,
                repeatType: JobRepeat.once.rawValue
            ),

            Job(
                title: "Check upcoming bills",
                estimatedMinutes: 10,
                category: JobCategory.admin.rawValue,
                priority: 2,
                repeatType: JobRepeat.weekly.rawValue
            ),

            // Outside

            Job(
                title: "Sweep front entrance",
                estimatedMinutes: 10,
                category: JobCategory.outside.rawValue,
                priority: 1,
                repeatType: JobRepeat.weekly.rawValue
            ),

            Job(
                title: "Pull a few weeds",
                estimatedMinutes: 15,
                category: JobCategory.outside.rawValue,
                priority: 0,
                repeatType: JobRepeat.weekly.rawValue
            ),

            // Maintenance

            Job(
                title: "Check smoke alarms",
                estimatedMinutes: 10,
                category: JobCategory.maintenance.rawValue,
                priority: 2,
                repeatType: JobRepeat.monthly.rawValue
            )
        ]
    }
}
