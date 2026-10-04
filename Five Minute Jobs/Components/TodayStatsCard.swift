import SwiftUI

struct TodayStatsCard: View {

    let readyCount: Int
    let overdueCount: Int
    let completedTodayCount: Int

    let onReadyTap: () -> Void
    let onOverdueTap: () -> Void
    let onCompletedTap: () -> Void

    var body: some View {

        HStack(spacing: 10) {

            Button {
                onReadyTap()
            } label: {
                stat(
                    title: "Ready",
                    value: readyCount,
                    icon: "bolt.fill"
                )
            }
            .buttonStyle(.plain)

            Button {
                onOverdueTap()
            } label: {
                stat(
                    title: "Overdue",
                    value: overdueCount,
                    icon:
                        "exclamationmark.circle.fill"
                )
            }
            Button {

                onCompletedTap()

            } label: {

                stat(
                    title: "Done Today",
                    value:
                        completedTodayCount,
                    icon:
                        "checkmark.circle.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stat

    private func stat(
        title: String,
        value: Int,
        icon: String
    ) -> some View {

        VStack(spacing: 8) {

            Image(
                systemName: icon
            )
            .font(.title3)
            .foregroundStyle(
                Color.accentColor
            )

            Text("\(value)")
                .font(
                    .title2.bold()
                )

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(1)
                .minimumScaleFactor(
                    0.75
                )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            14
        )
        .background(
            .regularMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }
}

// MARK: - Preview

#Preview {

    TodayStatsCard(
        readyCount: 8,
        overdueCount: 2,
        completedTodayCount: 3,
        onReadyTap: {},
        onOverdueTap: {},
        onCompletedTap: {}
    )
    .padding()
}
