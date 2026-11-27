import SwiftUI

struct WeeklyRecapCard: View {
    let completions: [JobCompletion]
    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let recent = completions.filter { $0.completedAt >= start && $0.completedAt <= .now }
        let days = Set(recent.map { calendar.startOfDay(for: $0.completedAt) }).count
        VStack(alignment: .leading, spacing: 10) {
            Label("Your Gentle Weekly Recap", systemImage: "sparkles").font(.headline)
            Text("Last seven days").font(.caption).foregroundStyle(.secondary)
            if recent.isEmpty {
                Text("There’s room for a small win whenever you’re ready. Rest counts too.")
            } else {
                Text("You made room for \(recent.count) small \(recent.count == 1 ? "win" : "wins") across \(days) \(days == 1 ? "day" : "days").")
                Text("Every bit helped. There’s no catching up to do.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
