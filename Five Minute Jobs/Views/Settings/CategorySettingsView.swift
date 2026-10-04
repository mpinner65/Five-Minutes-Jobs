import SwiftUI

struct CategorySettingsView: View {

    // MARK: - Disabled Categories

    @AppStorage("disabledJobCategories")
    private var disabledCategoriesData = ""

    // MARK: - Body

    var body: some View {

        List {

            Section {

                ForEach(JobCategory.allCases) { category in

                    Toggle(
                        isOn: binding(
                            for: category
                        )
                    ) {

                        Label(
                            category.rawValue,
                            systemImage:
                                category.icon
                        )
                    }
                }

            } header: {

                Text("Job Categories")

            } footer: {

                Text(
                    "Turn off categories you don't want Five Minute Jobs to suggest. Your jobs will not be deleted."
                )
            }

            Section {

                Button(
                    "Enable All Categories"
                ) {

                    disabledCategoriesData = ""
                }
                .disabled(
                    disabledCategories.isEmpty
                )
            }
        }
        .navigationTitle("Categories")
    }

    // MARK: - Disabled Categories

    private var disabledCategories:
        Set<String> {

        Set(
            disabledCategoriesData
                .split(separator: "|")
                .map(String.init)
        )
    }

    // MARK: - Category Binding

    private func binding(
        for category: JobCategory
    ) -> Binding<Bool> {

        Binding {

            !disabledCategories.contains(
                category.rawValue
            )

        } set: { enabled in

            var categories =
                disabledCategories

            if enabled {

                categories.remove(
                    category.rawValue
                )

            } else {

                categories.insert(
                    category.rawValue
                )
            }

            disabledCategoriesData =
                categories
                    .sorted()
                    .joined(
                        separator: "|"
                    )
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        CategorySettingsView()
    }
}
