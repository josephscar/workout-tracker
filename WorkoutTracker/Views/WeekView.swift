import SwiftUI

/// The seven days of the week and what's planned for each.
struct WeekView: View {
    @Environment(PlanStore.self) private var store
    @AppStorage(WeightUnit.storageKey) private var unit = WeightUnit.pounds
    @State private var confirmingClear = false

    var body: some View {
        let today = Weekday.current()

        NavigationStack {
            List {
                Section {
                    ForEach(store.plan.days) { day in
                        NavigationLink(value: day.weekday) {
                            DayRow(day: day, isToday: day.weekday == today)
                        }
                    }
                } footer: {
                    Text(summary)
                }
            }
            .navigationTitle("This Week")
            .navigationDestination(for: Weekday.self) { day in
                DayPlanView(day: day)
            }
            .toolbar {
                Menu {
                    Picker("Weight Unit", selection: $unit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    Button("Clear Week", systemImage: "trash", role: .destructive) {
                        confirmingClear = true
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
            .confirmationDialog("Clear every day's plan?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Clear Week", role: .destructive) {
                    store.plan = WeekPlan()
                }
            }
        }
    }

    private var summary: String {
        let days = store.plan.trainingDays
        let exercises = days.reduce(0) { $0 + $1.exercises.count }
        if days.isEmpty {
            return "Tap a day to plan its workout."
        }
        return "\(days.count) training \(days.count == 1 ? "day" : "days") · \(exercises) \(exercises == 1 ? "exercise" : "exercises") planned"
    }
}

private struct DayRow: View {
    let day: DayPlan
    let isToday: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(day.weekday.shortName.uppercased())
                .font(.caption.weight(.bold))
                .frame(width: 44, height: 44)
                .foregroundStyle(isToday ? Color.white : Color.accentColor)
                .background(
                    isToday ? Color.accentColor : Color.accentColor.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(day.weekday.name)
                        .font(.headline)
                    if isToday {
                        Text("Today")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !day.isRestDay, !day.exercises.isEmpty {
                    Text(day.exercises.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var status: String {
        if day.isRestDay {
            return "Rest day"
        }
        let count = day.exercises.count
        let exercises = count == 0 ? "Nothing planned" : "\(count) \(count == 1 ? "exercise" : "exercises")"
        return day.title.isEmpty ? exercises : "\(day.title) · \(exercises)"
    }
}

#Preview {
    WeekView()
        .previewEnvironment()
}
