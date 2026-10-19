import SwiftUI

/// Browse every exercise in the dataset.
struct LibraryView: View {
    @Environment(\.exerciseLibrary) private var library
    @State private var searchText = ""
    @State private var muscle: String?

    var body: some View {
        let results = library.filtered(searchText: searchText, muscle: muscle)

        NavigationStack {
            List {
                Section {
                    MuscleFilterBar(muscles: library.muscleGroups, selection: $muscle)
                        .listRowInsets(EdgeInsets())
                }
                Section {
                    ForEach(results) { exercise in
                        NavigationLink(value: exercise) {
                            ExerciseRow(exercise: exercise)
                        }
                        .accessibilityIdentifier("library-exercise")
                    }
                } header: {
                    Text("\(results.count) \(results.count == 1 ? "exercise" : "exercises")")
                }
            }
            .overlay {
                if results.isEmpty, !library.exercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
}

/// Everything the dataset says about one exercise, with a shortcut to plan it.
struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(PlanStore.self) private var store
    @State private var addedTo: Weekday?

    var body: some View {
        Form {
            ExerciseInfoSections(exercise: exercise)
        }
        .navigationTitle(exercise.name)
        .toolbar {
            Menu {
                ForEach(Weekday.allCases) { day in
                    Button(day.name) {
                        store.plan.add([exercise], to: day)
                        addedTo = day
                    }
                }
            } label: {
                Label("Add to Day", systemImage: "calendar.badge.plus")
            }
        }
        .overlay(alignment: .bottom) {
            if let addedTo {
                Label("Added to \(addedTo.name)", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: addedTo)
        .task(id: addedTo) {
            guard addedTo != nil else { return }
            do {
                try await Task.sleep(for: .seconds(2))
                addedTo = nil
            } catch {
                // Replaced by a newer confirmation.
            }
        }
    }
}

/// Muscles, equipment, instructions and link for an exercise, as form sections.
struct ExerciseInfoSections: View {
    let exercise: Exercise

    var body: some View {
        Section("Details") {
            if !exercise.primaryMuscles.isEmpty {
                LabeledContent("Primary", value: exercise.muscleSummary)
            }
            if !exercise.secondaryMuscles.isEmpty {
                LabeledContent("Secondary", value: exercise.secondaryMuscles.map(\.capitalized).joined(separator: ", "))
            }
            if let equipment = exercise.equipment {
                LabeledContent("Equipment", value: equipment.capitalized)
            }
            if let category = exercise.category {
                LabeledContent("Type", value: category.capitalized)
            }
            if let level = exercise.level {
                LabeledContent("Level", value: level.capitalized)
            }
        }

        if !exercise.instructions.isEmpty {
            Section("How To") {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Text(step)
                    }
                }
            }
        }

        if let link = exercise.link {
            Section {
                Link(destination: link) {
                    Label("Watch How To", systemImage: "play.rectangle")
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .previewEnvironment()
}
