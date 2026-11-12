//
//  StiintUITestsLaunchTests.swift
//  StiintUITests
//
//  Created by Liam Wittig on 10.12.25.
//

import XCTest

final class StiintUITestsLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsWelcomeOrMainTabs() {
        let app = XCUIApplication()
        app.launch()
        let mainTabs = app.tabBars.buttons["Tasks"]
        let welcome = app.buttons["Let's Start"]
        XCTAssertTrue(mainTabs.waitForExistence(timeout: 5) || welcome.waitForExistence(timeout: 5),
                      "Launch must show the app's main tabs or its onboarding welcome.")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Minutide Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
