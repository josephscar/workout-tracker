import SwiftUI

/// Name, muscles and equipment for an exercise in a list.
struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
                .font(.body)
                .foregroundStyle(.primary)
            Text(details)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var details: String {
        [exercise.muscleSummary, exercise.equipment?.capitalized ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

/// A horizontally scrolling row of muscle-group chips; `nil` means all.
struct MuscleFilterBar: View {
    let muscles: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isSelected: selection == nil) { selection = nil }
                ForEach(muscles, id: \.self) { muscle in
                    chip(muscle.capitalized, isSelected: selection == muscle) {
                        selection = selection == muscle ? nil : muscle
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? Color.accentColor : Color(uiColor: .secondarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// "3 × 10 · 135 lb" for a planned exercise.
struct TargetSummary: View {
    let planned: PlannedExercise
    @AppStorage(WeightUnit.storageKey) private var unit = WeightUnit.pounds

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }

    private var text: String {
        let target = "\(planned.sets) × \(planned.reps)"
        guard let weight = planned.weight else { return target }
        return "\(target) · \(weight.formatted(.number.precision(.fractionLength(0...1)))) \(unit.rawValue)"
    }
}
