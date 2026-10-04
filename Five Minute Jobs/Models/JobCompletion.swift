import Foundation
import SwiftData

@Model
final class JobCompletion {

    var jobTitle: String
    var category: String
    var estimatedMinutes: Int
    var completedAt: Date

    init(
        jobTitle: String,
        category: String,
        estimatedMinutes: Int,
        completedAt: Date = .now
    ) {
        self.jobTitle = jobTitle
        self.category = category
        self.estimatedMinutes = estimatedMinutes
        self.completedAt = completedAt
    }
}
