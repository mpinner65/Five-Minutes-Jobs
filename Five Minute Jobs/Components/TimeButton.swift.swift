import SwiftUI

struct TimeButton: View {

    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.title2.bold())

                Text("min")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                        ? Color.accentColor
                        : Color.secondary.opacity(0.12)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
