import Foundation
import SwiftData

@Model
final class Job {

    // MARK: - Job Details

    var title: String
    var estimatedMinutes: Int
    var category: String
    var priority: Int
    var notes: String

    // MARK: - Repeat

    var repeatType: String

    // MARK: - Dates

    var createdAt: Date
    var lastCompletedAt: Date?

    // MARK: - State

    var isArchived: Bool
    var isFavourite: Bool

    // Additive optional fields let existing stores migrate without losing jobs.
    var featureID: UUID?
    var effortValue: String?
    var roomValue: String?
    var nextStep: String?
    var pausedAt: Date?

    var effort: JobEffort { JobEffort(rawValue: effortValue ?? "") ?? .moderate }
    var room: String { roomValue ?? "Unassigned" }
    var resumeStep: String { nextStep?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }

    // MARK: - Init

    init(
        title: String,
        estimatedMinutes: Int = 5,
        category: String = "Home",
        priority: Int = 1,
        notes: String = "",
        repeatType: String = JobRepeat.once.rawValue,
        createdAt: Date = .now,
        lastCompletedAt: Date? = nil,
        isArchived: Bool = false,
        isFavourite: Bool = false
    ) {

        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.category = category
        self.priority = priority
        self.notes = notes
        self.repeatType = repeatType
        self.createdAt = createdAt
        self.lastCompletedAt = lastCompletedAt
        self.isArchived = isArchived
        self.isFavourite = isFavourite
    }

    // MARK: - Repeat

    var repeatRule: JobRepeat {

        JobRepeat(
            rawValue: repeatType
        ) ?? .once
    }

    // MARK: - Next Due Date

    var nextDueDate: Date? {

        guard repeatRule != .once else {

            return nil
        }

        guard let lastCompletedAt else {

            return createdAt
        }

        let calendar =
            Calendar.current

        switch repeatRule {

        case .once:

            return nil

        case .daily:

            return calendar.date(
                byAdding: .day,
                value: 1,
                to: lastCompletedAt
            )

        case .weekly:

            return calendar.date(
                byAdding: .day,
                value: 7,
                to: lastCompletedAt
            )

        case .fortnightly:

            return calendar.date(
                byAdding: .day,
                value: 14,
                to: lastCompletedAt
            )

        case .monthly:

            return calendar.date(
                byAdding: .month,
                value: 1,
                to: lastCompletedAt
            )
        }
    }

    // MARK: - Available

    var isAvailable: Bool {

        // Archived jobs can never be selected.

        guard !isArchived else {

            return false
        }

        // A job that has never been completed
        // should always be available immediately.

        guard lastCompletedAt != nil else {

            return true
        }

        // A completed one-off job is finished.

        if repeatRule == .once {

            return false
        }

        // Repeating jobs become available again
        // when their next due date arrives.

        guard let nextDueDate else {

            return true
        }

        return nextDueDate <= .now
    }

    // MARK: - Overdue

    var isOverdue: Bool {

        guard !isArchived else {

            return false
        }

        // Never-completed jobs are available,
        // but we don't call them overdue.

        guard lastCompletedAt != nil else {

            return false
        }

        guard
            repeatRule != .once,
            let nextDueDate
        else {

            return false
        }

        return nextDueDate <
            Calendar.current.startOfDay(
                for: .now
            )
    }

    // MARK: - Days Overdue

    var daysOverdue: Int {

        guard
            isOverdue,
            let nextDueDate
        else {

            return 0
        }

        return max(
            0,
            Calendar.current.dateComponents(
                [.day],
                from: nextDueDate,
                to: .now
            ).day ?? 0
        )
    }
}
