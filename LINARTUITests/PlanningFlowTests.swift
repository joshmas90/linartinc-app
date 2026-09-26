import XCTest

final class PlanningFlowTests: XCTestCase {
    func testPlanningNavigationAndAccessibleInquiry() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL", "-LINARTDisableWelcomeAutoDismiss"]
        app.launch()
        let skip = app.buttons["Continue to LINART"]
        if skip.waitForExistence(timeout: 5), skip.isHittable { skip.tap() }
        XCTAssertTrue(app.buttons["Explore our work"].waitForExistence(timeout: 8))
        capture("01-home", app)
        tab("My Project", app)
        let studio = app.buttons["openStudio"]
        tapWhenVisible(studio, in: app)
        chooseStep("details", in: app)
        capture("02-guided-project-details", app)
        let goals = app.textFields["What would you like to create?"]
        XCTAssertTrue(goals.waitForExistence(timeout: 5))
        tapWhenVisible(goals, in: app); goals.typeText("More daylight and a calmer kitchen.")
        app.toolbars.buttons["Done"].tap()
        tapWhenVisible(app.buttons["studioContinue"], in: app)
        XCTAssertTrue(identified("studioAddPhotos", in: app).waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["studioSkip"], in: app)
        tapWhenVisible(app.buttons["studioAddLink"], in: app)
        let address = app.textFields["Full web address"]
        XCTAssertTrue(address.waitForExistence(timeout: 5))
        address.tap(); address.typeText("https://example.com/kitchen")
        app.navigationBars.buttons["Add link"].tap()
        XCTAssertTrue(app.staticTexts["https://example.com/kitchen"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["studioContinue"], in: app)
        XCTAssertTrue(app.textFields["Ideal project timing"].waitForExistence(timeout: 5))
        app.buttons["studioBack"].tap()
        XCTAssertTrue(app.staticTexts["https://example.com/kitchen"].waitForExistence(timeout: 5))
        app.buttons["studioContinue"].tap()
        app.buttons["studioSkip"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "More daylight and a calmer kitchen.")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["studioSend"].isEnabled)
        tapWhenVisible(app.buttons["studioEdit-details"], in: app)
        let editedGoals = app.textFields["What would you like to create?"]
        XCTAssertTrue(editedGoals.waitForExistence(timeout: 5))
        tapWhenVisible(editedGoals, in: app); editedGoals.typeText(" Natural finishes.")
        app.toolbars.buttons["Done"].tap()
        app.buttons["studioContinue"].tap()
        XCTAssertTrue(app.buttons["studioSend"].waitForExistence(timeout: 5))
        capture("03-review", app)
        XCTAssertFalse(identified("studioEdit-photos", in: app).exists, "Unanswered sections stay collapsed")
        tapWhenVisible(identified("studioOptionalDetails", in: app), in: app)
        tapWhenVisible(identified("studioEdit-photos", in: app), in: app)
        XCTAssertTrue(identified("studioAddPhotos", in: app).waitForExistence(timeout: 5))
        app.buttons["studioContinue"].tap()
        tapWhenVisible(app.buttons["studioSend"], in: app)
        XCTAssertTrue(app.textFields["projectSignInEmail"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Delete my app account"].exists)
        XCTAssertFalse(app.buttons["Refresh submissions"].exists)
        XCTAssertFalse(app.staticTexts["projectSendSuccess"].exists, "Opening send must never show an earlier receipt")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        settleRotation(app, landscape: true)
        capture("04-review-landscape", app)
        XCUIDevice.shared.orientation = .portrait
        settleRotation(app, landscape: false)
        tapWhenVisible(app.buttons["studioSaveForLater"], in: app)
        XCTAssertTrue(app.buttons["openStudio"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        tab("My Project", app)
        tapWhenVisible(app.buttons["openStudio"], in: app)
        XCTAssertTrue(app.buttons["studioSend"].waitForExistence(timeout: 5), "The draft should reopen at the review step")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "More daylight and a calmer kitchen.")).firstMatch.exists)
        XCTAssertFalse(app.tabBars.buttons["More"].isHittable, "The planner should be a focused flow without competing tab navigation")
        tapWhenVisible(app.buttons["studioSaveForLater"], in: app)
        tab("More", app)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Contact Us,")).firstMatch.tap()
        app.buttons["Start a Project Inquiry"].tap()
        let next = app.buttons["Continue"]
        for _ in 0..<4 {
            if next.exists && next.isHittable { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(next.isHittable); next.tap()
        XCTAssertTrue(app.staticTexts["Enter your name, up to 120 characters."].waitForExistence(timeout: 5))
        let invalidName = app.textFields["Full name, required"]
        let revealed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in invalidName.isHittable }, object: invalidName)
        XCTAssertEqual(XCTWaiter.wait(for: [revealed], timeout: 5), .completed)
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
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-LINARTDisableWelcomeAutoDismiss"]
        app.launch()
        let skip = app.buttons["Continue to LINART"]
        if skip.waitForExistence(timeout: 5), skip.isHittable { skip.tap() }
        capture("08-large-text-home", app)
        tab("My Project", app)
        let studio = app.buttons["openStudio"]
        tapWhenVisible(studio, in: app)
        chooseStep("photos", in: app)
        XCTAssertTrue(app.buttons["studioContinue"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["studioContinue"].isHittable)
        capture("09-large-text-studio", app)
    }
    func testSkipEmptyPlanAndResume() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments.append("-LINARTDisableWelcomeAutoDismiss")
        app.launch()
        let welcome = app.buttons["Continue to LINART"]
        if welcome.waitForExistence(timeout: 5), welcome.isHittable { welcome.tap() }
        tab("More", app)
        let settings = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Settings,")).firstMatch
        tapWhenVisible(settings, in: app)
        app.buttons["Clear all local app data"].tap()
        app.buttons["Clear local data"].tap()
        tab("My Project", app)
        tapWhenVisible(app.buttons["openStudio"], in: app)
        for _ in 0..<4 { tapWhenVisible(app.buttons["studioSkip"], in: app) }
        let send = app.buttons["studioSend"]
        XCTAssertTrue(send.waitForExistence(timeout: 5))
        XCTAssertFalse(send.isEnabled, "An empty plan must not look ready to send")
        app.buttons["studioBack"].tap()
        XCTAssertTrue(app.textFields["Ideal project timing"].waitForExistence(timeout: 5))
        app.buttons["Project options"].tap()
        app.buttons["Save & close"].tap()
        tapWhenVisible(app.buttons["openStudio"], in: app)
        XCTAssertTrue(app.textFields["Ideal project timing"].waitForExistence(timeout: 5))
        app.buttons["studioSkip"].tap()
        XCTAssertFalse(app.buttons["studioSend"].isEnabled)
    }

    func testProjectGuidanceAndDeliberateInspirationSelection() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments.append("-LINARTDisableWelcomeAutoDismiss")
        app.launch()
        let welcome = app.buttons["Continue to LINART"]
        if welcome.waitForExistence(timeout: 5), welcome.isHittable { welcome.tap() }
        tab("More", app)
        tapWhenVisible(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Settings,")).firstMatch, in: app)
        app.buttons["Clear all local app data"].tap()
        app.buttons["Clear local data"].tap()
        tab("My Project", app)
        tapWhenVisible(app.buttons["openStudio"], in: app)
        tapWhenVisible(app.buttons["studioProjectType"], in: app)
        app.buttons["Kitchen Remodeling"].tap()
        let goals = app.textFields["What would you like to create?"]
        tapWhenVisible(goals, in: app)
        goals.typeText("Keep these personal notes.")
        app.toolbars.buttons["Done"].tap()
        tapWhenVisible(app.buttons["studioProjectType"], in: app)
        app.buttons["Bathroom Remodeling"].tap()
        XCTAssertEqual(goals.value as? String, "Keep these personal notes.")
        app.buttons["studioContinue"].tap()
        XCTAssertTrue(app.staticTexts["studioPhotoGuidance"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["studioPhotoGuidance"].label.contains("shower"))
        app.buttons["studioSkip"].tap()
        tapWhenVisible(app.buttons["studioChooseIdeas"], in: app)
        // SwiftUI NavigationLink can surface as either a button or link across iOS simulator releases.
        let preview = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "studioPreview-")).firstMatch
        tapWhenVisible(preview, in: app)
        let add = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "studioIdea-")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertTrue(add.isEnabled, "Previewing must not silently add inspiration")
        add.tap()
        XCTAssertFalse(add.isEnabled)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons["Done"].tap()
        chooseStep("review", in: app)
        XCTAssertTrue(app.buttons["studioEdit-links"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["studioSend"].isEnabled)
        app.buttons["studioSend"].tap()
        let email = app.textFields["projectSignInEmail"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        let requestLink = app.buttons["projectRequestSignIn"]
        XCTAssertFalse(requestLink.isEnabled)
        tapWhenVisible(email, in: app)
        email.typeText("client")
        XCTAssertFalse(requestLink.isEnabled, "An incomplete address cannot request a link")
        email.typeText("@example.com")
        app.toolbars.buttons["Done"].tap()
        XCTAssertTrue(requestLink.isEnabled)
        XCTAssertFalse(app.buttons["Delete my app account"].exists)
        // Verify the form without sending a real sign-in email or uploading data.
        capture("10-focused-verify-send", app)
    }

    private func chooseStep(_ id: String, in app: XCUIApplication) {
        app.buttons["studioSteps"].tap()
        tapWhenVisible(app.buttons["studio-\(id)"], in: app)
    }

    private func identified(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
    }

    private func tapWhenVisible(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.exists && element.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
        element.tap()
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
            let nextPage = app.buttons["Next Page"]
            // UIKit can expose a clipped tab as existing/hittable even though
            // its center lies underneath the paging control. Reveal it first.
            if nextPage.exists && (!target.exists || target.frame.maxX > nextPage.frame.minX) {
                nextPage.tap()
            } else if !target.exists {
                let previousPage = app.buttons["Previous Page"]
                if previousPage.exists { previousPage.tap() }
            }
            if !target.waitForExistence(timeout: 5) { print(app.debugDescription) }
            XCTAssertTrue(target.exists); target.tap()
        }
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let settled = expectation(description: "Navigation animation settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = name; screenshot.lifetime = .keepAlways; add(screenshot)
    }
}
