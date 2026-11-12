import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import Stiint

@MainActor
struct LiveActivityDetailsTests {
    @Test func legacyActivityKitAttributesDecodeWhenWorkNamesAreAbsent() throws {
        let payload = Data(##"{"id":"00000000-0000-0000-0000-000000000001","name":"Legacy task","startTime":0,"icon":"book.fill","color":"#007AFF"}"##.utf8)

        let attributes = try JSONDecoder().decode(LiveActivityDTO.self, from: payload)

        #expect(attributes.name == "Legacy task")
        #expect(attributes.startTime == Date(timeIntervalSinceReferenceDate: 0))
        #expect(attributes.organizationName == nil)
        #expect(attributes.clientName == nil)
        #expect(attributes.projectName == nil)
        #expect(attributes.workPath.isEmpty)
    }

    @Test func currentActivityKitAttributesRoundTripCapturedWorkNames() throws {
        let attributes = LiveActivityDTO(
            id: UUID(),
            name: "Planning",
            startTime: Date(timeIntervalSince1970: 1_700_000_000),
            icon: "book.fill",
            color: "#007AFF",
            organizationName: "Studio",
            clientName: "Client",
            projectName: "Project"
        )

        let payload = try JSONEncoder().encode(attributes)
        let decoded = try JSONDecoder().decode(LiveActivityDTO.self, from: payload)

        #expect(decoded == attributes)
        #expect(decoded.workPath == "Studio › Client › Project")
    }

    @Test func existingActivityDTOInitializerKeepsHierarchyNamesOptional() {
        let dto = ActivityDTO(
            id: UUID(),
            name: "Task",
            startTime: Date(timeIntervalSince1970: 100),
            icon: "book.fill",
            color: .blue,
            weekdays: []
        )

        #expect(dto.organizationName == nil)
        #expect(dto.clientName == nil)
        #expect(dto.projectName == nil)
        #expect(dto.workPath.isEmpty)
    }

    @Test func runningActivityDTOUsesImmutableLogSnapshotNames() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let work = WorkHierarchyActor(modelContainer: container)
        let logs = ActivityLogActor(modelContainer: container)
        let organization = try await work.saveOrganization(name: "Studio")
        let client = try await work.saveClient(name: "Client", organizationID: organization)
        let project = try await work.saveProject(name: "Project", clientID: client)
        let task = try await work.saveTask(name: "Planning", parent: .project(project))
        let started = try #require(try await logs.startOrSwitchActivity(activityId: task))

        _ = try await work.saveOrganization(id: organization, name: "Renamed studio")
        _ = try await work.saveClient(id: client, name: "Renamed client", organizationID: organization)
        _ = try await work.saveProject(id: project, name: "Renamed project", clientID: client)
        _ = try await work.saveTask(id: task, name: "Renamed task", parent: .project(project))

        let recovered = try #require(try await ActivityLogActor(modelContainer: container).recoverRunningActivity())

        #expect(recovered.logId == started.logId)
        #expect(recovered.activity.startTime == started.activity.startTime)
        #expect(recovered.activity.name == "Planning")
        #expect(recovered.activity.organizationName == "Studio")
        #expect(recovered.activity.clientName == "Client")
        #expect(recovered.activity.projectName == "Project")
        #expect(recovered.activity.workPath == "Studio › Client › Project")
        #expect(recovered.activity.endTime == nil)
    }

    @Test func unassignedRunningActivityProjectsNoWorkBreadcrumb() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let work = WorkHierarchyActor(modelContainer: container)
        let logs = ActivityLogActor(modelContainer: container)
        let task = try await work.saveTask(name: "Personal task", parent: nil)

        let running = try #require(try await logs.startOrSwitchActivity(activityId: task))

        #expect(running.activity.organizationName == nil)
        #expect(running.activity.clientName == nil)
        #expect(running.activity.projectName == nil)
        #expect(running.activity.workPath.isEmpty)
    }
}
