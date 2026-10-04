import SwiftUI

struct AppearanceSettingsView: View {

    // MARK: - Saved Appearance

    @AppStorage("appAppearance")
    private var appAppearance =
        AppAppearance.system.rawValue

    // MARK: - Body

    var body: some View {

        List {

            Section {

                ForEach(
                    AppAppearance.allCases
                ) { appearance in

                    Button {

                        appAppearance =
                            appearance.rawValue

                    } label: {

                        HStack(
                            spacing: 14
                        ) {

                            Image(
                                systemName:
                                    appearance.icon
                            )
                            .font(.title3)
                            .frame(width: 28)
                            .foregroundStyle(
                                .primary
                            )

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {

                                Text(
                                    appearance.title
                                )
                                .foregroundStyle(
                                    .primary
                                )

                                Text(
                                    appearance.description
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            if appAppearance ==
                                appearance.rawValue {

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
                }

            } header: {

                Text("Appearance")

            } footer: {

                Text(
                    "System automatically follows your iPhone's Light or Dark appearance."
                )
            }
        }
        .navigationTitle(
            "Appearance"
        )
    }
}

// MARK: - App Appearance

enum AppAppearance:
    String,
    CaseIterable,
    Identifiable {

    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var title: String {

        switch self {

        case .system:
            return "System"

        case .light:
            return "Light"

        case .dark:
            return "Dark"
        }
    }

    var description: String {

        switch self {

        case .system:
            return "Match your iPhone"

        case .light:
            return "Always use Light Mode"

        case .dark:
            return "Always use Dark Mode"
        }
    }

    var icon: String {

        switch self {

        case .system:
            return "circle.lefthalf.filled"

        case .light:
            return "sun.max.fill"

        case .dark:
            return "moon.fill"
        }
    }

    var colorScheme:
        ColorScheme? {

        switch self {

        case .system:
            return nil

        case .light:
            return .light

        case .dark:
            return .dark
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        AppearanceSettingsView()
    }
}
