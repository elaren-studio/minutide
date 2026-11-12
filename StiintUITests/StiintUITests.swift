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
        let organizationID = openWorkEntity(named: organization, kind: "organization", in: app)
        createWorkEntity(named: client, addIdentifier: "work.client.add", in: app)
        let clientID = openWorkEntity(named: client, kind: "client", in: app)
        createWorkEntity(named: project, addIdentifier: "work.project.add", in: app)
        let projectID = openWorkEntity(named: project, kind: "project", in: app)
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

        app.tabBars.buttons["Reports"].tap()
        selectReportValue(dimension: "organization", id: organizationID,
                          matchingName: organization, in: app)
        selectReportValue(dimension: "client", id: clientID, matchingName: client, in: app)
        selectReportValue(dimension: "project", id: projectID, matchingName: project, in: app)
        selectReportValue(dimension: "task", id: taskButtonID.replacingOccurrences(of: "activity.start.", with: ""),
                          matchingName: task, in: app)
        let row = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "analytics.report.row.", task)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Combined filters must include the recorded project task.")
        XCTAssertTrue(row.label.contains("1 entries"), "The combined report must count this timer once.")
    }

    @MainActor
    func testMyDayManualLogCanCreateTaskInlineWithoutChangingItsTimes() throws {
        let app = launchReadyApp()
        app.tabBars.buttons["My Day"].tap()
        app.buttons["timeline.log.new"].tap()
        XCTAssertTrue(app.navigationBars["Create Log"].waitForExistence(timeout: 10))

        let originalFields = logFieldSignatures(in: app)
        let task = "UI Inline Log \(UUID().uuidString)"

        app.buttons["log.task.new"].tap()
        let taskEditor = app.navigationBars["New Task"]
        XCTAssertTrue(taskEditor.waitForExistence(timeout: 10))
        taskEditor.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Create Log"].waitForExistence(timeout: 10),
                      "Canceling the nested task editor must leave Create Log open.")
        XCTAssertEqual(logFieldSignatures(in: app), originalFields,
                       "Canceling task creation must preserve the selected date, times, and duration.")

        app.buttons["log.task.new"].tap()
        XCTAssertTrue(app.navigationBars["New Task"].waitForExistence(timeout: 10))
        createTaskInNestedEditor(named: task, in: app)
        XCTAssertTrue(app.navigationBars["Create Log"].waitForExistence(timeout: 10),
                      "Saving an inline task must return to the open manual log form.")
        XCTAssertFalse(app.alerts["What would you like to do?"].exists,
                       "Creating a task inside a manual log should not open the Shortcuts automation prompt.")
        XCTAssertEqual(logFieldSignatures(in: app), originalFields,
                       "Creating a task must preserve the selected date, times, and duration.")
        assertManualLogTaskSelected(named: task, in: app)

        let create = app.buttons["log.create"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        XCTAssertTrue(create.isEnabled, "The newly created task should be selected for this log.")
        create.tap()
        XCTAssertTrue(app.navigationBars["Create Log"].waitForNonExistence(timeout: 10))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["Export"].tap()
        XCTAssertTrue(app.navigationBars["Raw Data"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[task].waitForExistence(timeout: 10),
                      "The manual log must be saved under the task created inside its form.")
    }

    @MainActor
    func testMyDayCanStartSwitchAndStopTimerFromScopedTaskPicker() throws {
        let app = launchReadyApp()
        try requireAvailableTimer(in: app)

        let suffix = String(UUID().uuidString.prefix(8))
        let organization = "UI Timer Org \(suffix)"
        app.buttons["work.manage"].tap()
        createWorkEntity(named: organization, addIdentifier: "work.organization.add", in: app)
        let organizationID = workEntityID(named: organization, kind: "organization", in: app)
        app.buttons["work.done"].tap()

        let firstTask = "UI Timer First \(suffix)"
        let secondTask = "UI Timer Second \(suffix)"
        app.tabBars.buttons["My Day"].tap()
        app.buttons["timeline.timer.start"].tap()
        XCTAssertTrue(app.navigationBars["Start Timer"].waitForExistence(timeout: 10))
        chooseTimerScope("unassigned", in: app)
        app.buttons["timer.picker.new"].tap()
        XCTAssertTrue(app.navigationBars["New Task"].waitForExistence(timeout: 10))
        app.descendants(matching: .any).matching(identifier: "task.location").firstMatch.tap()
        let organizationChoice = app.descendants(matching: .any)
            .matching(identifier: "task.location.organization.\(organizationID)").firstMatch
        XCTAssertTrue(organizationChoice.waitForExistence(timeout: 5))
        organizationChoice.tap()
        createTaskInNestedEditor(named: firstTask, in: app)
        XCTAssertTrue(app.navigationBars["Start Timer"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts["What would you like to do?"].exists)
        XCTAssertFalse(app.buttons["timer.accessory.stop"].exists,
                       "Saving a new task must return to the picker; the user starts it by tapping its row.")

        let firstChoice = startTimerChoice(named: firstTask, in: app)
        attachScreenshot(named: "Task picker after inline task creation", in: app)
        XCTAssertTrue(firstChoice.waitForExistence(timeout: 10),
                      "The just-created task must remain visible even though its organization is outside Unassigned scope.")
        firstChoice.tap()
        assertRunningActivity(named: firstTask, in: app)
        attachScreenshot(named: "My Day shows the running timer", in: app)

        app.buttons["timeline.timer.switch"].tap()
        XCTAssertTrue(app.navigationBars["Start Timer"].waitForExistence(timeout: 10))
        let scope = app.buttons["timer.picker.scope"]
        XCTAssertTrue(scope.waitForExistence(timeout: 5))
        scope.tap()
        let allWork = app.buttons["timer.picker.scope.all"]
        XCTAssertTrue(allWork.waitForExistence(timeout: 5))
        allWork.tap()
        app.buttons["timer.picker.new"].tap()
        XCTAssertTrue(app.navigationBars["New Task"].waitForExistence(timeout: 10))
        createTaskInNestedEditor(named: secondTask, in: app)
        XCTAssertTrue(app.navigationBars["Start Timer"].waitForExistence(timeout: 10))
        startTimerChoice(named: secondTask, in: app).tap()
        assertRunningActivity(named: secondTask, in: app)
        XCTAssertEqual(app.buttons.matching(identifier: "timeline.timer.switch").count, 1,
                       "Switching a task must leave exactly one active timer visible.")

        app.buttons["timer.accessory.stop"].tap()
        XCTAssertTrue(app.buttons["timer.accessory.stop"].waitForNonExistence(timeout: 10))
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Export"].tap()
        XCTAssertTrue(app.navigationBars["Raw Data"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[firstTask].waitForExistence(timeout: 10),
                      "Switching away must finish and save the first task's timer.")
        XCTAssertTrue(app.staticTexts[secondTask].waitForExistence(timeout: 10),
                      "Stopping must finish and save the second task's timer.")
    }

    @MainActor
    func testWorkAppearanceCustomValuesAndIndependentResets() throws {
        let app = launchReadyApp()
        try requireAvailableTimer(in: app)
        let task = "UI Appearance \(UUID().uuidString)"

        app.tabBars.buttons["My Day"].tap()
        app.buttons["timeline.timer.start"].tap()
        XCTAssertTrue(app.navigationBars["Start Timer"].waitForExistence(timeout: 10))
        app.buttons["timer.picker.new"].tap()
        XCTAssertTrue(app.navigationBars["New Task"].waitForExistence(timeout: 10))
        assertAppearance(named: "Minutide default", icon: "Minutide default", in: app)

        app.buttons["work.appearance.color.mode"].tap()
        XCTAssertTrue(app.navigationBars["Color"].waitForExistence(timeout: 10))
        attachScreenshot(named: "Work color chooser", in: app)
        let green = app.buttons["Green"]
        XCTAssertTrue(green.waitForExistence(timeout: 5))
        green.tap()
        popAppearanceChooser("Color", backTo: "New Task", in: app)

        app.buttons["work.appearance.icon.mode"].tap()
        XCTAssertTrue(app.navigationBars["Icon"].waitForExistence(timeout: 10))
        attachScreenshot(named: "Work icon chooser", in: app)
        let readingIcon = app.buttons["work.appearance.icon.custom.book.fill"]
        XCTAssertTrue(readingIcon.waitForExistence(timeout: 5))
        readingIcon.tap()
        popAppearanceChooser("Icon", backTo: "New Task", in: app)
        assertAppearance(named: "Custom", icon: "Custom", in: app)

        createTaskInNestedEditor(named: task, in: app)
        XCTAssertTrue(app.navigationBars["Start Timer"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts["What would you like to do?"].exists,
                       "The inline task editor should return its task without opening the automation prompt.")
        app.navigationBars["Start Timer"].buttons["Cancel"].tap()

        app.tabBars.buttons["Tasks"].tap()
        app.buttons["work.manage"].tap()
        let row = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "work.task.", task)).firstMatch
        scrollUntilHittable(row, in: app,
                            message: "The customized task should be visible in Work Management.")
        row.tap()
        XCTAssertTrue(app.navigationBars["Edit Task"].waitForExistence(timeout: 10))
        assertAppearance(named: "Custom", icon: "Custom", in: app)

        app.buttons["work.appearance.color.mode"].tap()
        XCTAssertTrue(app.navigationBars["Color"].waitForExistence(timeout: 10))
        let useDefaultColor = app.buttons["work.appearance.color.source"]
        XCTAssertTrue(useDefaultColor.waitForExistence(timeout: 5))
        useDefaultColor.tap()
        popAppearanceChooser("Color", backTo: "Edit Task", in: app)
        assertAppearance(named: "Minutide default", icon: "Custom", in: app)

        app.buttons["work.appearance.icon.mode"].tap()
        XCTAssertTrue(app.navigationBars["Icon"].waitForExistence(timeout: 10))
        let useDefaultIcon = app.buttons["work.appearance.icon.source"]
        XCTAssertTrue(useDefaultIcon.waitForExistence(timeout: 5))
        useDefaultIcon.tap()
        popAppearanceChooser("Icon", backTo: "Edit Task", in: app)
        assertAppearance(named: "Minutide default", icon: "Minutide default", in: app)
        app.buttons["task.save"].tap()
        XCTAssertTrue(app.navigationBars["Manage Work"].waitForExistence(timeout: 10))

        let persistedRow = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "work.task.", task)).firstMatch
        scrollUntilHittable(persistedRow, in: app,
                            message: "The task with reset appearance should remain visible in Work Management.")
        persistedRow.tap()
        XCTAssertTrue(app.navigationBars["Edit Task"].waitForExistence(timeout: 10))
        assertAppearance(named: "Minutide default", icon: "Minutide default", in: app)
        app.navigationBars["Edit Task"].buttons["Cancel"].tap()
    }

    @MainActor
    func testMyDayBriefEntryHasBottomStopAndAppearsInBothModes() throws {
        let app = launchReadyApp()
        try requireAvailableTimer(in: app)
        let name = "UI Brief Entry \(String(UUID().uuidString.prefix(8)))"
        createActivity(named: name, in: app)
        startActivity(named: name, in: app)
        app.tabBars.buttons["My Day"].tap()
        let stop = app.buttons["timer.accessory.stop"]
        XCTAssertTrue(stop.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(stop.frame.midY, app.frame.height * 0.65,
                             "The timer controls should sit above the bottom navigation.")
        XCTAssertLessThanOrEqual(stop.frame.maxY, app.tabBars.firstMatch.frame.minY + 2)
        attachScreenshot(named: "Bottom timer has Stop", in: app)
        stop.tap()
        XCTAssertTrue(stop.waitForNonExistence(timeout: 10))
        let start = app.buttons["timeline.timer.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(start.frame.midY, app.frame.height * 0.65)
        chooseDayMode("timeline", in: app)
        let marker = dayEntry(named: name, prefix: "timeline.segment.", in: app)
        XCTAssertTrue(marker.waitForExistence(timeout: 10),
                      "A seconds-long completed task must remain discoverable in the timeline.")
        attachScreenshot(named: "Brief entry remains visible in Timeline", in: app)
        chooseDayMode("list", in: app)
        let row = dayEntry(named: name, prefix: "timeline.entry.", in: app)
        scrollUntilHittable(row, in: app, message: "The same brief entry must appear in List mode.")
        XCTAssertTrue(row.label.contains("sec"), "The brief entry should show seconds rather than zero minutes.")
        attachScreenshot(named: "My Day list shows exact short duration", in: app)
        row.tap()
        XCTAssertTrue(app.navigationBars["Edit Log"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["log.detail.duration"].waitForExistence(timeout: 5))
        app.navigationBars["Edit Log"].buttons["Cancel"].tap()
        app.terminate()
        app.launch()
        app.tabBars.buttons["My Day"].tap()
        let restoredRow = dayEntry(named: name, prefix: "timeline.entry.", in: app)
        scrollUntilHittable(restoredRow, in: app, message: "List mode and the completed entry should survive relaunch.")
        chooseDayMode("timeline", in: app)
    }

    @MainActor
    func testReportsLongLabelsStayOutsideThePlotAndExportsStaySeparate() throws {
        let app = launchReadyApp()
        try requireAvailableTimer(in: app)
        let name = "UI Long Report planning and coordination for an extended project \(String(UUID().uuidString.prefix(8)))"
        createActivity(named: name, in: app)
        let taskID = startActivity(named: name, in: app).replacingOccurrences(of: "activity.start.", with: "")
        stopActivity(named: name, in: app)
        app.tabBars.buttons["Reports"].tap()
        let summary = app.descendants(matching: .any).matching(identifier: "analytics.report.summary").firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        selectReportValue(dimension: "task", id: taskID, matchingName: name, in: app)
        let row = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "analytics.report.row.", name)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertFalse(row.label.contains("0m"), "A short positive entry must not display zero minutes.")
        let summaryExport = app.buttons["analytics.report.export.summary"]
        let detailsExport = app.buttons["analytics.report.export.details"]
        XCTAssertFalse(summaryExport.frame.intersects(app.staticTexts["Report summary"].frame))
        XCTAssertFalse(detailsExport.frame.intersects(app.staticTexts["Report summary"].frame))
        attachScreenshot(named: "Report summary wraps long labels", in: app)
        let chart = app.descendants(matching: .any).matching(identifier: "analytics.chart.sankey").firstMatch
        scrollUntilHittable(chart, in: app, message: "Sankey card must remain reachable.")
        let plot = app.descendants(matching: .any).matching(identifier: "analytics.sankey.plot").firstMatch
        XCTAssertTrue(plot.waitForExistence(timeout: 10))
        let description = app.staticTexts["The diagram compares each activity's average daily time over the selected period."]
        XCTAssertLessThanOrEqual(description.frame.maxY, plot.frame.minY + 2,
                                 "The diagram must begin after its description.")
        attachScreenshot(named: "Sankey contains labels and a wrapping legend", in: app)
    }

    @MainActor
    func testReportDateCancelPreservesAppliedWindow() {
        let app = launchReadyApp()
        app.tabBars.buttons["Reports"].tap()
        let summary = app.staticTexts["analytics.filter.date.summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        let original = summary.label
        app.buttons["analytics.filter.date.open"].tap()
        // SwiftUI's native inline Picker exposes the parent identifier on each
        // option; its visible label distinguishes Today from the other rows.
        let today = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label == %@",
                                                     "analytics.filter.date.preset", "Today")).firstMatch
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        today.tap()
        app.buttons["analytics.filter.cancel"].tap()
        XCTAssertTrue(app.buttons["analytics.filter.cancel"].waitForNonExistence(timeout: 5))
        XCTAssertEqual(summary.label, original, "Cancel must leave both the displayed and applied date range unchanged.")
        app.buttons["analytics.filter.date.open"].tap()
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        today.tap()
        app.buttons["analytics.filter.apply"].tap()
        XCTAssertTrue(app.buttons["analytics.filter.apply"].waitForNonExistence(timeout: 5))
        XCTAssertNotEqual(summary.label, original, "Apply must commit the Today window.")
    }

    @MainActor
    private func selectReportValue(dimension: String, id: String, matchingName: String? = nil, in app: XCUIApplication) {
        let opener = app.buttons["analytics.report.filter.\(dimension)"]
        XCTAssertTrue(opener.waitForExistence(timeout: 10))
        opener.tap()
        if let matchingName {
            let search = app.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 5))
            search.tap()
            search.typeText(matchingName)
        }
        let option = app.buttons["analytics.report.filter.\(dimension).option.\(id)"]
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
        app.buttons["analytics.report.filter.\(dimension).done"].tap()
        XCTAssertTrue(option.waitForNonExistence(timeout: 5))
    }

    @MainActor
    @discardableResult
    private func openWorkEntity(named name: String, kind: String, in app: XCUIApplication) -> String {
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@",
                                                   "work.\(kind).", name)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let id = row.identifier.replacingOccurrences(of: "work.\(kind).", with: "")
        row.tap()
        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 10),
                      "Opening a work row must show its detail screen.")
        return id
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
    private func workEntityID(named name: String, kind: String, in app: XCUIApplication) -> String {
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@",
                                                   "work.\(kind).", name)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        return row.identifier.replacingOccurrences(of: "work.\(kind).", with: "")
    }

    @MainActor
    private func createTaskInNestedEditor(named name: String, in app: XCUIApplication) {
        let field = app.textFields["task.name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)
        app.buttons["task.save"].tap()
    }

    @MainActor
    private func logFieldSignatures(in app: XCUIApplication) -> [String] {
        ["log.date", "log.start", "log.end", "log.duration"].map { identifier in
            let field = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: 5), "Missing manual log field \(identifier).")
            let value = field.value.map { String(describing: $0) } ?? ""
            return "\(field.label)|\(value)"
        }
    }

    @MainActor
    private func assertManualLogTaskSelected(named name: String, in app: XCUIApplication) {
        let picker = app.descendants(matching: .any).matching(identifier: "log.task").firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        let exposed = "\(picker.label) \(picker.value.map { String(describing: $0) } ?? "")"
        XCTAssertTrue(exposed.localizedCaseInsensitiveContains(name),
                      "The task created inside Create Log must be selected; found: \(exposed)")
    }

    @MainActor
    private func chooseTimerScope(_ scope: String, in app: XCUIApplication) {
        let picker = app.buttons["timer.picker.scope"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let option = app.buttons["timer.picker.scope.\(scope)"]
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
    }

    @MainActor
    private func startTimerChoice(named name: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@",
                                         "timer.picker.task.", "Start \(name)")).firstMatch
    }

    @MainActor
    private func assertAppearance(named color: String, icon: String, in app: XCUIApplication) {
        let preview = app.descendants(matching: .any)
            .matching(identifier: "work.appearance.preview").firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let value = preview.value.map { String(describing: $0) } ?? ""
        XCTAssertEqual(value, "Color from \(color), icon from \(icon)")
    }

    @MainActor
    private func attachScreenshot(named name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func popAppearanceChooser(_ chooser: String, backTo editor: String, in app: XCUIApplication) {
        let back = app.navigationBars[chooser].buttons["BackButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 5), "Missing the Back button for the \(chooser) chooser.")
        back.tap()
        XCTAssertTrue(app.navigationBars[editor].waitForExistence(timeout: 10),
                      "The \(chooser) chooser should return to \(editor).")
    }

    @MainActor
    private func chooseDayMode(_ mode: String, in app: XCUIApplication) {
        app.buttons["timeline.mode"].tap()
        let option = app.buttons["timeline.mode.\(mode)"]
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
    }

    @MainActor
    private func dayEntry(named name: String, prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
                                         prefix, name)).firstMatch
    }

    @MainActor
    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication,
                                     message: String, maxSwipes: Int = 20) {
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists, message)
        XCTAssertTrue(element.isHittable, message)
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
        if app.buttons["timer.running.stop"].exists || app.buttons["timer.accessory.stop"].exists {
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
        if title.exists {
            XCTAssertEqual(title.label, name)
            XCTAssertTrue(app.buttons["timer.running.stop"].exists)
            XCTAssertTrue(app.staticTexts["timer.running.elapsed"].exists)
        } else {
            let switcher = app.buttons["timeline.timer.switch"]
            XCTAssertTrue(switcher.waitForExistence(timeout: 10))
            XCTAssertTrue(switcher.label.contains(name))
            XCTAssertTrue(app.buttons["timer.accessory.stop"].exists)
            XCTAssertTrue(app.staticTexts["timer.accessory.elapsed"].exists)
        }
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
