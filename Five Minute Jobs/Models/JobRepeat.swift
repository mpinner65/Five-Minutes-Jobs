import Foundation

enum JobRepeat: String, CaseIterable, Identifiable, Codable {

    case once = "One-off"
    case daily = "Daily"
    case weekly = "Weekly"
    case fortnightly = "Fortnightly"
    case monthly = "Monthly"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .once:
            return "1.circle"

        case .daily:
            return "sun.max"

        case .weekly:
            return "calendar"

        case .fortnightly:
            return "calendar.badge.clock"

        case .monthly:
            return "calendar.circle"
        }
    }

    var numberOfDays: Int? {
        switch self {
        case .once:
            return nil

        case .daily:
            return 1

        case .weekly:
            return 7

        case .fortnightly:
            return 14

        case .monthly:
            return 30
        }
    }
}
