import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct WorkHierarchyTests {
    @Test func tasksResolveEveryOptionalParentAndInheritPropertiesIndependently() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let actor = WorkHierarchyActor(modelContainer: container)
        let org = try await actor.saveOrganization(name: "Studio", colorHex: "112233", sfSymbolName: "building.2")
        let client = try await actor.saveClient(name: "Client", organizationID: org, sfSymbolName: "person.fill")
        let project = try await actor.saveProject(name: "Project", clientID: client, colorHex: "#AABBCC")
        let unassigned = try await actor.saveTask(name: "Unassigned", parent: nil)
        let directOrg = try await actor.saveTask(name: "Organization work", parent: .organization(org))
        let directClient = try await actor.saveTask(name: "Client work", parent: .client(client))
        let task = try await actor.saveTask(name: "Project work", parent: .project(project))

        let standalone = try await actor.resolveTask(taskID: unassigned)
        #expect(standalone.organization == nil && standalone.client == nil && standalone.project == nil)
        #expect(standalone.task?.colorHex == WorkHierarchy.defaultColorHex)
        #expect(standalone.task?.sfSymbolName == WorkHierarchy.defaultSymbolName)
        let organizationWork = try await actor.resolveTask(taskID: directOrg)
        #expect(organizationWork.organization?.id == org && organizationWork.client == nil)
        #expect(organizationWork.task?.colorHex == "#112233")
        let clientWork = try await actor.resolveTask(taskID: directClient)
        #expect(clientWork.organization?.id == org && clientWork.client?.id == client && clientWork.project == nil)
        #expect(clientWork.task?.colorHex == "#112233" && clientWork.task?.sfSymbolName == "person.fill")
        let projectWork = try await actor.resolveTask(taskID: task)
        #expect(projectWork.organization?.colorHex == "#112233")
        #expect(projectWork.client?.colorHex == "#112233" && projectWork.client?.sfSymbolName == "person.fill")
        #expect(projectWork.project?.colorHex == "#AABBCC" && projectWork.project?.sfSymbolName == "person.fill")
        #expect(projectWork.task?.colorHex == "#AABBCC" && projectWork.task?.sfSymbolName == "person.fill")
    }

    @Test func duplicateNamesAreTrimmedCaseInsensitiveAndScopedToImmediateParent() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let actor = WorkHierarchyActor(modelContainer: container)
        let first = try await actor.saveOrganization(name: " First ")
        let second = try await actor.saveOrganization(name: "Second")
        do {
            _ = try await actor.saveOrganization(name: " first ")
            Issue.record("Duplicate organization should be rejected")
        } catch { #expect(error as? WorkHierarchyError == .duplicateName) }
        let client = try await actor.saveClient(name: "Shared", organizationID: first)
        _ = try await actor.saveClient(name: "shared", organizationID: second)
        do {
            _ = try await actor.saveClient(name: " SHARED ", organizationID: first)
            Issue.record("Duplicate client in the same organization should be rejected")
        } catch { #expect(error as? WorkHierarchyError == .duplicateName) }
        _ = try await actor.saveTask(name: "Focus", parent: nil)
        _ = try await actor.saveTask(name: "Focus", parent: .organization(first))
        _ = try await actor.saveTask(name: "Focus", parent: .client(client))
        do {
            _ = try await actor.saveTask(name: " focus ", parent: .client(client))
            Issue.record("Duplicate task in the same immediate parent should be rejected")
        } catch { #expect(error as? WorkHierarchyError == .duplicateName) }
        #expect(try ModelContext(container).fetch(FetchDescriptor<WorkClient>()).count == 2)
        #expect(try ModelContext(container).fetch(FetchDescriptor<ActivityItem>()).count == 3)
    }

    @Test func missingParentsAndInvalidInputsLeaveTheStoreUntouched() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let actor = WorkHierarchyActor(modelContainer: container)
        do {
            _ = try await actor.saveClient(name: "Invalid", organizationID: UUID())
            Issue.record("Missing organization should be rejected")
        } catch { #expect(error as? WorkHierarchyError == .missingEntity) }
        do {
            _ = try await actor.saveProject(name: "Invalid", clientID: UUID())
            Issue.record("Missing client should be rejected")
        } catch { #expect(error as? WorkHierarchyError == .missingEntity) }
        do {
            _ = try await actor.saveTask(name: "Invalid", parent: .project(UUID()))
            Issue.record("Missing project should be rejected")
        } catch { #expect(error as? WorkHierarchyError == .missingEntity) }
        do {
            _ = try await actor.saveOrganization(name: "   ")
            Issue.record("Empty name should be rejected")
        } catch { #expect(error as? WorkHierarchyError == .emptyName) }
        do {
            _ = try await actor.saveOrganization(name: "Color", colorHex: "red")
            Issue.record("Invalid color should be rejected")
        } catch { #expect(error as? WorkHierarchyError == .invalidColor) }
        let context = ModelContext(container)
        #expect(try context.fetch(FetchDescriptor<WorkOrganization>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<WorkClient>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<WorkProject>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<ActivityItem>()).isEmpty)
    }

    @Test func archivedAncestorsBlockNewStartsButRunningTimerRemainsRecoverableAndStoppable() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let work = WorkHierarchyActor(modelContainer: container)
        let logs = ActivityLogActor(modelContainer: container)
        let org = try await work.saveOrganization(name: "Studio")
        let client = try await work.saveClient(name: "Client", organizationID: org)
        let project = try await work.saveProject(name: "Project", clientID: client)
        let task = try await work.saveTask(name: "Task", parent: .project(project))
        let running = try #require(try await logs.startOrSwitchActivity(activityId: task))
        try await work.setArchived(kind: .organization, id: org, archived: true)
        #expect(try await logs.startOrSwitchActivity(activityId: task) == nil)
        let recovered = try await logs.recoverRunningActivity()
        #expect(recovered?.logId == running.logId)
        #expect(try await logs.stopRunningActivity())
        #expect(try await logs.recoverRunningActivity() == nil)
        #expect(try await ActivityActor(modelContainer: container).getStartableActivitySnapshots().isEmpty)
        try await work.setArchived(kind: .organization, id: org, archived: false)
        #expect(try await logs.startOrSwitchActivity(activityId: task) != nil)
        #expect(try await ActivityActor(modelContainer: container).getStartableActivitySnapshots().count == 1)
    }

    @Test func corruptedParentPairCannotBecomeAStartableUnassignedTask() throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let task = ActivityItem(name: "Corrupted")
        task.workParentKindRaw = "client"
        context.insert(task)
        try context.save()
        #expect(!WorkHierarchy.isAvailable(task: task, in: context))
    }

    @Test func malformedTasksCannotCreateNewTimeButExistingHistoryCanBeEditedAndExported() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let task = ActivityItem(name: "   ")
        let taskID = try #require(task.id)
        let missingID = ActivityItem(name: "Missing identity")
        missingID.id = nil
        let log = ActivityLog(startTime: Date(timeIntervalSince1970: 0),
                              endTime: Date(timeIntervalSince1970: 100), activity: task)
        let logID = try #require(log.id)
        context.insert(task)
        context.insert(missingID)
        context.insert(log)
        try context.save()
        let actor = ActivityLogActor(modelContainer: container)
        #expect(!WorkHierarchy.isAvailable(task: task, in: context))
        #expect(!WorkHierarchy.isAvailable(task: missingID, in: context))
        #expect(try await actor.startOrSwitchActivity(activityId: taskID) == nil)
        do {
            _ = try await actor.saveCompletedLog(activityId: taskID,
                startTime: Date(timeIntervalSince1970: 200), endTime: Date(timeIntervalSince1970: 300))
            Issue.record("Malformed task cannot receive a new manual log")
        } catch { #expect(error as? ActivityLogActor.ManualLogError == .unavailableActivity) }
        try await actor.saveCompletedLog(logId: logID, activityId: taskID,
            startTime: Date(timeIntervalSince1970: 10), endTime: Date(timeIntervalSince1970: 90))
        let saved = try #require(try ModelContext(container).fetch(FetchDescriptor<ActivityLog>()).first)
        #expect(saved.id == logID && saved.startTime == Date(timeIntervalSince1970: 10))
        #expect(saved.endTime == Date(timeIntervalSince1970: 90))
        let target = FileManager.default.temporaryDirectory.appendingPathComponent("malformed-history-\(UUID()).csv")
        defer { try? FileManager.default.removeItem(at: target) }
        _ = try await CsvHandler().exportDataAsCsv(logs: [saved], destinationURL: target)
        let csv = try String(contentsOf: target, encoding: .utf8)
        #expect(csv.contains("1970-01-01T00:00:10Z") && csv.contains("1970-01-01T00:01:30Z"))
        #expect(try ModelContext(container).fetch(FetchDescriptor<ActivityLog>()).count == 1)
    }
}
