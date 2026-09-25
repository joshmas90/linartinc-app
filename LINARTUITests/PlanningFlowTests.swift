import XCTest

final class PlanningFlowTests: XCTestCase {
    func testPlanningNavigationAndAccessibleInquiry() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let skip = app.buttons["skipBrandIntroduction"]
        if skip.waitForExistence(timeout: 5), skip.isHittable { skip.tap() }
        XCTAssertTrue(app.buttons["Explore our work"].waitForExistence(timeout: 8))
        capture("01-home", app)
        tab("My Project", app)
        let studio = app.buttons["openStudio"]
        XCTAssertTrue(studio.waitForExistence(timeout: 5)); studio.tap()
        capture("02-studio-hub", app)
        app.buttons["studio-The spaces you imagine"].tap()
        let goals = app.textFields["What would you like to create?"]
        XCTAssertTrue(goals.waitForExistence(timeout: 5))
        goals.tap(); goals.typeText("More daylight and a calmer kitchen.")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["studio-Review & share"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "More daylight and a calmer kitchen.")).firstMatch.waitForExistence(timeout: 5))
        capture("03-review", app)
        XCUIDevice.shared.orientation = .landscapeLeft
        capture("04-review-landscape", app)
        XCUIDevice.shared.orientation = .portrait
        tab("More", app)
        app.buttons["Contact Us"].tap()
        app.buttons["Start a Project Inquiry"].tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Enter your name, up to 120 characters."].waitForExistence(timeout: 5))
        capture("05-inquiry-validation", app)
        app.buttons["Close"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Settings"].tap()
        capture("06-settings", app)
        app.buttons["Clear all local app data"].tap()
        app.buttons["Clear local data"].tap()
        tab("My Project", app)
        XCTAssertTrue(app.buttons["openStudio"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["More daylight and a calmer kitchen."].exists)
        capture("07-cleared-studio", app)
    }
    private func tab(_ name: String, _ app: XCUIApplication) {
        let tab = app.tabBars.buttons[name]
        if tab.exists { tab.tap() } else { app.buttons[name].firstMatch.tap() }
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name; screenshot.lifetime = .keepAlways; add(screenshot)
    }
}
