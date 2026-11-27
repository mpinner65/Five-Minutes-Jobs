import Foundation
import SwiftData

struct JobPicker {

    // MARK: - Pick Job

    static func pickJob(
        from jobs: [Job],
        maximumMinutes: Int,
        disabledCategories: Set<String> = [],
        excluding excludedJob: Job? = nil,
        lowEnergy: Bool = false,
        room: String? = nil
    ) -> Job? {

        var candidates =
            jobs.filter { job in

                job.estimatedMinutes <=
                    maximumMinutes &&

                (!lowEnergy || job.effort == .easy) &&
                (room == nil || job.room == room) &&
                job.isAvailable &&

                !job.isArchived &&

                !disabledCategories.contains(
                    job.category
                )
            }

        // Avoid immediately showing the
        // same job again when alternatives
        // are available.

        if let excludedJob,
           candidates.count > 1 {

            candidates.removeAll { job in

                job.persistentModelID ==
                    excludedJob
                        .persistentModelID
            }
        }

        guard !candidates.isEmpty
        else {
            return nil
        }

        // MARK: - Score Jobs

        let scoredJobs =
            candidates.map { job in

                var score = job.pausedAt == nil ? 0 : 20

                // MARK: Priority

                switch job.priority {

                case 3:
                    score += 40

                case 2:
                    score += 25

                case 1:
                    score += 10

                default:
                    break
                }

                // MARK: Favourite

                // Favourite jobs receive a
                // useful boost without always
                // overriding higher-priority
                // or overdue jobs.

                if job.isFavourite {

                    score += 15
                }

                // MARK: Overdue

                // Overdue jobs get pushed
                // towards the top.

                if job.isOverdue {

                    score += 25

                    score += min(
                        job.daysOverdue * 3,
                        30
                    )
                }

                // MARK: Time Fit

                // Prefer jobs that make
                // good use of the selected
                // amount of time.

                let unusedMinutes =
                    maximumMinutes -
                    job.estimatedMinutes

                if unusedMinutes == 0 {

                    score += 10

                } else if unusedMinutes <= 5 {

                    score += 5
                }

                // MARK: Variety

                // Small random amount keeps
                // suggestions from feeling
                // too repetitive.

                score += Int.random(
                    in: 0...15
                )

                return ScoredJob(
                    job: job,
                    score: score
                )
            }

        return scoredJobs.max {
            $0.score < $1.score
        }?.job
    }
}

// MARK: - Scored Job

private struct ScoredJob {

    let job: Job

    let score: Int
}
