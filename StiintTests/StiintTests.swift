import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct StiintTests {
    @Test func startSwitchAndStopPreserveHistory() async throws {
        let fixture = try TimerFixture()
        let first = try fixture.addActivity("Work")
        let second = try fixture.addActivity("Break")
        let started = try #require(try await fixture.logs.startOrSwitchActivity(activityId: first))
        let switched = try #require(try await fixture.logs.startOrSwitchActivity(activityId: second))
        #expect(started.logId != switched.logId)

        var rows = try fixture.rows()
        #expect(rows.count == 2)
        let firstRow = try #require(rows.first { $0.id == started.logId })
        let secondRow = try #require(rows.first { $0.id == switched.logId })
        #expect(firstRow.end == secondRow.start)
        #expect(secondRow.previousId == started.logId)
        #expect(secondRow.end == nil)

        #expect(try await fixture.logs.stopRunningActivity())
        rows = try fixture.rows()
        #expect(rows.count == 2)
        #expect(rows.allSatisfy { $0.end != nil })
        #expect(try await fixture.logs.recoverRunningActivity() == nil)
    }

    @Test func missingAndDeletedTargetsLeaveCurrentTimerUntouched() async throws {
        let fixture = try TimerFixture()
        let valid = try fixture.addActivity("Current")
        let deleted = try fixture.addActivity("Deleted", deleted: true)
        let running = try #require(try await fixture.logs.startOrSwitchActivity(activityId: valid))

        #expect(try await fixture.logs.startOrSwitchActivity(activityId: UUID()) == nil)
        #expect(try await fixture.logs.startOrSwitchActivity(activityId: deleted) == nil)
        let recovered = try await fixture.logs.recoverRunningActivity()
        #expect(recovered?.logId == running.logId)
        #expect(try fixture.rows().count == 1)
        #expect(try fixture.rows().first?.end == nil)
    }

    @Test func recoverySurvivesMissingStaleAndCompletedPreferencePointers() async throws {
        let fixture = try TimerFixture()
        let activity = try fixture.addActivity("Recover me")
        let started = try #require(try await fixture.logs.startOrSwitchActivity(activityId: activity))
        let completedId = try fixture.addLog(activityId: activity,
            start: Date(timeIntervalSince1970: 10), end: Date(timeIntervalSince1970: 20))

        // A fresh database actor models a relaunch without using app singletons,
        // real UserDefaults, location services, or the user's persistent store.
        let relaunched = ActivityLogActor(modelContainer: fixture.container)
        for hint in [nil, UUID(), completedId] as [UUID?] {
            let recovered = try await relaunched.recoverRunningActivity(preferredLogId: hint)
            #expect(recovered?.logId == started.logId)
            #expect(recovered?.activity.startTime == started.activity.startTime)
        }
        #expect(try fixture.rows().count == 2)
    }

    @Test func duplicateRecoveryClosesRowsAtNextStartWithoutDeletingHistory() async throws {
        let fixture = try TimerFixture()
        let activity = try fixture.addActivity("History")
        let firstDate = Date(timeIntervalSince1970: 1_000)
        let secondDate = Date(timeIntervalSince1970: 2_000)
        let thirdDate = Date(timeIntervalSince1970: 3_000)
        let first = try fixture.addLog(activityId: activity, start: firstDate)
        let second = try fixture.addLog(activityId: activity, start: secondDate)
        let third = try fixture.addLog(activityId: activity, start: thirdDate)

        // An old preferences pointer cannot override the newest database timer.
        let recovered = try await fixture.logs.recoverRunningActivity(preferredLogId: first)
        #expect(recovered?.logId == third)
        let rows = try fixture.rows()
        #expect(rows.count == 3)
        #expect(rows.first { $0.id == first }?.end == secondDate)
        #expect(rows.first { $0.id == second }?.end == thirdDate)
        #expect(rows.filter { $0.end == nil }.count == 1)

        _ = try await fixture.logs.recoverRunningActivity()
        #expect(try fixture.rows().count == 3)
    }

    @Test func orphanedRowsArePreservedAndDoNotPreventRecovery() async throws {
        let fixture = try TimerFixture()
        let activity = try fixture.addActivity("Valid")
        let current = try fixture.addLog(activityId: activity, start: Date(timeIntervalSince1970: 1_000))
        let orphan = try fixture.addLog(activityId: nil, start: Date(timeIntervalSince1970: 500))
        let recovered = try await fixture.logs.recoverRunningActivity(preferredLogId: orphan)
        #expect(recovered?.logId == current)
        let rows = try fixture.rows()
        #expect(rows.count == 2)
        #expect(rows.first { $0.id == orphan }?.end == Date(timeIntervalSince1970: 1_000))
    }

    @Test func simultaneousStartsOfSameActivityCreateOneTimer() async throws {
        let fixture = try TimerFixture()
        let activity = try fixture.addActivity("One timer")
        let actor = fixture.logs
        let ids = await withTaskGroup(of: UUID?.self, returning: [UUID?].self) { group in
            for _ in 0..<20 {
                group.addTask { await actor.startActivity(activityId: activity) }
            }
            var values: [UUID?] = []
            for await value in group { values.append(value) }
            return values
        }
        #expect(ids.count == 20)
        #expect(ids.allSatisfy { $0 != nil })
        #expect(Set(ids.compactMap { $0 }).count == 1)
        #expect(try fixture.rows().count == 1)
    }

    @Test func simultaneousSwitchesLeaveOneRunningTimerAndKeepBothLogs() async throws {
        let fixture = try TimerFixture()
        let first = try fixture.addActivity("First")
        let second = try fixture.addActivity("Second")
        let logs = fixture.logs
        async let firstStart = logs.startActivity(activityId: first)
        async let secondStart = logs.startActivity(activityId: second)
        let (firstId, secondId) = await (firstStart, secondStart)
        #expect(firstId != nil)
        #expect(secondId != nil)
        #expect(firstId != secondId)
        let rows = try fixture.rows()
        #expect(rows.count == 2)
        #expect(rows.filter { $0.end == nil }.count == 1)
        #expect(rows.filter { $0.previousId != nil }.count == 1)
        #expect(rows.allSatisfy { ($0.end ?? .distantFuture) >= $0.start })
    }

    @Test func stoppingIsIdempotentAndSpecificStopChecksActivity() async throws {
        let fixture = try TimerFixture()
        let activity = try fixture.addActivity("Stop safely")
        #expect(try await fixture.logs.stopRunningActivity() == false)
        await fixture.logs.stopActivity(activityLogId: UUID())
        let running = try #require(try await fixture.logs.startOrSwitchActivity(activityId: activity))
        #expect(try await fixture.logs.stopRunningActivity(matchingActivityId: UUID()) == false)
        #expect(try await fixture.logs.recoverRunningActivity()?.logId == running.logId)
        #expect(try await fixture.logs.stopRunningActivity(matchingActivityId: activity))
        let ended = try #require(try fixture.rows().first?.end)
        await fixture.logs.stopActivity(activityLogId: running.logId)
        #expect(try await fixture.logs.stopRunningActivity() == false)
        #expect(try fixture.rows().first?.end == ended)
    }

    @Test func deletedActivitiesKeepRecoverableHistoryButCannotRestart() async throws {
        let fixture = try TimerFixture()
        let activity = try fixture.addActivity("Archived", deleted: true)
        let logId = try fixture.addLog(activityId: activity, start: Date(timeIntervalSince1970: 1_000))
        #expect(try await fixture.logs.recoverRunningActivity()?.logId == logId)
        #expect(try await fixture.logs.stopRunningActivity())
        #expect(try await fixture.logs.startOrSwitchActivity(activityId: activity) == nil)
        #expect(try fixture.rows().count == 1)
    }

    @Test func externallyArchivedActivityCannotRestartFromStaleActorContext() async throws {
        let fixture = try TimerFixture()
        let activity = try fixture.addActivity("Archive after registration")
        _ = try await fixture.logs.startOrSwitchActivity(activityId: activity)
        #expect(try await fixture.logs.stopRunningActivity())
        let editor = ActivityActor(modelContainer: fixture.container)
        await editor.delete(from: activity)
        #expect(try await fixture.logs.startOrSwitchActivity(activityId: activity) == nil)
        #expect(try fixture.rows().count == 1)
    }

    @Test func editingIntervalPreservesArchivedAndOrphanSplitTails() async throws {
        let fixture = try TimerFixture()
        let archived = try fixture.addActivity("Archived history", deleted: true)
        let active = try fixture.addActivity("Edited activity")
        func date(_ seconds: Double) -> Date { Date(timeIntervalSince1970: seconds) }
        let archivedLog = try fixture.addLog(activityId: archived, start: date(0), end: date(1_000))
        let orphanLog = try fixture.addLog(activityId: nil, start: date(0), end: date(1_000))
        let untouched = try fixture.addLog(activityId: archived, start: date(1_100), end: date(1_200))
        let edited = try fixture.addLog(activityId: active, start: date(400), end: date(600))
        let covered = try fixture.addLog(activityId: archived, start: date(450), end: date(550))

        try await fixture.logs.clearTimeFrame(startDate: date(400), endDate: date(600), logId: edited)

        let rows = try fixture.rows()
        #expect(rows.count == 6)
        #expect(rows.first { $0.id == archivedLog }?.end == date(400))
        #expect(rows.first { $0.id == orphanLog }?.end == date(400))
        let tails = rows.filter { $0.start == date(600) && $0.end == date(1_000) }
        #expect(tails.count == 2)
        #expect(tails.contains { $0.activityId == archived })
        #expect(tails.contains { $0.activityId == nil })
        #expect(rows.first { $0.id == untouched }?.start == date(1_100))
        #expect(rows.first { $0.id == untouched }?.end == date(1_200))
        #expect(rows.first { $0.id == edited }?.start == date(400))
        #expect(rows.first { $0.id == edited }?.end == date(600))
        #expect(!rows.contains { $0.id == covered })
        #expect(try await fixture.logs.startOrSwitchActivity(activityId: archived) == nil)
    }
}

@MainActor
private final class TimerFixture {
    let container: ModelContainer
    let logs: ActivityLogActor

    init() throws {
        let schema = Schema([ActivityItem.self, ActivityLog.self])
        container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
        logs = ActivityLogActor(modelContainer: container)
    }

    func addActivity(_ name: String, deleted: Bool = false) throws -> UUID {
        let context = ModelContext(container)
        let id = UUID()
        let activity = ActivityItem(id: id, name: name, deleted: deleted, storeLocation: false)
        context.insert(activity)
        try context.save()
        let verification = ModelContext(container)
        let saved = try #require(try verification.fetch(FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == id }
        )).first)
        try #require(saved.archived == deleted, "Archive state must survive a fresh SwiftData context")
        return id
    }

    func addLog(activityId: UUID?, start: Date, end: Date? = nil) throws -> UUID {
        let context = ModelContext(container)
        var activity: ActivityItem?
        if let activityId {
            activity = try context.fetch(FetchDescriptor<ActivityItem>(
                predicate: #Predicate { $0.id == activityId }
            )).first
        }
        let log = ActivityLog(startTime: start, endTime: end, activity: activity)
        context.insert(log)
        try context.save()
        return try #require(log.id)
    }

    struct Row {
        let id: UUID?
        let start: Date
        let end: Date?
        let previousId: UUID?
        let activityId: UUID?
    }

    func rows() throws -> [Row] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<ActivityLog>()).map {
            Row(id: $0.id, start: $0.startTime ?? .distantPast, end: $0.endTime,
                previousId: $0.previousActivityLogId, activityId: $0.activity?.id)
        }
    }
}
