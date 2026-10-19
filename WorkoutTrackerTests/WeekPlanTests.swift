import Foundation
import Testing
@testable import WorkoutTracker

struct WeekdayTests {
    @Test func mapsCalendarNumberingToMondayFirst() {
        #expect(Weekday(calendarWeekday: 1) == .sunday)
        #expect(Weekday(calendarWeekday: 2) == .monday)
        #expect(Weekday(calendarWeekday: 7) == .saturday)
        for day in Weekday.allCases {
            #expect(Weekday(calendarWeekday: day.calendarWeekday) == day)
        }
    }

    @Test func currentDayComesFromTheCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let monday = try #require(ISO8601DateFormatter().date(from: "2026-10-19T12:00:00Z"))
        let sunday = try #require(ISO8601DateFormatter().date(from: "2026-10-25T12:00:00Z"))
        #expect(Weekday.current(calendar: calendar, now: monday) == .monday)
        #expect(Weekday.current(calendar: calendar, now: sunday) == .sunday)
    }
}

struct WeekPlanTests {
    let bench = Exercise(id: "bench", name: "Bench Press", primaryMuscles: ["chest"], defaultSets: 4, defaultReps: 8)
    let row = Exercise(id: "row", name: "Barbell Row", primaryMuscles: ["middle back"])

    @Test func newPlanHasEveryDayInOrder() {
        let plan = WeekPlan()
        #expect(plan.days.map(\.weekday) == Weekday.allCases)
        #expect(plan.days.allSatisfy { $0.exercises.isEmpty && !$0.isRestDay && $0.title.isEmpty })
        #expect(plan.trainingDays.isEmpty)
    }

    @Test func addingUsesDatasetDefaultsAndKeepsOrder() {
        var plan = WeekPlan()
        plan.add([bench, row], to: .tuesday)

        let planned = plan[.tuesday].exercises
        #expect(planned.map(\.exerciseID) == ["bench", "row"])
        #expect(planned[0].sets == 4 && planned[0].reps == 8)
        #expect(planned[1].sets == 3 && planned[1].reps == 10)
        #expect(plan[.monday].exercises.isEmpty)
        #expect(plan.trainingDays.map(\.weekday) == [.tuesday])
    }

    @Test func addingToARestDayMakesItATrainingDay() {
        var plan = WeekPlan()
        plan[.friday].isRestDay = true
        plan.add([bench], to: .friday)
        #expect(!plan[.friday].isRestDay)
    }

    @Test func updateReplacesOnlyTheMatchingExercise() throws {
        var plan = WeekPlan()
        plan.add([bench, row], to: .monday)
        var edited = try #require(plan[.monday].exercises.first)
        edited.sets = 5
        edited.weight = 185
        edited.notes = "Pause at the chest"

        plan.update(edited, on: .monday)

        #expect(plan[.monday].exercises[0] == edited)
        #expect(plan[.monday].exercises[1].exerciseID == "row")
    }

    @Test func copyReplacesTargetWithFreshIDs() {
        var plan = WeekPlan()
        plan[.monday].title = "Push"
        plan.add([bench], to: .monday)
        plan.add([row], to: .thursday)

        plan.copy(.monday, to: .thursday)

        #expect(plan[.thursday].title == "Push")
        #expect(plan[.thursday].weekday == .thursday)
        #expect(plan[.thursday].exercises.map(\.exerciseID) == ["bench"])
        #expect(plan[.thursday].exercises[0].id != plan[.monday].exercises[0].id)
    }

    @Test func clearResetsOneDay() {
        var plan = WeekPlan()
        plan.add([bench], to: .monday)
        plan.add([row], to: .tuesday)
        plan.clear(.monday)
        #expect(plan[.monday] == DayPlan(weekday: .monday))
        #expect(plan[.tuesday].exercises.count == 1)
    }

    @Test func roundTripsThroughJSON() throws {
        var plan = WeekPlan()
        plan[.monday].title = "Push"
        plan.add([bench], to: .monday)
        plan[.monday].exercises[0].weight = 135
        plan[.sunday].isRestDay = true

        let data = try JSONEncoder().encode(plan)
        #expect(try JSONDecoder().decode(WeekPlan.self, from: data) == plan)
    }

    @Test func decodingToleratesMissingDaysAndFields() throws {
        let json = """
        {"days": [
          {"weekday": 3, "title": "Legs",
           "exercises": [{"exerciseID": "back-squat", "name": "Back Squat"}]},
          {"weekday": 7, "isRestDay": true}
        ]}
        """
        let plan = try JSONDecoder().decode(WeekPlan.self, from: Data(json.utf8))

        #expect(plan.days.map(\.weekday) == Weekday.allCases)
        #expect(plan[.wednesday].title == "Legs")
        #expect(plan[.wednesday].exercises.first?.sets == 3)
        #expect(plan[.wednesday].exercises.first?.reps == 10)
        #expect(plan[.wednesday].exercises.first?.weight == nil)
        #expect(plan[.sunday].isRestDay)
        #expect(plan[.monday] == DayPlan(weekday: .monday))
    }
}
