import Foundation

/// A day of the week. Raw values follow ISO 8601 (Monday = 1 … Sunday = 7),
/// which is also the order the week is shown in.
enum Weekday: Int, CaseIterable, Codable, Identifiable, Comparable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    /// Maps Foundation's `Calendar` numbering (Sunday = 1 … Saturday = 7).
    init(calendarWeekday: Int) {
        let iso = ((calendarWeekday - 2) % 7 + 7) % 7 + 1
        self = Weekday(rawValue: iso)!
    }

    /// The weekday number `Calendar` uses for this day.
    var calendarWeekday: Int { rawValue % 7 + 1 }

    static func current(calendar: Calendar = .current, now: Date = .now) -> Weekday {
        Weekday(calendarWeekday: calendar.component(.weekday, from: now))
    }

    /// Localized full name, e.g. "Monday".
    var name: String {
        Calendar.current.standaloneWeekdaySymbols[calendarWeekday - 1]
    }

    /// Localized short name, e.g. "Mon".
    var shortName: String {
        Calendar.current.shortStandaloneWeekdaySymbols[calendarWeekday - 1]
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
