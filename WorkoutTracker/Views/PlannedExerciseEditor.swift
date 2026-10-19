import SwiftUI

/// Set the sets, reps, weight and notes for an exercise on a day.
struct PlannedExerciseEditor: View {
    let day: Weekday

    @Environment(PlanStore.self) private var store
    @Environment(\.exerciseLibrary) private var library
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WeightUnit.storageKey) private var unit = WeightUnit.pounds
    @State private var draft: PlannedExercise
    @State private var weightText: String

    init(day: Weekday, planned: PlannedExercise) {
        self.day = day
        _draft = State(initialValue: planned)
        _weightText = State(initialValue: planned.weight.map { $0.formatted(.number.grouping(.never)) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Target") {
                    Stepper(value: $draft.sets, in: 1...20) {
                        LabeledContent("Sets", value: "\(draft.sets)")
                    }
                    Stepper(value: $draft.reps, in: 1...100) {
                        LabeledContent("Reps", value: "\(draft.reps)")
                    }
                    LabeledContent("Weight") {
                        HStack(spacing: 4) {
                            TextField("Bodyweight", text: $weightText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(unit.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Tempo, rest time, cues…", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let exercise = library.exercise(id: draft.exerciseID) {
                    ExerciseInfoSections(exercise: exercise)
                }

                Section {
                    Button("Remove from \(day.name)", role: .destructive) {
                        store.plan[day].exercises.removeAll { $0.id == draft.id }
                        dismiss()
                    }
                }
            }
            .navigationTitle(draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!weightIsValid)
                }
            }
        }
    }

    private var parsedWeight: Double? {
        let text = weightText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        return try? Double(text, format: .number)
    }

    private var weightIsValid: Bool {
        weightText.trimmingCharacters(in: .whitespaces).isEmpty || (parsedWeight ?? -1) >= 0
    }

    private func save() {
        var updated = draft
        updated.weight = parsedWeight
        store.plan.update(updated, on: day)
        dismiss()
    }
}

#Preview {
    PlannedExerciseEditor(
        day: .monday,
        planned: PlannedExercise(exerciseID: "barbell-bench-press", name: "Barbell Bench Press", sets: 4, reps: 8, weight: 135)
    )
    .previewEnvironment()
}
