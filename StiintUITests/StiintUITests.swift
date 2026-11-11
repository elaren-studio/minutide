//
//  StiintUITests.swift
//  StiintUITests
//
//  Created by Liam Wittig on 10.12.25.
//

import XCTest

final class StiintUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testActivityCanStartStopExportAndUseEveryChartForFree() throws {
        let app = launchReadyApp()
        try requireAvailableTimer(in: app)
        let name = "UI Export \(UUID().uuidString)"
        createActivity(named: name, in: app)
        startActivity(named: name, in: app)
        stopActivity(named: name, in: app)

        app.tabBars.buttons["Settings"].tap()
        let export = app.buttons["Export"]
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        export.tap()
        XCTAssertTrue(app.navigationBars["Raw Data"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[name].firstMatch.waitForExistence(timeout: 5),
                      "Stopping a timer must persist a completed record visible in Export.")
        app.navigationBars["Raw Data"].buttons["Settings"].tap()

        app.tabBars.buttons["Insights"].tap()
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        for chartName in ["sankey", "pie", "bar", "line", "area"] {
            let chart = app.descendants(matching: .any)
                .matching(identifier: "analytics.chart.\(chartName)").firstMatch
            XCTAssertTrue(chart.waitForExistence(timeout: 10), "Missing \(chartName) chart.")
            for _ in 0..<12 {
                if chart.isHittable { break }
                scrollView.swipeUp()
            }
            XCTAssertTrue(chart.isHittable, "The \(chartName) chart must be accessible by scrolling.")
            XCTAssertTrue(chart.isEnabled, "The \(chartName) chart must be enabled without a purchase.")
            assertNoPurchaseScreen(in: app)
        }

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["All features are free. No account, subscription, or purchase is required."]
            .waitForExistence(timeout: 5))
        assertNoPurchaseScreen(in: app)
    }

    @MainActor
    func testRunningActivitySurvivesRelaunch() throws {
        let app = launchReadyApp()
        try requireAvailableTimer(in: app)
        let name = "UI Relaunch \(UUID().uuidString)"
        createActivity(named: name, in: app)
        startActivity(named: name, in: app)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Timers"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Timers"].tap()
        assertRunningActivity(named: name, in: app)
        stopActivity(named: name, in: app)
    }

    @MainActor
    private func launchReadyApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let start = app.buttons["Let's Start"]
        if start.waitForExistence(timeout: 3) {
            start.tap()
        }
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 2) {
            skip.tap()
        }
        XCTAssertTrue(app.tabBars.buttons["Timers"].waitForExistence(timeout: 10),
                      "The main tabs should appear after onboarding is skipped.")
        return app
    }

    @MainActor
    private func requireAvailableTimer(in app: XCUIApplication) throws {
        app.tabBars.buttons["Timers"].tap()
        let addActivity = app.buttons["activity.add"]
        // The UI tests never reset a store or stop an unrelated pre-existing timer.
        // XCTest records this explicit skip; run on an idle test simulator to exercise the flow.
        if !addActivity.waitForExistence(timeout: 5),
           app.buttons["timer.running.stop"].exists {
            throw XCTSkip("A pre-existing timer is running. Preserved it; use an idle test simulator for this regression test.")
        }
        XCTAssertTrue(addActivity.exists, "Expected the activity list. Tracking must be unpaused for this test.")
    }

    @MainActor
    private func createActivity(named name: String, in app: XCUIApplication) {
        app.buttons["activity.add"].tap()
        let nameField = app.textFields["Activity Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        app.navigationBars.buttons["Done"].tap()
        let later = app.alerts.buttons["Do It Later"]
        XCTAssertTrue(later.waitForExistence(timeout: 10))
        later.tap()
        XCTAssertTrue(app.buttons["activity.add"].waitForExistence(timeout: 10))
    }

    @MainActor
    private func activityStartButton(named name: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier BEGINSWITH %@",
                                         "Start \(name)", "activity.start.")).firstMatch
    }

    @MainActor
    private func startActivity(named name: String, in app: XCUIApplication) {
        let button = activityStartButton(named: name, in: app)
        for _ in 0..<12 {
            if button.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable, "New activity must have an accessible start button.")
        button.tap()
        assertRunningActivity(named: name, in: app)
    }

    @MainActor
    private func assertRunningActivity(named name: String, in app: XCUIApplication) {
        let title = app.staticTexts["timer.running.name"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, name)
        XCTAssertTrue(app.buttons["timer.running.stop"].exists)
        XCTAssertTrue(app.staticTexts["timer.running.elapsed"].exists)
    }

    @MainActor
    private func stopActivity(named name: String, in app: XCUIApplication) {
        assertRunningActivity(named: name, in: app)
        app.buttons["timer.running.stop"].tap()
        XCTAssertTrue(app.buttons["activity.add"].waitForExistence(timeout: 10),
                      "Stopping must return to the activity list.")
    }

    @MainActor
    private func assertNoPurchaseScreen(in app: XCUIApplication) {
        for label in ["Try It Free", "Restore purchases", "Manage Subscriptions", "Get Stiint"] {
            XCTAssertFalse(app.buttons[label].exists, "Unexpected purchase UI: \(label)")
        }
        XCTAssertFalse(app.staticTexts["Stiint Plus"].exists)
    }
}
