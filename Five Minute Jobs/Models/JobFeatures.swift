import Foundation

enum JobEffort: String, CaseIterable, Identifiable {
    case easy = "Easy", moderate = "Moderate", demanding = "Demanding"
    var id: String { rawValue }
}

enum JobRooms {
    static let all = ["Unassigned", "Kitchen", "Bedroom", "Bathroom", "Living Room", "Garden", "Garage", "Office", "Other"]
}

struct JobTemplate: Identifiable {
    let id: String
    let title: String
    let minutes: Int
    let category: String
    let repeatType: String
    let room: String
    let effort: JobEffort
    static let all: [JobTemplate] = [
        .init(id: "bench", title: "Wipe kitchen bench", minutes: 5, category: "Cleaning", repeatType: JobRepeat.daily.rawValue, room: "Kitchen", effort: .easy),
        .init(id: "drawer", title: "Tidy one drawer", minutes: 5, category: "Home", repeatType: JobRepeat.once.rawValue, room: "Bedroom", effort: .easy),
        .init(id: "plants", title: "Water garden plants", minutes: 10, category: "Outside", repeatType: JobRepeat.weekly.rawValue, room: "Garden", effort: .moderate),
        .init(id: "bills", title: "Check upcoming bills", minutes: 10, category: "Admin", repeatType: JobRepeat.weekly.rawValue, room: "Office", effort: .easy),
        .init(id: "bathroom", title: "Clean bathroom sink", minutes: 5, category: "Cleaning", repeatType: JobRepeat.weekly.rawValue, room: "Bathroom", effort: .easy),
        .init(id: "weeds", title: "Weed a small garden patch", minutes: 15, category: "Outside", repeatType: JobRepeat.fortnightly.rawValue, room: "Garden", effort: .demanding)
    ]
}
