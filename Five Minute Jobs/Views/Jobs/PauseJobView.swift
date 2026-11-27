import SwiftUI
import SwiftData

struct PauseJobView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let job: Job
    @State private var step: String
    @State private var error: String?
    init(job: Job) {
        self.job = job
        _step = State(initialValue: job.resumeStep)
    }
    var body: some View {
        Form {
            Section {
                TextField("For example: Put the clean dishes away", text: $step, axis: .vertical)
                    .lineLimit(3...6)
            } header: { Text("Next small step") } footer: {
                Text("Save where you stopped. This does not record a completion or change the repeat schedule.")
            }
        }
        .navigationTitle("Pick Up Later")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(step.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .alert("Couldn’t Save Next Step", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) { error = nil }
        } message: { Text(error ?? "Please try again.") }
    }
    private func save() {
        do { if context.hasChanges { try context.save() } }
        catch { self.error = error.localizedDescription; return }
        job.nextStep = step.trimmingCharacters(in: .whitespacesAndNewlines)
        job.pausedAt = .now
        do { try context.save(); dismiss() }
        catch { context.rollback(); self.error = error.localizedDescription }
    }
}
