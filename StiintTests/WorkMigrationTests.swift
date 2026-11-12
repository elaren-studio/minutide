import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct WorkMigrationTests {
    @Test func realUnversionedV1DiskStoreMigratesWithoutLosingHistoryOrRunningTimer() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("minutide-v1-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("history.store")
        let ids = FixtureIDs()

        // A separate synchronous scope releases the V1 context/container before V2 opens.
        try autoreleasepool { try seedReleasedUnversionedStore(at: url, ids: ids) }
        #expect(FileManager.default.fileExists(atPath: url.path))
        try autoreleasepool { try verifyMigrationAndMoveTask(at: url, ids: ids) }
        try autoreleasepool { try verifyReopenIsIdempotent(at: url, ids: ids) }
        try await verifyOpenTimer(at: url, ids: ids)
    }

    @Test func legacyBackfillDoesNotInferCurrentHierarchyAndRunsOnlyOnce() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let work = WorkHierarchyActor(modelContainer: container)
        let org = try await work.saveOrganization(name: "New organization")
        let taskID = try await work.saveTask(name: "Legacy task", parent: .organization(org))
        let context = ModelContext(container)
        let task = try #require(try context.fetch(FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == taskID })).first)
        let log = ActivityLog(startTime: date(0), endTime: date(100), activity: task)
        context.insert(log)
        try context.save()
        try WorkStore.bootstrapLegacySnapshots(in: container)
        let captured = try ModelContext(container).fetch(FetchDescriptor<ActivityLog>()).first?.workSnapshot
        #expect(captured?.task?.id == taskID && captured?.organization == nil)
        _ = try await work.saveTask(id: taskID, name: "Changed", parent: nil, colorHex: "#FFFFFF")
        try WorkStore.bootstrapLegacySnapshots(in: container)
        let reopened = try ModelContext(container).fetch(FetchDescriptor<ActivityLog>()).first?.workSnapshot
        #expect(reopened == captured)
    }

    private struct FixtureIDs {
        let active = UUID()
        let archived = UUID()
        let completed = UUID()
        let archivedLog = UUID()
        let orphan = UUID()
        let running = UUID()
        let organization = UUID()
    }

    private func seedReleasedUnversionedStore(at url: URL, ids: FixtureIDs) throws {
        // Intentionally use the released UNVERSIONED Schema construction, not Schema(versionedSchema:).
        let schema = Schema([MinutideSchemaV1.ActivityItem.self, MinutideSchemaV1.ActivityLog.self])
        let container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        ])
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let active = MinutideSchemaV1.ActivityItem(id: ids.active, name: "Legacy active")
        active.createdDate = date(-100)
        active.colorHex = "#112233"
        active.sfSymbolName = "book.fill"
        active.weekdays = [.monday, .friday]
        active.storeLocation = true
        let archived = MinutideSchemaV1.ActivityItem(id: ids.archived, name: "Archived", archived: true)
        let malformed = MinutideSchemaV1.ActivityItem(id: nil, name: nil)
        for task in [active, archived, malformed] { context.insert(task) }
        let completed = MinutideSchemaV1.ActivityLog(id: ids.completed, startTime: date(0),
                                                     endTime: date(100), activity: active)
        completed.previousActivityLogId = ids.archivedLog
        completed.startLatitude = 32
        completed.startLongitude = -97
        completed.endLatitude = 33
        completed.endLongitude = -98
        let historical = MinutideSchemaV1.ActivityLog(id: ids.archivedLog, startTime: date(100),
                                                      endTime: date(200), activity: archived)
        let orphan = MinutideSchemaV1.ActivityLog(id: ids.orphan, startTime: date(200), endTime: date(300))
        let invalid = MinutideSchemaV1.ActivityLog(id: nil, startTime: nil, endTime: date(400), activity: malformed)
        let running = MinutideSchemaV1.ActivityLog(id: ids.running, startTime: date(500), activity: active)
        running.previousActivityLogId = ids.completed
        for log in [completed, historical, orphan, invalid, running] { context.insert(log) }
        try context.save()
        #expect(try context.fetch(FetchDescriptor<MinutideSchemaV1.ActivityLog>()).count == 5)
    }

    private func verifyMigrationAndMoveTask(at url: URL, ids: FixtureIDs) throws {
        let container = try WorkStore.makeContainer(url: url)
        let context = ModelContext(container)
        let tasks = try context.fetch(FetchDescriptor<ActivityItem>())
        let logs = try context.fetch(FetchDescriptor<ActivityLog>())
        #expect(tasks.count == 3 && logs.count == 5)
        let task = try #require(tasks.first { $0.id == ids.active })
        #expect(task.name == "Legacy active" && task.createdDate == date(-100))
        #expect(task.weekdays == [.monday, .friday] && task.storeLocation == true)
        #expect(tasks.first { $0.id == ids.archived }?.archived == true)
        #expect(tasks.contains { $0.id == nil && $0.name == nil })
        let completed = try #require(logs.first { $0.id == ids.completed })
        #expect(completed.startTime == date(0) && completed.endTime == date(100))
        #expect(completed.activity?.id == ids.active && completed.previousActivityLogId == ids.archivedLog)
        #expect(completed.startLatitude == 32 && completed.startLongitude == -97)
        #expect(completed.endLatitude == 33 && completed.endLongitude == -98)
        #expect(completed.workSnapshot.task?.id == ids.active)
        #expect(completed.workSnapshot.task?.name == "Legacy active")
        #expect(completed.workSnapshot.task?.colorHex == "#112233")
        #expect(completed.workSnapshot.task?.sfSymbolName == "book.fill")
        #expect(logs.first { $0.id == ids.archivedLog }?.activity?.id == ids.archived)
        #expect(logs.first { $0.id == ids.orphan }?.activity == nil)
        #expect(logs.contains { $0.id == nil && $0.startTime == nil && $0.endTime == date(400) })
        let running = try #require(logs.first { $0.id == ids.running })
        #expect(running.startTime == date(500) && running.endTime == nil)
        #expect(running.previousActivityLogId == ids.completed)
        #expect(logs.allSatisfy { $0.hierarchySnapshotVersion == 1 })
        #expect(logs.allSatisfy { $0.workSnapshot.organization == nil && $0.workSnapshot.client == nil
            && $0.workSnapshot.project == nil })

        // Moving the task after migration must not retroactively classify any legacy entry.
        let organization = WorkOrganization(id: ids.organization, name: "Later organization", colorHex: "#FFFFFF")
        context.insert(organization)
        task.workParent = .organization(ids.organization)
        task.name = "Renamed later"
        task.colorHex = "#FFFFFF"
        try context.save()
    }

    private func verifyReopenIsIdempotent(at url: URL, ids: FixtureIDs) throws {
        let container = try WorkStore.makeContainer(url: url)
        let context = ModelContext(container)
        let logs = try context.fetch(FetchDescriptor<ActivityLog>())
        #expect(logs.count == 5)
        #expect(logs.allSatisfy { $0.hierarchySnapshotVersion == 1 && $0.workSnapshot.organization == nil })
        let completed = try #require(logs.first { $0.id == ids.completed })
        #expect(completed.workSnapshot.task?.name == "Legacy active")
        #expect(completed.workSnapshot.task?.colorHex == "#112233")
        let task = try #require(try context.fetch(FetchDescriptor<ActivityItem>()).first { $0.id == ids.active })
        #expect(task.workParent == .organization(ids.organization) && task.name == "Renamed later")
    }

    private func verifyOpenTimer(at url: URL, ids: FixtureIDs) async throws {
        let container = try WorkStore.makeContainer(url: url)
        let actor = ActivityLogActor(modelContainer: container)
        let running = try #require(try await actor.recoverRunningActivity(preferredLogId: ids.running))
        #expect(running.logId == ids.running)
        #expect(running.activity.id == ids.active && running.activity.startTime == date(500))
        #expect(running.activity.name == "Legacy active")
        #expect(try ModelContext(container).fetch(FetchDescriptor<ActivityLog>()).count == 5)
    }

    private func date(_ seconds: Double) -> Date { Date(timeIntervalSince1970: seconds) }
}
