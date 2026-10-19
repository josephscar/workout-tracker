# Workout Tracker

An iPhone app for planning your training week. Each day of the week gets its own
workout: give it a name ("Push Day"), mark it as a rest day, or pick the exercises
you'll do from the exercise list and set sets, reps and weight for each one.

Version 2 will add a meal planner as a separate tab that works the same way:
meals with their nutrients and macros, plus a link or steps for making them.

## Run it

1. Open `WorkoutTracker.xcodeproj` in Xcode 16 or later.
2. Pick an iPhone simulator and press **Run** (⌘R).

To run it on your own iPhone, select the **WorkoutTracker** target, open
**Signing & Capabilities**, and choose your Apple ID under **Team**. A free Apple
ID works; Xcode may ask you to change the bundle identifier to something unique.

Requires iOS 17 or later.

## What's in it

| Tab | What you can do |
| --- | --- |
| **Plan** | See all seven days with today highlighted. Tap a day to name it, mark it as a rest day, add exercises, reorder or delete them, copy the day to another day, or clear it. Tap an exercise to set sets, reps, weight (lb or kg) and notes. |
| **Exercises** | Search and filter the full exercise list by muscle group, read how to do each one, and add it straight to any day. |

Your plan is saved on the device as you edit it.

## The exercise dataset

Exercises come from `WorkoutTracker/Resources/exercises.json`, a JSON array.
Only `name` is required:

```json
{
  "id": "barbell-bench-press",
  "name": "Barbell Bench Press",
  "primaryMuscles": ["chest"],
  "secondaryMuscles": ["triceps", "shoulders"],
  "equipment": "barbell",
  "category": "strength",
  "level": "intermediate",
  "defaultSets": 4,
  "defaultReps": 8,
  "instructions": ["Lie on the bench…", "Lower the bar…"],
  "link": "https://…"
}
```

- `id` can be a string or a number. If it's missing, one is made from the name.
- `primaryMuscles`, `secondaryMuscles` and `instructions` can be a list or a single string.
- `defaultSets`/`defaultReps` are used when the exercise is added to a day (otherwise 3 × 10).

If the file can't be read, the app tells you which entry and field are wrong.

## Project layout

```
WorkoutTracker/
  Core/        Models and logic with no UI: Weekday, Exercise, ExerciseLibrary,
               WeekPlan, JSONFileStorage
  Views/       SwiftUI screens
  PlanStore.swift   Holds the week plan and saves every change
  Resources/exercises.json
WorkoutTrackerTests/   Unit tests (Swift Testing)
```

## Tests

Run them in Xcode with ⌘U, or from the command line:

```sh
xcodebuild test -project WorkoutTracker.xcodeproj -scheme WorkoutTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

GitHub Actions builds the app and runs the tests on every push.
