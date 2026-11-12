import Foundation
import CoreLocation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct ManualLogMutationTests {
    @Test func warmedActorRefetchesManualEditsAndDeletedOverlapRows() async throws {
        let fixture = try ManualLogFixture()
        let activity = try fixture.activity("Active")
        let head = try fixture.log(activity: activity, start: 0, end: 1_000)
        let covered = try fixture.log(activity: activity, start: 450, end: 550)
        let edited = try fixture.log(activity: activity, start: 1_100, end: 1_200)
        for id in [head, covered, edited] {
            #expect(await fixture.actor.getActivtyLogDTO(activityLogId: id) != nil)
        }

        try await fixture.actor.saveCompletedLog(logId: edited, activityId: activity,
                                                  startTime: date(400), endTime: date(600))
        let headDTO = await fixture.actor.getActivtyLogDTO(activityLogId: head)
        let editedDTO = await fixture.actor.getActivtyLogDTO(activityLogId: edited)
        #expect(headDTO?.endTime == date(400))
        #expect(editedDTO?.startTime == date(400) && editedDTO?.endTime == date(600))
        #expect(await fixture.actor.getActivtyLogDTO(activityLogId: covered) == nil)
        #expect(try await fixture.actor.recoverRunningActivity() == nil)
        #expect(try fixture.rows().count == 3)
    }

    @Test func delayedLocationCannotRestoreCoordinatesForAnEditedBoundary() async throws {
        let fixture = try ManualLogFixture()
        let activity = try fixture.activity("Located", storeLocation: true)
        let edited = try fixture.log(activity: activity, start: 0, end: 1_000)
        #expect(await fixture.actor.getActivtyLogDTO(activityLogId: edited) != nil)
        try await fixture.actor.saveCompletedLog(logId: edited, activityId: activity,
                                                  startTime: date(400), endTime: date(600))
        let location = CLLocation(latitude: 32, longitude: -97)
        #expect(try await fixture.actor.applyCapturedLocation(location, activityLogId: edited,
                    activityId: activity, boundary: date(0), isStart: true) == false)
        #expect(try await fixture.actor.applyCapturedLocation(location, activityLogId: edited,
                    activityId: activity, boundary: date(1_000), isStart: false) == false)
        let unchanged = try #require(fixture.rows().first)
        #expect(unchanged.startLatitude == nil && unchanged.endLatitude == nil)

        #expect(try await fixture.actor.applyCapturedLocation(location, activityLogId: edited,
                    activityId: activity, boundary: date(400), isStart: true))
        let stored = try #require(fixture.rows().first)
        #expect(stored.startLatitude == 32 && stored.endLatitude == nil)
        #expect(stored.start == date(400) && stored.end == date(600))
    }

    @Test func delayedLocationHonorsReassignmentOptOutArchiveAndDeletion() async throws {
        let fixture = try ManualLogFixture()
        let first = try fixture.activity("First", storeLocation: true)
        let second = try fixture.activity("Second", storeLocation: true)
        let edited = try fixture.log(activity: first, start: 0, end: 100)
        try await fixture.actor.saveCompletedLog(logId: edited, activityId: second,
                                                  startTime: date(0), endTime: date(100))
        let location = CLLocation(latitude: 32, longitude: -97)
        #expect(try await fixture.actor.applyCapturedLocation(location, activityLogId: edited,
                    activityId: first, boundary: date(0), isStart: true) == false)
        try fixture.setLocationPolicy(activity: second, enabled: false, archived: false)
        #expect(try await fixture.actor.applyCapturedLocation(location, activityLogId: edited,
                    activityId: second, boundary: date(100), isStart: false) == false)
        try fixture.setLocationPolicy(activity: second, enabled: true, archived: true)
        #expect(try await fixture.actor.applyCapturedLocation(location, activityLogId: edited,
                    activityId: second, boundary: date(100), isStart: false) == false)
        try fixture.deleteLog(edited)
        #expect(try await fixture.actor.applyCapturedLocation(location, activityLogId: edited,
                    activityId: second, boundary: date(100), isStart: false) == false)
        #expect(try fixture.rows().isEmpty)
    }

    @Test func analyticsActorQueryIncludesSelectedRunningLogAcrossFilterBoundary() async throws {
        let fixture = try ManualLogFixture()
        let selected = try fixture.activity("Selected")
        let excluded = try fixture.activity("Excluded")
        let running = try fixture.log(activity: selected, start: 0, end: nil)
        _ = try fixture.log(activity: excluded, start: 0, end: nil)
        _ = try fixture.log(activity: selected, start: 0, end: 50)
        _ = try fixture.log(activity: selected, start: 300, end: nil)
        let filter = FilterData(startDate: date(100), endDate: date(200),
                                showFreeTime: false, selectedActivityIds: [selected])
        let logs = await fixture.actor.getActivityLogsForTimeFrame(filterData: filter)
        #expect(logs.count == 1 && logs.first?.id == running)
        let frame = TimeFrameData(filterData: filter, logs: logs)
        #expect(frame.timeSpendOnActivities == 100)
        #expect(frame.dataSeries.reduce(0) { $0 + $1.timeSpend } == 100)
        #expect(try fixture.rows().filter { $0.end == nil }.count == 3)
    }

    @Test func archivedAndMissingCreationTargetsPreserveAllOverlappingHistory() async throws {
        let fixture = try ManualLogFixture()
        let active = try fixture.activity("Active")
        let archived = try fixture.activity("Archived", archived: true)
        _ = try fixture.log(activity: active, start: 0, end: 1_000)
        _ = try fixture.log(activity: archived, start: 450, end: 550)
        _ = try fixture.log(activity: nil, start: 300, end: 700)
        let original = try fixture.rows()

        for target in [archived, UUID()] {
            do {
                try await fixture.actor.saveCompletedLog(activityId: target, startTime: date(400), endTime: date(600))
                Issue.record("An unavailable target must fail before clearing overlap history")
            } catch {
                #expect(error as? ActivityLogActor.ManualLogError == .unavailableActivity)
            }
            #expect(try fixture.rows() == original)
        }
    }

    @Test func creatingLogPreservesArchivedAndOrphanOuterSegments() async throws {
        let fixture = try ManualLogFixture()
        let active = try fixture.activity("Active")
        let archived = try fixture.activity("Archived", archived: true)
        let original = try fixture.log(activity: archived, start: 0, end: 1_000, coordinates: true)
        _ = try fixture.log(activity: nil, start: 100, end: 900)
        _ = try fixture.log(activity: active, start: 450, end: 550)
        let untouched = try fixture.log(activity: archived, start: 1_100, end: 1_200)

        let created = try await fixture.actor.saveCompletedLog(activityId: active, startTime: date(400), endTime: date(600))
        let rows = try fixture.rows()
        #expect(rows.count == 6)
        #expect(rows.contains { $0.id == created && $0.activity == active && $0.start == date(400) && $0.end == date(600) })
        #expect(rows.contains { $0.id == untouched && $0.start == date(1_100) && $0.end == date(1_200) })
        let head = try #require(rows.first { $0.id == original })
        #expect(head.start == date(0) && head.end == date(400))
        #expect(head.startLatitude == 32 && head.endLatitude == nil)
        let tail = try #require(rows.first { $0.activity == archived && $0.start == date(600) })
        #expect(tail.end == date(1_000) && tail.startLatitude == nil && tail.endLatitude == 33)
        #expect(rows.contains { $0.activity == nil && $0.start == date(100) && $0.end == date(400) })
        #expect(rows.contains { $0.activity == nil && $0.start == date(600) && $0.end == date(900) })
    }

    @Test func editingLogReplacesOverlapAndKeepsItsIdentity() async throws {
        let fixture = try ManualLogFixture()
        let active = try fixture.activity("Active")
        let archived = try fixture.activity("Archived", archived: true)
        _ = try fixture.log(activity: archived, start: 0, end: 1_000)
        let edited = try fixture.log(activity: active, start: 1_100, end: 1_200, coordinates: true)

        let result = try await fixture.actor.saveCompletedLog(logId: edited, activityId: active, startTime: date(400), endTime: date(600))
        let rows = try fixture.rows()
        #expect(result == edited && rows.count == 3)
        let replacement = try #require(rows.first { $0.id == edited })
        #expect(replacement.start == date(400) && replacement.end == date(600))
        #expect(replacement.startLatitude == nil && replacement.endLatitude == nil)
        #expect(rows.contains { $0.activity == archived && $0.start == date(0) && $0.end == date(400) })
        #expect(rows.contains { $0.activity == archived && $0.start == date(600) && $0.end == date(1_000) })
    }

    @Test func editingMayKeepArchivedOrMissingAssignmentButCannotSwitchToAnotherArchive() async throws {
        let fixture = try ManualLogFixture()
        let archived = try fixture.activity("Archived", archived: true)
        let anotherArchive = try fixture.activity("Another archive", archived: true)
        let edited = try fixture.log(activity: archived, start: 0, end: 100)
        let orphan = try fixture.log(activity: nil, start: 200, end: 300)

        try await fixture.actor.saveCompletedLog(logId: edited, activityId: archived, startTime: date(10), endTime: date(90))
        try await fixture.actor.saveCompletedLog(logId: orphan, activityId: nil, startTime: date(210), endTime: date(290))
        let beforeRejectedEdit = try fixture.rows()
        do {
            try await fixture.actor.saveCompletedLog(logId: edited, activityId: anotherArchive, startTime: date(20), endTime: date(280))
            Issue.record("Switching a historical log to another archived activity must fail")
        } catch {
            #expect(error as? ActivityLogActor.ManualLogError == .unavailableActivity)
        }
        #expect(try fixture.rows() == beforeRejectedEdit)
        #expect(beforeRejectedEdit.contains { $0.id == edited && $0.activity == archived })
        #expect(beforeRejectedEdit.contains { $0.id == orphan && $0.activity == nil })
    }

    @Test func databaseRunningTimerBlocksOverlapsWithoutAPreferenceOrDTOMirror() async throws {
        let fixture = try ManualLogFixture()
        let active = try fixture.activity("Active")
        _ = try fixture.log(activity: active, start: 0, end: 1_000)
        let running = try fixture.log(activity: active, start: 500, end: nil)
        let before = try fixture.rows()
        do {
            try await fixture.actor.saveCompletedLog(activityId: active, startTime: date(400), endTime: date(600))
            Issue.record("Manual mutation must consult persisted running timers")
        } catch {
            #expect(error as? ActivityLogActor.ManualLogError == .runningActivityOverlap)
        }
        #expect(try fixture.rows() == before)
        do {
            try await fixture.actor.saveCompletedLog(logId: running, activityId: active, startTime: date(300), endTime: date(400))
            Issue.record("Manual editing must not close a running log")
        } catch {
            #expect(error as? ActivityLogActor.ManualLogError == .unavailableLog)
        }
        #expect(try fixture.rows() == before)
    }

    @Test func invalidIntervalsCannotClearHistory() async throws {
        let fixture = try ManualLogFixture()
        let active = try fixture.activity("Active")
        _ = try fixture.log(activity: active, start: 0, end: 1_000)
        let before = try fixture.rows()
        let intervals = [(date(600), date(400)), (date(400), date(400)),
                         (Date(timeIntervalSinceReferenceDate: .infinity), date(600)),
                         (date(400), Date(timeIntervalSinceReferenceDate: .nan)),
                         (Date.now, Date.now.addingTimeInterval(3_600))]
        for (start, end) in intervals {
            do {
                try await fixture.actor.saveCompletedLog(activityId: active, startTime: start, endTime: end)
                Issue.record("An invalid completed interval must be rejected")
            } catch {
                #expect(error as? ActivityLogActor.ManualLogError == .invalidInterval)
            }
            #expect(try fixture.rows() == before)
        }
    }
}

private func date(_ seconds: Double) -> Date { Date(timeIntervalSince1970: seconds) }

@MainActor
private final class ManualLogFixture {
    let container: ModelContainer
    let actor: ActivityLogActor

    init() throws {
        let schema = Schema([ActivityItem.self, ActivityLog.self])
        container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
        actor = ActivityLogActor(modelContainer: container)
    }

    func activity(_ name: String, archived: Bool = false, storeLocation: Bool = false) throws -> UUID {
        let context = ModelContext(container)
        let activity = ActivityItem(name: name, deleted: archived, storeLocation: storeLocation)
        context.insert(activity)
        try context.save()
        return try #require(activity.id)
    }

    func setLocationPolicy(activity id: UUID, enabled: Bool, archived: Bool) throws {
        let context = ModelContext(container)
        let activity = try #require(try context.fetch(FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == id }
        )).first)
        activity.storeLocation = enabled
        activity.archived = archived
        try context.save()
    }

    func deleteLog(_ id: UUID) throws {
        let context = ModelContext(container)
        let log = try #require(try context.fetch(FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == id }
        )).first)
        context.delete(log)
        try context.save()
    }

    func log(activity id: UUID?, start: Double, end: Double?, coordinates: Bool = false) throws -> UUID {
        let context = ModelContext(container)
        let activity: ActivityItem?
        if let id {
            activity = try context.fetch(FetchDescriptor<ActivityItem>(predicate: #Predicate { $0.id == id })).first
        } else { activity = nil }
        let log = ActivityLog(startTime: date(start), endTime: end.map(date), activity: activity)
        if coordinates {
            log.startLatitude = 32; log.startLongitude = -97
            log.endLatitude = 33; log.endLongitude = -98
        }
        context.insert(log)
        try context.save()
        return try #require(log.id)
    }

    struct Row: Equatable {
        let id: UUID?
        let activity: UUID?
        let start: Date?
        let end: Date?
        let startLatitude: Double?
        let endLatitude: Double?
    }

    func rows() throws -> [Row] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<ActivityLog>()).map {
            Row(id: $0.id, activity: $0.activity?.id, start: $0.startTime, end: $0.endTime,
                startLatitude: $0.startLatitude, endLatitude: $0.endLatitude)
        }.sorted { ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "") }
    }
}
