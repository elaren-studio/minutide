import Foundation
import Testing
@testable import Stiint

@MainActor
struct WorkReportTests {
    @Test func filteredHistoryNeverUsesMetadataFromAnExcludedAssignmentOrDate() throws {
        let task = UUID(), firstOrg = UUID(), secondOrg = UUID()
        var historical = snapshot(task: task, taskName: "Original task", organization: firstOrg,
                                  organizationName: "Original studio")
        historical.task?.colorHex = "#112233"
        var moved = snapshot(task: task, taskName: "Moved task", organization: secondOrg,
                            organizationName: "Different studio")
        moved.task?.colorHex = "#AABBCC"
        let entries = [entry(100, 0, 10, work: historical), entry(101, 20, 30, work: moved)]
        let filtered = WorkReportEngine.build(entries: entries, query: query(
            filters: WorkReportFilters(organizations: .selected([firstOrg]))))
        let dated = WorkReportEngine.build(entries: entries, query: query(start: 0, end: 10))
        for result in [filtered, dated] {
            #expect(result.totalDurationSeconds == 10 && result.totalEntryCount == 1)
            let row = try #require(result.rows.first)
            #expect(row.displayName == "Original task — Original studio")
            let value = try #require(row.key.components.first?.value)
            guard case .entity(let node) = value else {
                Issue.record("Expected the captured task group"); continue
            }
            #expect(node.colorHex == "#112233")
            #expect(result.details.first?.entry.workSnapshot == historical)
        }
    }

    @Test func filtersOrWithinLevelsAndAndAcrossLevels() throws {
        let orgA = id("00000000-0000-0000-0000-000000000001")
        let orgB = id("00000000-0000-0000-0000-000000000002")
        let clientA = id("00000000-0000-0000-0000-000000000011")
        let clientB = id("00000000-0000-0000-0000-000000000012")
        let clientOther = id("00000000-0000-0000-0000-000000000013")
        let projectA = id("00000000-0000-0000-0000-000000000021")
        let projectB = id("00000000-0000-0000-0000-000000000022")
        let taskA = id("00000000-0000-0000-0000-000000000031")
        let taskB = id("00000000-0000-0000-0000-000000000032")
        let taskC = id("00000000-0000-0000-0000-000000000033")
        let taskD = id("00000000-0000-0000-0000-000000000034")
        let filters = WorkReportFilters(
            organizations: .selected([orgA, orgB]),
            clients: .selected([clientA, clientB]),
            projects: .selected([projectA, projectB]),
            tasks: .selected([taskA, taskB, taskD])
        )
        let entries = [
            entry(1, 0, 10, work: snapshot(task: taskA, organization: orgA, client: clientA, project: projectA)),
            entry(2, 10, 20, work: snapshot(task: taskB, organization: orgA, client: clientB, project: projectB)),
            entry(3, 20, 30, work: snapshot(task: taskC, organization: orgA, client: clientOther, project: projectA)),
            entry(4, 30, 40, work: snapshot(task: taskD, organization: orgB, client: clientA, project: projectB)),
            entry(5, 40, 50, work: snapshot(task: id("00000000-0000-0000-0000-000000000035")))
        ]

        let result = WorkReportEngine.build(entries: entries, query: query(filters: filters))

        #expect(Set(result.details.map(\.id)) == [entries[0].id, entries[1].id, entries[3].id])
        #expect(result.totalEntryCount == 3)
        #expect(result.totalDurationSeconds == 30)
    }

    @Test func anyUnassignedAndSelectedHaveDistinctNilSemantics() {
        let org = id("10000000-0000-0000-0000-000000000001")
        let client = id("10000000-0000-0000-0000-000000000002")
        let project = id("10000000-0000-0000-0000-000000000003")
        let allEntries = [
            entry(10, 0, 10, work: snapshot(task: id("10000000-0000-0000-0000-000000000011"), organization: org)),
            entry(11, 10, 20, work: snapshot(task: id("10000000-0000-0000-0000-000000000012"), organization: org, client: client)),
            entry(12, 20, 30, work: snapshot(task: id("10000000-0000-0000-0000-000000000013"), organization: org, client: client, project: project)),
            entry(13, 30, 40, work: snapshot(task: id("10000000-0000-0000-0000-000000000014")))
        ]

        let any = WorkReportEngine.build(entries: allEntries, query: query(filters: WorkReportFilters()))
        let unassignedOrganization = WorkReportEngine.build(
            entries: allEntries,
            query: query(filters: WorkReportFilters(organizations: .unassigned))
        )
        let unassignedClient = WorkReportEngine.build(
            entries: allEntries,
            query: query(filters: WorkReportFilters(clients: .unassigned))
        )
        let unassignedProject = WorkReportEngine.build(
            entries: allEntries,
            query: query(filters: WorkReportFilters(projects: .unassigned))
        )
        let selectedNone = WorkReportEngine.build(
            entries: allEntries,
            query: query(filters: WorkReportFilters(organizations: .selected([])))
        )

        #expect(any.totalEntryCount == 4)
        #expect(unassignedOrganization.totalEntryCount == 1)
        #expect(unassignedClient.totalEntryCount == 2)
        #expect(unassignedProject.totalEntryCount == 3)
        #expect(selectedNone.rows.isEmpty)
    }

    @Test func unparentedTaskKeepsItsTaskIdentityAndGroupsMissingAncestorsAsUnassigned() throws {
        let task = id("20000000-0000-0000-0000-000000000001")
        let source = entry(20, 0, 60, work: snapshot(task: task, taskName: "Personal admin"))
        let result = WorkReportEngine.build(
            entries: [source],
            query: query(groupings: [.organization, .client, .project, .task])
        )

        #expect(result.rows.count == 1)
        #expect(result.rows[0].key.components.map(\.value.displayName) == [
            "Unassigned", "Unassigned", "Unassigned", "Personal admin"
        ])
        guard case .entity(let taskValue)? = result.rows[0].key.components.last?.value else {
            Issue.record("The task grouping should retain the task snapshot.")
            return
        }
        #expect(taskValue.id == task)
        #expect(taskValue.name == "Personal admin")
        #expect(result.totalDurationSeconds == 60)
    }

    @Test func openLogsUseOneCapturedNowAndDuplicateSourceIDsCannotDoubleCount() {
        let task = id("30000000-0000-0000-0000-000000000001")
        let running = entry(30, 10, nil, work: snapshot(task: task))
        let result = WorkReportEngine.build(
            entries: [running, running],
            query: query(start: 0, end: 100, now: 40, groupings: [.task])
        )

        #expect(result.details.count == 1)
        #expect(result.details[0].clippedEnd == Date(timeIntervalSince1970: 40))
        #expect(result.details[0].durationSeconds == 30)
        #expect(result.totalEntryCount == 1)
        #expect(result.rows.first?.entryCount == 1)
        #expect(running.endTime == nil)
    }

    @Test func dayAndHierarchyGroupingConserveClippedDurationWithoutSubtotalDuplication() throws {
        let calendar = try calendar("UTC")
        let firstDay = try date(2026, 1, 1, 23, calendar: calendar)
        let end = firstDay.addingTimeInterval(2 * 60 * 60)
        let org = id("40000000-0000-0000-0000-000000000001")
        let client = id("40000000-0000-0000-0000-000000000002")
        let project = id("40000000-0000-0000-0000-000000000003")
        let task = id("40000000-0000-0000-0000-000000000004")
        let source = WorkReportEntry(
            id: id("40000000-0000-0000-0000-000000000010"),
            startTime: firstDay,
            endTime: end,
            workSnapshot: snapshot(task: task, organization: org, client: client, project: project)
        )
        let startOfRange = try #require(calendar.date(byAdding: .day, value: -1, to: firstDay))
        let endOfRange = end.addingTimeInterval(60)
        let result = WorkReportEngine.build(
            entries: [source],
            query: query(
                start: startOfRange,
                end: endOfRange,
                now: endOfRange,
                calendar: calendar,
                groupings: [.organization, .client, .project, .task, .day]
            )
        )

        #expect(result.rows.count == 2)
        #expect(result.rows.reduce(0) { $0 + $1.durationSeconds } == 7_200)
        #expect(result.rows.reduce(0) { $0 + $1.entryCount } == 2)
        #expect(result.totalDurationSeconds == 7_200)
        #expect(result.totalEntryCount == 1)
        #expect(result.series.reduce(0) { $0 + $1.durationSeconds } == result.totalDurationSeconds)
    }

    @Test func dayBucketsAndLabelsUseTheRequestedCalendarAcrossDST() throws {
        var calendar = try calendar("America/Los_Angeles")
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let start = try date(2026, 3, 7, 0, calendar: calendar)
        let end = try date(2026, 3, 9, 0, calendar: calendar)
        let task = id("50000000-0000-0000-0000-000000000001")
        let source = WorkReportEntry(
            id: id("50000000-0000-0000-0000-000000000010"),
            startTime: start,
            endTime: end,
            workSnapshot: snapshot(task: task, taskName: "DST work")
        )
        let result = WorkReportEngine.build(
            entries: [source],
            query: query(start: start, end: end, now: end, calendar: calendar, groupings: [.day, .task])
        )
        let dayValues = result.rows.compactMap { row in
            row.key.components.compactMap { component -> Date? in
                guard case .day(let date, _) = component.value else { return nil }
                return date
            }.first
        }
        let labels = result.rows.compactMap { row in
            row.key.components.compactMap { component -> String? in
                guard case .day(_, let label) = component.value else { return nil }
                return label
            }.first
        }

        #expect(result.totalDurationSeconds == 169_200)
        #expect(result.rows.map(\.durationSeconds) == [86_400, 82_800])
        #expect(dayValues == [start, try #require(calendar.date(byAdding: .day, value: 1, to: start))])
        #expect(labels[0].contains("Mar 7"))
        #expect(labels[1].contains("Mar 8"))
    }

    @Test func latestCapturedNamesWinAndDuplicateNamesStayVisuallyDistinct() throws {
        let orgA = id("60000000-0000-0000-0000-000000000001")
        let orgB = id("60000000-0000-0000-0000-000000000002")
        let taskA = id("60000000-0000-0000-0000-000000000011")
        let taskB = id("60000000-0000-0000-0000-000000000012")
        let sameTask = id("60000000-0000-0000-0000-000000000013")
        let entries = [
            entry(60, 0, 10, work: snapshot(task: sameTask, taskName: "Old", organization: orgA, organizationName: "Old studio")),
            entry(61, 10, 20, work: snapshot(task: taskA, taskName: "Planning", organization: orgA, organizationName: "Studio A")),
            entry(62, 20, 30, work: snapshot(task: taskB, taskName: "Planning", organization: orgB, organizationName: "Studio B")),
            entry(63, 30, 40, work: snapshot(task: sameTask, taskName: "Current", organization: orgA, organizationName: "Studio A"))
        ]

        let result = WorkReportEngine.build(entries: entries, query: query(groupings: [.task]))
        let duplicateRows = result.rows.filter { $0.key.displayName.hasPrefix("Planning") }
        let currentTaskRow = try #require(result.rows.first { row in
            row.key.components.contains { component in
                guard case .entity(let value) = component.value else { return false }
                return value.id == sameTask
            }
        })
        let taskChoices = WorkReportEngine.options(from: entries).tasks

        #expect(duplicateRows.count == 2)
        #expect(Set(duplicateRows.map(\.displayName)).count == 2)
        #expect(duplicateRows.allSatisfy { $0.displayName.contains("—") })
        #expect(currentTaskRow.displayName == "Current — Studio A")
        #expect(taskChoices.first { $0.id == taskA }?.name == "Planning — Studio A")
        #expect(taskChoices.first { $0.id == taskB }?.name == "Planning — Studio B")
    }

    @Test func sortingSupportsMetricNameAndDateWithStableIdentityTies() {
        let taskA = id("70000000-0000-0000-0000-000000000001")
        let taskB = id("70000000-0000-0000-0000-000000000002")
        let entries = [
            entry(70, 20, 50, work: snapshot(task: taskA, taskName: "Beta")),
            entry(71, 0, 20, work: snapshot(task: taskB, taskName: "Alpha"))
        ]

        let byMetric = WorkReportEngine.build(
            entries: entries,
            query: query(groupings: [.task], sorting: [WorkReportSort(field: .metric, direction: .descending)])
        )
        let byName = WorkReportEngine.build(
            entries: entries,
            query: query(groupings: [.task], sorting: [WorkReportSort(field: .name, direction: .ascending)])
        )
        let byDate = WorkReportEngine.build(
            entries: entries,
            query: query(groupings: [.task], sorting: [WorkReportSort(field: .date, direction: .ascending)])
        )

        #expect(byMetric.rows.first?.displayName == "Beta — Unassigned")
        #expect(byName.rows.first?.displayName == "Alpha — Unassigned")
        #expect(byDate.rows.first?.displayName == "Alpha — Unassigned")
    }

    @Test func duplicateCompoundNamesRemainDistinctInRowsAndSeries() {
        let orgA = id("71000000-0000-0000-0000-000000000001")
        let orgB = id("71000000-0000-0000-0000-000000000002")
        let movedTask = id("71000000-0000-0000-0000-000000000003")
        let entries = [
            entry(72, 0, 10, work: snapshot(task: movedTask, taskName: "Work", organization: orgA, organizationName: "Studio")),
            entry(73, 20, 30, work: snapshot(task: movedTask, taskName: "Work", organization: orgB, organizationName: "Studio"))
        ]

        let result = WorkReportEngine.build(
            entries: entries,
            query: query(groupings: [.organization, .task])
        )

        #expect(result.rows.count == 2)
        #expect(Set(result.rows.map(\.displayName)).count == 2)
        #expect(result.series.count == 2)
        #expect(Set(result.series.map(\.displayName)).count == 2)
        #expect(Set(result.rows.map(\.displayName)) == Set(result.series.map(\.displayName)))
    }

    @Test func malformedAndNonOverlappingIntervalsAreIgnored() {
        let task = id("80000000-0000-0000-0000-000000000001")
        let valid = entry(80, 10, 20, work: snapshot(task: task))
        let missingStart = WorkReportEntry(id: id("80000000-0000-0000-0000-000000000081"),
                                           startTime: nil, endTime: Date(timeIntervalSince1970: 20),
                                           workSnapshot: snapshot(task: task))
        let reversed = entry(82, 30, 20, work: snapshot(task: task))
        let zeroLength = entry(83, 20, 20, work: snapshot(task: task))
        let nonfinite = WorkReportEntry(id: id("80000000-0000-0000-0000-000000000084"),
                                        startTime: Date(timeIntervalSinceReferenceDate: .nan), endTime: nil,
                                        workSnapshot: snapshot(task: task))
        let outside = entry(85, 100, 110, work: snapshot(task: task))
        let result = WorkReportEngine.build(
            entries: [missingStart, reversed, zeroLength, nonfinite, outside, valid],
            query: query(start: 0, end: 50, now: 50)
        )

        #expect(result.details.map(\.id) == [valid.id])
        #expect(result.totalDurationSeconds == 10)
        #expect(result.totalDurationSeconds.isFinite)
    }

    private func query(
        start: Date,
        end: Date,
        now: Date,
        calendar: Calendar = Calendar(identifier: .gregorian),
        filters: WorkReportFilters = WorkReportFilters(),
        groupings: [WorkReportGrouping] = [.task]
    ) -> WorkReportQuery {
        query(start: start.timeIntervalSince1970, end: end.timeIntervalSince1970,
              now: now.timeIntervalSince1970, calendar: calendar, filters: filters, groupings: groupings)
    }

    private func query(
        start: TimeInterval = 0,
        end: TimeInterval = 1_000,
        now: TimeInterval = 1_000,
        calendar: Calendar = Calendar(identifier: .gregorian),
        filters: WorkReportFilters = WorkReportFilters(),
        groupings: [WorkReportGrouping] = [.task],
        metric: WorkReportMetric = .duration,
        sorting: [WorkReportSort] = [WorkReportSort(field: .metric)]
    ) -> WorkReportQuery {
        WorkReportQuery(
            startDate: Date(timeIntervalSince1970: start),
            endDateExclusive: Date(timeIntervalSince1970: end),
            capturedNow: Date(timeIntervalSince1970: now),
            calendar: calendar,
            filters: filters,
            groupings: groupings,
            metric: metric,
            sorting: sorting
        )
    }

    private func entry(_ number: Int, _ start: TimeInterval, _ end: TimeInterval?, work: WorkSnapshot) -> WorkReportEntry {
        WorkReportEntry(
            id: id(String(format: "90000000-0000-0000-0000-%012d", number)),
            startTime: Date(timeIntervalSince1970: start),
            endTime: end.map { Date(timeIntervalSince1970: $0) },
            workSnapshot: work
        )
    }

    private func snapshot(
        task: UUID? = nil,
        taskName: String = "Task",
        organization: UUID? = nil,
        organizationName: String = "Organization",
        client: UUID? = nil,
        clientName: String = "Client",
        project: UUID? = nil,
        projectName: String = "Project"
    ) -> WorkSnapshot {
        WorkSnapshot(
            task: task.map { WorkNodeSnapshot(id: $0, name: taskName) },
            organization: organization.map { WorkNodeSnapshot(id: $0, name: organizationName) },
            client: client.map { WorkNodeSnapshot(id: $0, name: clientName) },
            project: project.map { WorkNodeSnapshot(id: $0, name: projectName) }
        )
    }

    private func id(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }

    private func calendar(_ timeZone: String) throws -> Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = try #require(TimeZone(identifier: timeZone))
        return value
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, calendar: Calendar) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return try #require(calendar.date(from: components))
    }
}
