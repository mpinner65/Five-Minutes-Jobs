import SwiftUI
import SwiftData

struct AddJobView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var estimatedMinutes = 5
    @State private var categoryName = JobCategory.home.rawValue
    @State private var priority = 1
    @State private var repeatType = JobRepeat.once.rawValue
    @State private var notes = ""

    @State private var isSaving = false
    @State private var saveError: String?

    private var cleanTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !cleanTitle.isEmpty && estimatedMinutes > 0 && !isSaving
    }

    private var timeOptions: [Int] {
        Array(Set([5, 10, 15, 30] + [estimatedMinutes].filter { $0 > 0 })).sorted()
    }

    private var repeatExplanation: String {
        switch JobRepeat(rawValue: repeatType) {
        case .once:
            return "A one-off job is archived when completed. Its completion stays in your history."
        case .daily:
            return "Ready again one day after its last completion."
        case .weekly:
            return "Ready again seven days after its last completion."
        case .fortnightly:
            return "Ready again fourteen days after its last completion."
        case .monthly:
            return "Ready again one calendar month after its last completion."
        case nil:
            return "Choose a repeat option to set when this job becomes ready again."
        }
    }

    var body: some View {
        Form {
            Section {
                TextField("What needs doing?", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
            } header: {
                Text("Job")
            } footer: {
                Text(cleanTitle.isEmpty ? "Enter a job name to enable Save." : "Keep the name short and clear.")
            }

            Section("Time") {
                Picker("Estimated Time", selection: $estimatedMinutes) {
                    ForEach(timeOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Category") {
                Picker("Category", selection: $categoryName) {
                    if JobCategory(rawValue: categoryName) == nil {
                        Label(categoryName, systemImage: "tag.fill").tag(categoryName)
                    }
                    ForEach(JobCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category.rawValue)
                    }
                }
                .pickerStyle(.menu)
                CategoryBadge(categoryName: categoryName)
            }

            Section {
                Picker("Repeat", selection: $repeatType) {
                    if JobRepeat(rawValue: repeatType) == nil {
                        Text(repeatType).tag(repeatType)
                    }
                    ForEach(JobRepeat.allCases) { rule in
                        Label(rule.rawValue, systemImage: rule.icon).tag(rule.rawValue)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Repeat")
            } footer: {
                Text(repeatExplanation)
            }

            Section {
                Picker("Priority", selection: $priority) {
                    Text("Low").tag(0)
                    Text("Normal").tag(1)
                    Text("High").tag(2)
                    Text("Urgent").tag(3)
                    if !(0...3).contains(priority) {
                        Text("Current priority (\(priority))").tag(priority)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Priority")
            } footer: {
                Text("Higher priority jobs are more likely to be picked.")
            }

            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
            }
        }
        .navigationTitle("New Job")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(isSaving)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!canSave)
            }
        }
        .alert("Couldn’t Save Job", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        // Save unrelated pending changes before establishing this operation's baseline.
        do {
            if modelContext.hasChanges { try modelContext.save() }
        } catch {
            saveError = "Couldn’t save existing changes. Your form is still here so you can try again. \(error.localizedDescription)"
            return
        }

        let newJob = Job(
            title: cleanTitle,
            estimatedMinutes: estimatedMinutes,
            category: categoryName,
            priority: priority,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            repeatType: repeatType
        )
        modelContext.insert(newJob)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Revert the failed model change while leaving the form's draft intact.
            modelContext.rollback()
            saveError = "Couldn’t create this job. Your entries are still here so you can try again. \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack { AddJobView() }
        .modelContainer(for: Job.self, inMemory: true)
}
