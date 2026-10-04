import SwiftUI

struct CategoryBadge: View {

    let categoryName: String

    private var category: JobCategory? {
        JobCategory(
            rawValue: categoryName
        )
    }

    var body: some View {

        Label(
            categoryName,
            systemImage:
                category?.icon ??
                "tag.fill"
        )
        .font(
            .caption.weight(.medium)
        )
        .foregroundStyle(
            Color.accentColor
        )
        .padding(
            .horizontal,
            10
        )
        .padding(
            .vertical,
            6
        )
        .background(
            Color.accentColor
                .opacity(0.12)
        )
        .clipShape(
            Capsule()
        )
        .accessibilityLabel(
            "\(categoryName) category"
        )
    }
}

// MARK: - Preview

#Preview {

    VStack(spacing: 16) {

        CategoryBadge(
            categoryName: "Home"
        )

        CategoryBadge(
            categoryName: "Cleaning"
        )

        CategoryBadge(
            categoryName: "Outside"
        )

        CategoryBadge(
            categoryName: "Car"
        )

        CategoryBadge(
            categoryName: "Digital"
        )
    }
    .padding()
}
