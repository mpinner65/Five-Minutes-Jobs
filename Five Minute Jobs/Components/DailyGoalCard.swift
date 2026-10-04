import SwiftUI

struct DailyGoalCard: View {

    let completedToday: Int
    let dailyGoal: Int
    let currentStreak: Int

    // MARK: - Progress

    private var progress:
        Double {

        guard dailyGoal > 0
        else {

            return 0
        }

        return min(
            Double(completedToday) /
            Double(dailyGoal),
            1
        )
    }

    private var goalReached:
        Bool {

        completedToday >=
            dailyGoal
    }

    // MARK: - Body

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            header

            progressSection
        }
        .padding(18)
        .background(
            .regularMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }

    // MARK: - Header

    private var header:
        some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Daily Goal")
                    .font(.headline)

                Text(goalMessage)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Spacer()

            Label(
                "\(currentStreak)",
                systemImage:
                    "flame.fill"
            )
            .font(.headline)
            .foregroundStyle(
                .orange
            )
        }
    }

    // MARK: - Progress Section

    private var progressSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text(
                    "\(completedToday) of \(dailyGoal) jobs"
                )
                .font(
                    .subheadline.bold()
                )

                Spacer()

                if goalReached {

                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        .green
                    )
                }
            }

            ProgressView(
                value: progress
            )
            .tint(
                goalReached
                ? .green
                : Color.accentColor
            )
        }
    }

    // MARK: - Goal Message

    private var goalMessage:
        String {

        if goalReached {

            return "Goal complete!"
        }

        let remaining =
            max(
                dailyGoal -
                completedToday,
                0
            )

        if remaining == 1 {

            return
                "1 more job to reach today's goal."
        }

        return
            "\(remaining) more jobs to reach today's goal."
    }
}

// MARK: - Preview

#Preview {

    DailyGoalCard(
        completedToday: 2,
        dailyGoal: 3,
        currentStreak: 4
    )
    .padding()
}
