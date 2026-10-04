import Foundation

enum JobCategory: String, CaseIterable, Identifiable {

    case home = "Home"
    case cleaning = "Cleaning"
    case outside = "Outside"
    case car = "Car"
    case digital = "Digital"
    case admin = "Admin"
    case maintenance = "Maintenance"
    case errands = "Errands"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .home:
            return "house.fill"

        case .cleaning:
            return "sparkles"

        case .outside:
            return "leaf.fill"

        case .car:
            return "car.fill"

        case .digital:
            return "laptopcomputer"

        case .admin:
            return "doc.text.fill"

        case .maintenance:
            return "wrench.and.screwdriver.fill"

        case .errands:
            return "cart.fill"
        }
    }
}
