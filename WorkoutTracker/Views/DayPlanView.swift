import SwiftUI

/// Build one day's workout: name it, pick exercises, set targets.
struct DayPlanView: View {
    let day: Weekday

    @Environment(PlanStore.self) private var store
    @State private var showingPicker = false
    @State private var editing: PlannedExercise?
    @State private var confirmingClear = false

    var body: some View {
        let plan = store.plan[day]

        List {
            Section {
                TextField("Workout name, e.g. Push Day", text: binding(\.title))
                Toggle("Rest day", isOn: binding(\.isRestDay))
            }

            if plan.isRestDay {
                Section {
                    Label("Recover today. Turn off Rest day to plan a workout.", systemImage: "bed.double")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(plan.exercises) { planned in
                        Button {
                            editing = planned
                        } label: {
                            PlannedExerciseRow(planned: planned)
                        }
                        .accessibilityIdentifier("planned-exercise")
                    }
                    .onDelete { offsets in
                        store.plan[day].exercises.remove(atOffsets: offsets)
                    }
                    .onMove { source, destination in
                        store.plan[day].exercises.move(fromOffsets: source, toOffset: destination)
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercises", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises")
                } footer: {
                    if plan.exercises.isEmpty {
                        Text("Choose the exercises you'll do on \(day.name).")
                    } else {
                        Text("Tap an exercise to set sets, reps and weight.")
                    }
                }
            }
        }
        .navigationTitle(day.name)
        .toolbar {
            if !plan.isRestDay, !plan.exercises.isEmpty {
                EditButton()
            }
            Menu {
                Menu("Copy To…", systemImage: "doc.on.doc") {
                    ForEach(Weekday.allCases.filter { $0 != day }) { other in
                        Button(other.name) {
                            store.plan.copy(day, to: other)
                        }
                    }
                }
                Button("Clear Day", systemImage: "trash", role: .destructive) {
                    confirmingClear = true
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
        .confirmationDialog("Clear \(day.name)?", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("Clear Day", role: .destructive) {
                store.plan.clear(day)
            }
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView(day: day)
        }
        .sheet(item: $editing) { planned in
            PlannedExerciseEditor(day: day, planned: planned)
        }
    }

    /// A binding to one field of this day's plan in the store.
    private func binding<Value>(_ field: WritableKeyPath<DayPlan, Value>) -> Binding<Value> {
        Binding(
            get: { store.plan[day][keyPath: field] },
            set: { store.plan[day][keyPath: field] = $0 }
        )
    }
}

private struct PlannedExerciseRow: View {
    let planned: PlannedExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(planned.name)
                    .foregroundStyle(.primary)
                TargetSummary(planned: planned)
                if !planned.notes.isEmpty {
                    Text(planned.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        DayPlanView(day: .monday)
    }
    .previewEnvironment()
}
