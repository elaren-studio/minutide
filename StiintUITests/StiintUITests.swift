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

        app.tabBars.buttons["Reports"].tap()
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
        XCTAssertTrue(app.tabBars.buttons["Tasks"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Tasks"].tap()
        assertRunningActivity(named: name, in: app)
        stopActivity(named: name, in: app)
    }

    @MainActor
    func testProjectTaskAndOrganizationSwitchKeepOneGlobalTimer() throws {
        let app = launchReadyApp()
        try requireAvailableTimer(in: app)
        let suffix = String(UUID().uuidString.prefix(8))
        let organization = "UI Studio \(suffix)"
        let client = "UI Client \(suffix)"
        let project = "UI Project \(suffix)"
        let task = "UI Project Task \(suffix)"
        app.buttons["work.manage"].tap()
        createWorkEntity(named: organization, addIdentifier: "work.organization.add", in: app)
        openWorkEntity(named: organization, kind: "organization", in: app)
        createWorkEntity(named: client, addIdentifier: "work.client.add", in: app)
        openWorkEntity(named: client, kind: "client", in: app)
        createWorkEntity(named: project, addIdentifier: "work.project.add", in: app)
        openWorkEntity(named: project, kind: "project", in: app)
        app.buttons["work.add"].tap()
        app.buttons["task.add"].tap()
        let field = app.textFields["task.name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(task)
        app.buttons["task.save"].tap()
        let later = app.alerts.buttons["Do It Later"]
        XCTAssertTrue(later.waitForExistence(timeout: 10))
        later.tap()
        XCTAssertTrue(app.navigationBars[project].waitForExistence(timeout: 5))
        for expectedTitle in [client, organization, "Manage Work"] {
            app.navigationBars.firstMatch.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.navigationBars[expectedTitle].waitForExistence(timeout: 5))
        }
        let done = app.buttons["work.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        let taskButtonID = startActivity(named: task, in: app)

        app.buttons["work.scope"].tap()
        app.buttons["work.scope.unassigned"].tap()
        assertRunningActivity(named: task, in: app)
        XCTAssertFalse(app.buttons[taskButtonID].exists,
                       "A project task must leave the unassigned task list while its timer continues.")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Unassigned scope keeps project timer"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["work.scope"].tap()
        app.buttons["work.scope.all"].tap()
        assertRunningActivity(named: task, in: app)
        app.terminate()
        app.launch()
        app.tabBars.buttons["Tasks"].tap()
        assertRunningActivity(named: task, in: app)
        stopActivity(named: task, in: app)
    }

    @MainActor
    private func openWorkEntity(named name: String, kind: String, in app: XCUIApplication) {
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@",
                                                   "work.\(kind).", name)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 10),
                      "Opening a work row must show its detail screen.")
    }

    @MainActor
    private func createWorkEntity(named name: String, addIdentifier: String, in app: XCUIApplication) {
        app.buttons["work.add"].tap()
        app.buttons[addIdentifier].tap()
        let field = app.textFields["work.entity.name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)
        app.buttons["work.entity.save"].tap()
        XCTAssertTrue(app.staticTexts[name].firstMatch.waitForExistence(timeout: 10))
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
        XCTAssertTrue(app.tabBars.buttons["Tasks"].waitForExistence(timeout: 10),
                      "The main tabs should appear after onboarding is skipped.")
        return app
    }

    @MainActor
    private func requireAvailableTimer(in app: XCUIApplication) throws {
        app.tabBars.buttons["Tasks"].tap()
        let addActivity = app.buttons["activity.add"]
        // The UI tests never reset a store or stop an unrelated pre-existing timer.
        // XCTest records this explicit skip; run on an idle test simulator to exercise the flow.
        _ = addActivity.waitForExistence(timeout: 5)
        if app.buttons["timer.running.stop"].exists {
            throw XCTSkip("A pre-existing timer is running. Preserved it; use an idle test simulator for this regression test.")
        }
        XCTAssertTrue(addActivity.exists, "Expected the activity list. Tracking must be unpaused for this test.")
    }

    @MainActor
    private func createActivity(named name: String, in app: XCUIApplication) {
        app.buttons["activity.add"].tap()
        let nameField = app.textFields["task.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        app.buttons["task.save"].tap()
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
    @discardableResult
    private func startActivity(named name: String, in app: XCUIApplication) -> String {
        let button = activityStartButton(named: name, in: app)
        for _ in 0..<12 {
            if button.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable, "New activity must have an accessible start button.")
        let identifier = button.identifier
        button.tap()
        assertRunningActivity(named: name, in: app)
        return identifier
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
        XCTAssertTrue(app.buttons["timer.running.stop"].waitForNonExistence(timeout: 10))
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
