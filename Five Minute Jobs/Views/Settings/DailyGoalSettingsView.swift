import SwiftUI

struct DailyGoalSettingsView: View {

    // MARK: - Daily Goal

    @AppStorage("dailyJobGoal")
    private var dailyJobGoal =
        3

    private let goalOptions = [
        1,
        2,
        3,
        5,
        10
    ]

    // MARK: - Body

    var body: some View {

        List {

            Section {

                ForEach(
                    goalOptions,
                    id: \.self
                ) { goal in

                    Button {

                        dailyJobGoal =
                            goal

                    } label: {

                        HStack(
                            spacing: 14
                        ) {

                            Image(
                                systemName:
                                    icon(
                                        for: goal
                                    )
                            )
                            .frame(width: 28)
                            .foregroundStyle(
                                Color.accentColor
                            )

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {

                                Text(
                                    goalTitle(
                                        goal
                                    )
                                )
                                .foregroundStyle(
                                    .primary
                                )

                                Text(
                                    description(
                                        for: goal
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            if dailyJobGoal ==
                                goal {

                                Image(
                                    systemName:
                                        "checkmark"
                                )
                                .font(.headline)
                                .foregroundStyle(
                                    Color.accentColor
                                )
                            }
                        }
                        .contentShape(
                            Rectangle()
                        )
                    }
                    .buttonStyle(.plain)
                }

            } header: {

                Text("Jobs Per Day")

            } footer: {

                Text(
                    "Complete this many jobs in a day to reach your daily goal and continue your streak."
                )
            }
        }
        .navigationTitle(
            "Daily Goal"
        )
    }

    // MARK: - Title

    private func goalTitle(
        _ goal: Int
    ) -> String {

        if goal == 1 {

            return "1 Job"
        }

        return "\(goal) Jobs"
    }

    // MARK: - Description

    private func description(
        for goal: Int
    ) -> String {

        switch goal {

        case 1:
            return "One small win every day"

        case 2:
            return "Keep things easy"

        case 3:
            return "A balanced daily target"

        case 5:
            return "Build a strong routine"

        case 10:
            return "A productive challenge"

        default:
            return ""
        }
    }

    // MARK: - Icon

    private func icon(
        for goal: Int
    ) -> String {

        switch goal {

        case 1:
            return "checkmark.circle"

        case 2:
            return "bolt"

        case 3:
            return "target"

        case 5:
            return "flame"

        case 10:
            return "trophy"

        default:
            return "target"
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        DailyGoalSettingsView()
    }
}
