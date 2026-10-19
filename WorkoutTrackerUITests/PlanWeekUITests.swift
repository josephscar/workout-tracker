import XCTest

/// Walks through planning a week the way you would in the app. Screenshots
/// are kept in the test results so the screens can be reviewed.
final class PlanWeekUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testPlanningAWeek() throws {
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        XCTAssert(app.navigationBars["This Week"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'day-'")).count, 7)
        screenshot("1 Week, empty")

        // Name Monday and pick two exercises for it.
        day("monday").tap()
        let name = app.textFields["Workout name, e.g. Push Day"]
        XCTAssert(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Push Day\n")

        app.buttons["Add Exercises"].tap()
        let options = app.buttons.matching(identifier: "exercise-option")
        XCTAssert(options.firstMatch.waitForExistence(timeout: 5))
        options.element(boundBy: 0).tap()
        options.element(boundBy: 1).tap()
        screenshot("2 Picker, two selected")
        app.buttons["Add (2)"].tap()

        let planned = app.buttons.matching(identifier: "planned-exercise")
        XCTAssert(planned.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(planned.count, 2)

        // Set a weight on the first exercise.
        planned.element(boundBy: 0).tap()
        let weight = app.textFields["Bodyweight"]
        XCTAssert(weight.waitForExistence(timeout: 5))
        screenshot("3 Exercise editor")
        weight.tap()
        weight.typeText("135")
        app.buttons["Save"].tap()
        XCTAssert(planned.element(boundBy: 0).waitForExistence(timeout: 5))
        XCTAssert(planned.element(boundBy: 0).label.contains("135 lb"), planned.element(boundBy: 0).label)
        screenshot("4 Monday planned")

        // Copy Monday to Thursday.
        app.navigationBars.buttons["More"].tap()
        app.buttons["Copy To…"].tap()
        app.buttons["Thursday"].tap()
        goBack()

        XCTAssert(day("monday").label.contains("Push Day · 2 exercises"), day("monday").label)
        XCTAssert(day("thursday").label.contains("Push Day · 2 exercises"), day("thursday").label)

        // Make Sunday a rest day.
        day("sunday").tap()
        let restDay = app.switches["Rest day"]
        XCTAssert(restDay.waitForExistence(timeout: 5))
        restDay.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(restDay.value as? String, "1")
        goBack()
        XCTAssert(day("sunday").label.contains("Rest day"), day("sunday").label)

        // Add an exercise to Wednesday from the Exercises tab.
        app.tabBars.buttons["Exercises"].tap()
        let libraryRow = app.buttons.matching(identifier: "library-exercise").firstMatch
        XCTAssert(libraryRow.waitForExistence(timeout: 5))
        screenshot("5 Exercise list")
        libraryRow.tap()
        app.navigationBars.buttons["Add to Day"].tap()
        app.buttons["Wednesday"].tap()
        let banner = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Added to Wednesday'")).firstMatch
        XCTAssert(banner.waitForExistence(timeout: 3))
        screenshot("6 Exercise detail")

        app.tabBars.buttons["Plan"].tap()
        XCTAssert(day("wednesday").waitForExistence(timeout: 5))
        XCTAssert(day("wednesday").label.contains("1 exercise"), day("wednesday").label)
        screenshot("7 Week, planned")
    }

    @MainActor
    private func day(_ id: String) -> XCUIElement {
        app.buttons["day-\(id)"]
    }

    @MainActor
    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssert(app.navigationBars["This Week"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
