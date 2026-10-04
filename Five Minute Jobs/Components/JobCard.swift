import SwiftUI

struct JobCard: View {

    let job: Job
    let onComplete: () -> Void
    let onSkip: () -> Void

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                Label(
                    "\(job.estimatedMinutes) min",
                    systemImage: "clock"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                Text(job.category)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }

            Text(job.title)
                .font(.title2.bold())

            if !job.notes.isEmpty {
                Text(job.notes)
                    .foregroundStyle(.secondary)
            }

            Button {
                onComplete()
            } label: {
                Label(
                    "Job Done",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)

            Button("Pick Another") {
                onSkip()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}
