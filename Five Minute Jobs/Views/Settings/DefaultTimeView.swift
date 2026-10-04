import SwiftUI

struct DefaultTimeView: View {

    // MARK: - Saved Setting

    @AppStorage("defaultJobMinutes")
    private var defaultJobMinutes = 5

    // MARK: - Options

    private var timeOptions: [Int] {
        Array(Set([5, 10, 15, 30] + [defaultJobMinutes].filter { $0 > 0 })).sorted()
    }

    // MARK: - Body

    var body: some View {

        List {

            Section {

                ForEach(
                    timeOptions,
                    id: \.self
                ) { minutes in

                    Button {

                        defaultJobMinutes =
                            minutes

                    } label: {

                        HStack {

                            Image(
                                systemName:
                                    timeIcon(
                                        for: minutes
                                    )
                            )
                            .frame(width: 28)

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {

                                Text(
                                    "\(minutes) Minutes"
                                )
                                .foregroundStyle(
                                    .primary
                                )

                                Text(
                                    description(
                                        for: minutes
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            if defaultJobMinutes ==
                                minutes {

                                Image(
                                    systemName:
                                        "checkmark"
                                )
                                .font(
                                    .headline
                                )
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
                    .accessibilityAddTraits(defaultJobMinutes == minutes ? .isSelected : [])
                }

            } header: {

                Text("Starting Time")

            } footer: {

                Text(
                    "Saved automatically. This is your starting time when Today first opens. You can choose a different time during your session; it does not change a job’s estimate."
                )
            }
        }
        .navigationTitle(
            "Default Time"
        )
    }

    // MARK: - Description

    private func description(
        for minutes: Int
    ) -> String {

        switch minutes {

        case 5:
            return "Quick wins"

        case 10:
            return "Small jobs"

        case 15:
            return "Get something useful done"

        case 30:
            return "Tackle a bigger job"

        default:
            return "Your saved custom starting time"
        }
    }

    // MARK: - Icon

    private func timeIcon(
        for minutes: Int
    ) -> String {

        switch minutes {

        case 5:
            return "bolt.fill"

        case 10:
            return "clock.fill"

        case 15:
            return "timer"

        case 30:
            return "hourglass"

        default:
            return "clock"
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        DefaultTimeView()
    }
}
