import CoreLocation
import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct ResumeCompletedLogTests {
    @Test func resumeStartsNewIntervalNowAndLeavesCompletedSourceAndCoordinatesUntouched() async throws {
        let fixture = try ResumeFixture()
        let task = try await fixture.work.saveTask(name: "Writing", parent: nil)
        let source = try await fixture.completed(task: task)
        try fixture.edit(source) {
            $0.startLatitude = 32; $0.startLongitude = -97
            $0.endLatitude = 33; $0.endLongitude = -98
            $0.previousActivityLogId = UUID()
        }
        let before = try fixture.row(source)
        let began = Date.now
        let running = try await fixture.logs.resumeCompletedLog(logId: source)
        let ended = Date.now
        let created = try fixture.row(running.logId)
        let started = try #require(created.start)
        #expect(running.logId != source)
        #expect(started >= began && started <= ended)
        #expect(created.end == nil && created.snapshot == before.snapshot)
        #expect(created.startLatitude == nil && created.startLongitude == nil)
        #expect(created.endLatitude == nil && created.endLongitude == nil)
        #expect(try fixture.row(source) == before)
        #expect(try fixture.rows().count == 2)
    }

    @Test func resumeKeepsHistoricalNamesHierarchyAndAppearanceAfterTaskMoves() async throws {
        let fixture = try ResumeFixture()
        let org = try await fixture.work.saveOrganization(name: "Studio", colorHex: "#112233", sfSymbolName: "building.2")
        let client = try await fixture.work.saveClient(name: "Client", organizationID: org)
        let project = try await fixture.work.saveProject(name: "Project", clientID: client)
        let task = try await fixture.work.saveTask(name: "Original task", parent: .project(project))
        let source = try await fixture.completed(task: task)
        let before = try fixture.row(source)
        _ = await fixture.logs.getActivtyLogDTO(activityLogId: source)
        _ = try await fixture.work.saveTask(id: task, name: "Moved task", parent: nil,
                                           colorHex: "#FFFFFF", sfSymbolName: "house")
        _ = try await fixture.work.saveOrganization(id: org, name: "Renamed organization", colorHex: "#AABBCC")
        // A historical parent can be archived after the task moves elsewhere;
        // availability is determined by the task's current valid assignment.
        try await fixture.work.setArchived(kind: .project, id: project, archived: true)
        let running = try await fixture.logs.resumeCompletedLog(logId: source)
        #expect(try fixture.row(running.logId).snapshot == before.snapshot)
        #expect(running.activity.name == "Original task" && running.activity.icon == "building.2")
        #expect(running.activity.organizationName == "Studio")
        #expect(running.activity.clientName == "Client" && running.activity.projectName == "Project")
        #expect(try fixture.row(source) == before)
    }

    @Test func resumeSwitchesRunningTaskAtOneBoundaryThenRecoverStartAndStopStayCoherent() async throws {
        let fixture = try ResumeFixture()
        let task = try await fixture.work.saveTask(name: "Resume this", parent: nil)
        let other = try await fixture.work.saveTask(name: "Other", parent: nil)
        let source = try await fixture.completed(task: task)
        let original = try fixture.row(source)
        let prior = try #require(try await fixture.logs.startOrSwitchActivity(activityId: other))
        // Register these models in the actor's older context before resuming.
        _ = await fixture.logs.getAllActivityLogs()
        let resumed = try await fixture.logs.resumeCompletedLog(logId: source, preferredLogId: prior.logId)
        #expect(try fixture.row(prior.logId).end == fixture.row(resumed.logId).start)
        #expect(try fixture.row(resumed.logId).previous == prior.logId)
        #expect(try await fixture.logs.recoverRunningActivity(preferredLogId: prior.logId)?.logId == resumed.logId)
        #expect(try await fixture.logs.startOrSwitchActivity(activityId: task)?.logId == resumed.logId)
        #expect(try await fixture.logs.stopRunningActivity(matchingActivityId: task))
        #expect(try await fixture.logs.recoverRunningActivity() == nil)
        #expect(await fixture.logs.getActivtyLogDTO(activityLogId: resumed.logId)?.endTime != nil)
        let restarted = try #require(try await fixture.logs.startOrSwitchActivity(activityId: other))
        #expect(restarted.logId != prior.logId && restarted.logId != resumed.logId)
        #expect(try fixture.rows().filter { $0.end == nil }.count == 1)
        #expect(try fixture.row(source) == original)
    }

    @Test func simultaneousResumesOfSameSnapshotAreIdempotent() async throws {
        let fixture = try ResumeFixture()
        let task = try await fixture.work.saveTask(name: "One timer", parent: nil)
        let source = try await fixture.completed(task: task)
        let actor = fixture.logs
        let ids = try await withThrowingTaskGroup(of: UUID.self, returning: [UUID].self) { group in
            for _ in 0..<20 {
                group.addTask { try await actor.resumeCompletedLog(logId: source).logId }
            }
            var result: [UUID] = []
            for try await value in group { result.append(value) }
            return result
        }
        #expect(ids.count == 20 && Set(ids).count == 1)
        #expect(try fixture.rows().count == 2)
        #expect(try fixture.rows().filter { $0.end == nil }.count == 1)
    }

    @Test func sameTaskWithDifferentSnapshotSwitchesToRequestedHistoricalDetails() async throws {
        let fixture = try ResumeFixture()
        let org = try await fixture.work.saveOrganization(name: "Past", colorHex: "#112233")
        let task = try await fixture.work.saveTask(name: "Earlier", parent: .organization(org))
        let source = try await fixture.completed(task: task)
        let original = try fixture.row(source)
        _ = try await fixture.work.saveTask(id: task, name: "Current", parent: nil)
        let current = try #require(try await fixture.logs.startOrSwitchActivity(activityId: task))
        let resumed = try await fixture.logs.resumeCompletedLog(logId: source)
        #expect(resumed.logId != current.logId && resumed.logId != source)
        #expect(resumed.activity.name == "Earlier" && resumed.activity.organizationName == "Past")
        #expect(try fixture.row(current.logId).end == fixture.row(resumed.logId).start)
        #expect(try fixture.row(resumed.logId).snapshot == original.snapshot)
        #expect(try await fixture.logs.resumeCompletedLog(logId: source).logId == resumed.logId)
        #expect(try fixture.rows().count == 3)
    }

    @Test func simultaneousResumesOfDifferentTasksKeepBothNewIntervalsAndOneRunningTimer() async throws {
        let fixture = try ResumeFixture()
        let first = try await fixture.work.saveTask(name: "First", parent: nil)
        let second = try await fixture.work.saveTask(name: "Second", parent: nil)
        let firstSource = try await fixture.completed(task: first)
        let secondSource = try await fixture.completed(task: second, offset: 200)
        let sources = try fixture.rows()
        async let firstResume = fixture.logs.resumeCompletedLog(logId: firstSource)
        async let secondResume = fixture.logs.resumeCompletedLog(logId: secondSource)
        let (firstRunning, secondRunning) = try await (firstResume, secondResume)
        #expect(firstRunning.logId != secondRunning.logId)
        let rows = try fixture.rows()
        #expect(rows.count == 4 && rows.filter { $0.end == nil }.count == 1)
        let newRows = rows.filter { $0.id == firstRunning.logId || $0.id == secondRunning.logId }
        let closed = try #require(newRows.first { $0.end != nil })
        let open = try #require(newRows.first { $0.end == nil })
        #expect(closed.end == open.start && open.previous == closed.id)
        #expect(try sources.allSatisfy { try fixture.row($0.id!) == $0 })
    }

    @Test func rejectedUnavailableSourcesDoNotChangeRunningTimer() async throws {
        let fixture = try ResumeFixture()
        let currentTask = try await fixture.work.saveTask(name: "Running", parent: nil)
        let archivedTask = try await fixture.work.saveTask(name: "Archived", parent: nil)
        let archivedSource = try await fixture.completed(task: archivedTask)
        let org = try await fixture.work.saveOrganization(name: "Archived parent")
        let parentTask = try await fixture.work.saveTask(name: "Parent task", parent: .organization(org))
        let parentSource = try await fixture.completed(task: parentTask, offset: 200)
        let orphanSource = try await fixture.completed(task: currentTask, offset: 400)
        try fixture.edit(orphanSource) { $0.activity = nil }
        try await fixture.work.setArchived(kind: .task, id: archivedTask, archived: true)
        try await fixture.work.setArchived(kind: .organization, id: org, archived: true)
        let running = try #require(try await fixture.logs.startOrSwitchActivity(activityId: currentTask))
        let before = try fixture.rows()
        for source in [archivedSource, parentSource, orphanSource] {
            await expectFailure(.unavailableActivity, fixture: fixture, source: source)
            #expect(try fixture.rows() == before)
        }
        await expectFailure(.unavailableLog, fixture: fixture, source: UUID())
        await expectFailure(.unavailableLog, fixture: fixture, source: running.logId)
        #expect(try fixture.rows() == before)
        #expect(try await fixture.logs.recoverRunningActivity()?.logId == running.logId)
    }

    @Test func invalidClosedIntervalsRejectBeforeAnyTimerMutation() async throws {
        let fixture = try ResumeFixture()
        let task = try await fixture.work.saveTask(name: "Invalid dates", parent: nil)
        let source = try await fixture.completed(task: task)
        _ = try await fixture.logs.startOrSwitchActivity(activityId: task)
        let intervals: [(Date?, Date)] = [
            (nil, date(100)), (date(100), date(100)), (date(100), date(0)),
            (date(0), Date.now.addingTimeInterval(3_600)),
            (Date(timeIntervalSinceReferenceDate: .infinity), date(100)),
            (date(0), Date(timeIntervalSinceReferenceDate: .infinity))
        ]
        for (start, end) in intervals {
            try fixture.edit(source) { $0.startTime = start; $0.endTime = end }
            let before = try fixture.rows()
            await expectFailure(.invalidInterval, fixture: fixture, source: source)
            #expect(try fixture.rows() == before)
        }
    }

    @Test func resumeRefetchesEditedSnapshotAndRejectsNewlyMissingCurrentParent() async throws {
        let fixture = try ResumeFixture()
        let task = try await fixture.work.saveTask(name: "Fresh source", parent: nil)
        let source = try await fixture.completed(task: task)
        _ = await fixture.logs.getAllActivityLogs()
        try fixture.edit(source) {
            var snapshot = $0.workSnapshot
            snapshot.task?.name = "Explicitly reclassified"
            $0.workSnapshot = snapshot
        }
        let running = try await fixture.logs.resumeCompletedLog(logId: source)
        #expect(running.activity.name == "Explicitly reclassified")
        #expect(try await fixture.logs.stopRunningActivity())
        let context = ModelContext(fixture.container)
        let savedTask = try #require(try context.fetch(FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == task })).first)
        savedTask.workParent = .project(UUID())
        try context.save()
        let before = try fixture.rows()
        await expectFailure(.unavailableActivity, fixture: fixture, source: source)
        #expect(try fixture.rows() == before)
    }

    @Test func resumedLocationUsesFreshBoundaryAndCurrentOptIn() async throws {
        let fixture = try ResumeFixture()
        let task = try await fixture.work.saveTask(name: "Location policy", parent: nil)
        let source = try await fixture.completed(task: task)
        let original = try fixture.row(source)
        let resumed = try await fixture.logs.resumeCompletedLog(logId: source)
        let location = CLLocation(latitude: 32, longitude: -97)
        let originalStart = try #require(original.start)
        #expect(try await fixture.logs.applyCapturedLocation(location, activityLogId: resumed.logId,
                    activityId: task, boundary: resumed.activity.startTime, isStart: true) == false)
        _ = try await fixture.work.saveTask(id: task, name: "Location policy", parent: nil, storeLocation: true)
        #expect(try await fixture.logs.applyCapturedLocation(location, activityLogId: resumed.logId,
                    activityId: task, boundary: originalStart, isStart: true) == false)
        #expect(try await fixture.logs.applyCapturedLocation(location, activityLogId: resumed.logId,
                    activityId: task, boundary: resumed.activity.startTime, isStart: true))
        #expect(try fixture.row(resumed.logId).startLatitude == 32)
        #expect(try fixture.row(source) == original)
    }

    private func expectFailure(_ expected: ActivityLogActor.ResumeLogError, fixture: ResumeFixture,
                               source: UUID) async {
        do {
            _ = try await fixture.logs.resumeCompletedLog(logId: source)
            Issue.record("An invalid resume must fail before changing history or the running timer")
        } catch {
            #expect(error as? ActivityLogActor.ResumeLogError == expected)
        }
    }
}

private func date(_ seconds: Double) -> Date { Date(timeIntervalSince1970: seconds) }

@MainActor
private final class ResumeFixture {
    let container: ModelContainer
    let logs: ActivityLogActor
    let work: WorkHierarchyActor

    init() throws {
        container = try WorkStore.makeContainer(inMemory: true)
        logs = ActivityLogActor(modelContainer: container)
        work = WorkHierarchyActor(modelContainer: container)
    }

    func completed(task: UUID, offset: Double = 0) async throws -> UUID {
        try await logs.saveCompletedLog(activityId: task, startTime: date(offset), endTime: date(offset + 100))
    }

    func edit(_ id: UUID, change: (ActivityLog) -> Void) throws {
        let context = ModelContext(container)
        let log = try #require(try context.fetch(FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == id })).first)
        change(log)
        try context.save()
    }

    struct Row: Equatable {
        let id: UUID?
        let activity: UUID?
        let start: Date?
        let end: Date?
        let previous: UUID?
        let snapshot: WorkSnapshot
        let startLatitude: Double?
        let startLongitude: Double?
        let endLatitude: Double?
        let endLongitude: Double?
    }

    func rows() throws -> [Row] {
        try ModelContext(container).fetch(FetchDescriptor<ActivityLog>()).map {
            Row(id: $0.id, activity: $0.activity?.id, start: $0.startTime, end: $0.endTime,
                previous: $0.previousActivityLogId, snapshot: $0.workSnapshot,
                startLatitude: $0.startLatitude, startLongitude: $0.startLongitude,
                endLatitude: $0.endLatitude, endLongitude: $0.endLongitude)
        }.sorted { ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "") }
    }

    func row(_ id: UUID) throws -> Row { try #require(try rows().first { $0.id == id }) }
}
