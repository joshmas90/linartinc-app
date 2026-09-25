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
        settleRotation(app, landscape: true)
        capture("04-review-landscape", app)
        XCUIDevice.shared.orientation = .portrait
        settleRotation(app, landscape: false)
        tab("More", app)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Contact Us,")).firstMatch.tap()
        app.buttons["Start a Project Inquiry"].tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Enter your name, up to 120 characters."].waitForExistence(timeout: 5))
        capture("05-inquiry-validation", app)
        app.buttons["Close"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let settings = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Settings,")).firstMatch
        if !settings.isHittable { app.swipeUp() }
        settings.tap()
        capture("06-settings", app)
        app.buttons["Clear all local app data"].tap()
        app.buttons["Clear local data"].tap()
        tab("My Project", app)
        for _ in 0..<2 where !app.buttons["openStudio"].exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        XCTAssertTrue(app.buttons["openStudio"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["More daylight and a calmer kitchen."].exists)
        capture("07-cleared-studio", app)
    }
    func testLargeTextPlanning() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let skip = app.buttons["skipBrandIntroduction"]
        if skip.waitForExistence(timeout: 5), skip.isHittable { skip.tap() }
        capture("08-large-text-home", app)
        tab("My Project", app)
        let studio = app.buttons["openStudio"]
        XCTAssertTrue(studio.waitForExistence(timeout: 5))
        if !studio.isHittable { app.swipeUp() }
        XCTAssertTrue(studio.isHittable); studio.tap()
        capture("09-large-text-studio", app)
    }
    private func settleRotation(_ app: XCUIApplication, landscape: Bool) {
        let frame = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            landscape ? app.frame.width > app.frame.height : app.frame.height > app.frame.width
        }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [frame], timeout: 5), .completed)
        // Wait for UIKit's orientation animation, not just the new screen bounds.
        let settled = expectation(description: "Rotation animation settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { settled.fulfill() }
        wait(for: [settled], timeout: 3)
    }
    private func tab(_ name: String, _ app: XCUIApplication) {
        let tab = app.tabBars.buttons[name]
        if tab.exists { tab.tap() }
        else {
            // iPad floating tabs may be exposed as cells after rotation on iOS 26.
            let target = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", name)).firstMatch
            if !target.exists {
                let page = app.buttons[name == "More" ? "Next Page" : "Previous Page"]
                if page.exists { page.tap() }
            }
            if !target.waitForExistence(timeout: 5) { print(app.debugDescription) }
            XCTAssertTrue(target.exists); target.tap()
        }
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name; screenshot.lifetime = .keepAlways; add(screenshot)
    }
}
