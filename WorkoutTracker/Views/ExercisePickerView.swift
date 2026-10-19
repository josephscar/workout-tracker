import SwiftUI

/// Pick one or more exercises from the library to add to a day.
struct ExercisePickerView: View {
    let day: Weekday

    @Environment(PlanStore.self) private var store
    @Environment(\.exerciseLibrary) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var muscle: String?
    /// Chosen exercise ids, in the order they were tapped.
    @State private var selection: [String] = []

    var body: some View {
        let results = library.filtered(searchText: searchText, muscle: muscle)
        let alreadyPlanned = Set(store.plan[day].exercises.map(\.exerciseID))

        NavigationStack {
            List {
                Section {
                    MuscleFilterBar(muscles: library.muscleGroups, selection: $muscle)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    ForEach(results) { exercise in
                        Button {
                            toggle(exercise)
                        } label: {
                            HStack {
                                ExerciseRow(exercise: exercise)
                                Spacer()
                                if alreadyPlanned.contains(exercise.id) {
                                    Text("Planned")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: selection.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selection.contains(exercise.id) ? Color.accentColor : Color.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .accessibilityAddTraits(selection.contains(exercise.id) ? .isSelected : [])
                    }
                } header: {
                    Text("\(results.count) \(results.count == 1 ? "exercise" : "exercises")")
                }
            }
            .overlay {
                if results.isEmpty {
                    if library.exercises.isEmpty {
                        ContentUnavailableView(
                            "No Exercises",
                            systemImage: "dumbbell",
                            description: Text("Add exercises to exercises.json to start planning.")
                        )
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
            .navigationTitle("Add to \(day.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selection.isEmpty ? "Add" : "Add (\(selection.count))") {
                        let chosen = selection.compactMap(library.exercise(id:))
                        store.plan.add(chosen, to: day)
                        dismiss()
                    }
                    .disabled(selection.isEmpty)
                }
            }
        }
    }

    private func toggle(_ exercise: Exercise) {
        if let index = selection.firstIndex(of: exercise.id) {
            selection.remove(at: index)
        } else {
            selection.append(exercise.id)
        }
    }
}

#Preview {
    Text("Day")
        .sheet(isPresented: .constant(true)) {
            ExercisePickerView(day: .monday)
        }
        .previewEnvironment()
}
