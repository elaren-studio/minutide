import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct WorkSnapshotTests {
    @Test func movingAndRenamingTaskPreservesHistoryUntilExplicitLogReclassification() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let work = WorkHierarchyActor(modelContainer: container)
        let logs = ActivityLogActor(modelContainer: container)
        let first = try await work.saveOrganization(name: "First", colorHex: "#112233", sfSymbolName: "building.2")
        let second = try await work.saveOrganization(name: "Second", colorHex: "#AABBCC", sfSymbolName: "house")
        let task = try await work.saveTask(name: "Original task", parent: .organization(first))
        let id = try await logs.saveCompletedLog(activityId: task, startTime: date(0), endTime: date(100))
        let captured = try stored(id, in: container).workSnapshot
        _ = try await work.saveTask(id: task, name: "Renamed task", parent: .organization(second))
        #expect(try stored(id, in: container).workSnapshot == captured)
        try await logs.saveCompletedLog(logId: id, activityId: task, startTime: date(10), endTime: date(90))
        #expect(try stored(id, in: container).workSnapshot == captured)
        #expect(try stored(id, in: container).workSnapshot.task?.name == "Original task")
        try await logs.saveCompletedLog(logId: id, activityId: task, startTime: date(10), endTime: date(90),
                                        refreshAssignment: true)
        let refreshed = try stored(id, in: container).workSnapshot
        #expect(refreshed.organization?.id == second && refreshed.task?.name == "Renamed task")
        #expect(refreshed.task?.colorHex == "#AABBCC" && refreshed.task?.sfSymbolName == "house")
    }

    @Test func splitSegmentsKeepOriginalHierarchyNameAndStyle() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let work = WorkHierarchyActor(modelContainer: container)
        let logs = ActivityLogActor(modelContainer: container)
        let org = try await work.saveOrganization(name: "Original", colorHex: "#112233")
        let task = try await work.saveTask(name: "History", parent: .organization(org))
        let replacementTask = try await work.saveTask(name: "Replacement", parent: nil)
        let head = try await logs.saveCompletedLog(activityId: task, startTime: date(0), endTime: date(300))
        let original = try stored(head, in: container).workSnapshot
        _ = try await work.saveOrganization(id: org, name: "Renamed", colorHex: "#FFFFFF")
        try await work.setArchived(kind: .task, id: task, archived: true)
        _ = try await logs.saveCompletedLog(activityId: replacementTask, startTime: date(100), endTime: date(200))
        let rows = try ModelContext(container).fetch(FetchDescriptor<ActivityLog>())
        let outer = rows.filter { $0.workSnapshot.task?.id == task }
        #expect(outer.count == 2)
        #expect(outer.allSatisfy { $0.workSnapshot == original })
        #expect(outer.contains { $0.startTime == date(0) && $0.endTime == date(100) })
        #expect(outer.contains { $0.startTime == date(200) && $0.endTime == date(300) })
    }

    @Test func startingAfterWarmReadUsesFreshHierarchyAndRecoveryUsesCapturedAppearance() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let work = WorkHierarchyActor(modelContainer: container)
        let logs = ActivityLogActor(modelContainer: container)
        let first = try await work.saveOrganization(name: "First", colorHex: "#112233")
        let second = try await work.saveOrganization(name: "Second", colorHex: "#AABBCC", sfSymbolName: "house")
        let task = try await work.saveTask(name: "Task", parent: .organization(first))
        _ = await logs.getAllActivityLogs()
        let earlier = try #require(try await logs.startOrSwitchActivity(activityId: task))
        #expect(try await logs.stopRunningActivity())
        _ = try await work.saveTask(id: task, name: "Moved", parent: .organization(second))
        let running = try #require(try await logs.startOrSwitchActivity(activityId: task))
        #expect(running.logId != earlier.logId)
        #expect(try stored(running.logId, in: container).workSnapshot.organization?.id == second)
        _ = try await work.saveTask(id: task, name: "Changed again", parent: nil)
        let recovered = try #require(try await logs.recoverRunningActivity())
        #expect(recovered.logId == running.logId && recovered.activity.name == "Moved")
        #expect(recovered.activity.icon == "house")
    }

    @Test func explicitChangeOfLogTaskRefreshesSnapshotAndReportBoundaryReturnsValues() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let work = WorkHierarchyActor(modelContainer: container)
        let logs = ActivityLogActor(modelContainer: container)
        let org = try await work.saveOrganization(name: "Studio")
        let first = try await work.saveTask(name: "First", parent: nil)
        let second = try await work.saveTask(name: "Second", parent: .organization(org))
        let id = try await logs.saveCompletedLog(activityId: first, startTime: date(0), endTime: date(100))
        try await logs.saveCompletedLog(logId: id, activityId: second, startTime: date(0), endTime: date(100))
        let entries = try await logs.getReportLogs(start: date(50), end: date(60), now: date(200))
        #expect(entries.count == 1)
        #expect(entries.first?.workSnapshot.task?.id == second)
        #expect(entries.first?.workSnapshot.organization?.id == org)
        #expect(entries.first?.startTime == date(0) && entries.first?.endTime == date(100))
    }

    private func date(_ seconds: Double) -> Date { Date(timeIntervalSince1970: seconds) }

    private func stored(_ id: UUID, in container: ModelContainer) throws -> ActivityLog {
        try #require(try ModelContext(container).fetch(FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == id })).first)
    }
}
