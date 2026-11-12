import AppIntents
import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct ActivityQueryTests {
    @Test func shortcutsDisambiguateSameNamedTasksAndExcludeArchivedAncestors() async throws {
        let container = try WorkStore.makeContainer(inMemory: true)
        let hierarchy = WorkHierarchyActor(modelContainer: container)
        let firstOrg = try await hierarchy.saveOrganization(name: "Studio", colorHex: nil, sfSymbolName: nil)
        let secondOrg = try await hierarchy.saveOrganization(name: "Personal", colorHex: nil, sfSymbolName: nil)
        let client = try await hierarchy.saveClient(name: "Acme", organizationID: firstOrg, colorHex: nil, sfSymbolName: nil)
        let first = try await hierarchy.saveTask(name: "Planning", parent: .client(client), colorHex: nil,
                                                 sfSymbolName: nil, weekdays: [], storeLocation: false)
        let second = try await hierarchy.saveTask(name: "Planning", parent: .organization(secondOrg), colorHex: nil,
                                                  sfSymbolName: nil, weekdays: [], storeLocation: false)
        let query = ActivityQuery(activityActor: ActivityActor(modelContainer: container))
        let choices = try await query.suggestedEntities()
        #expect(Set(choices.map(\.id)) == [first, second])
        #expect(choices.first { $0.id == first }?.name == "Planning — Studio / Acme")
        #expect(choices.first { $0.id == second }?.name == "Planning — Personal")
        try await hierarchy.setArchived(kind: .organization, id: firstOrg, archived: true)
        #expect(try await query.entities(for: [first, second]).map(\.id) == [second])
        try await hierarchy.setArchived(kind: .organization, id: firstOrg, archived: false)
        #expect(Set(try await query.entities(for: [first, second]).map(\.id)) == [first, second])
    }

    @Test func shortcutsExcludeArchivedAndMalformedActivitiesAndRespectRequestedIDs() async throws {
        let schema = Schema([ActivityItem.self, ActivityLog.self])
        let container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
        let context = ModelContext(container)
        let active = ActivityItem(name: "Available")
        let archived = ActivityItem(name: "Archived", deleted: true)
        let missingID = ActivityItem(name: "Missing ID")
        missingID.id = nil
        let missingName = ActivityItem(name: "Missing name")
        missingName.name = nil
        for activity in [active, archived, missingID, missingName] { context.insert(activity) }
        try context.save()
        let id = try #require(active.id)
        let archivedID = try #require(archived.id)
        let query = ActivityQuery(activityActor: ActivityActor(modelContainer: container))

        let available = try await query.suggestedEntities()
        #expect(available.map(\.id) == [id])
        #expect(available.first?.name == "Available")
        #expect(try await query.entities(for: [id, archivedID, UUID()]).map(\.id) == [id])
        #expect(try await query.entities(for: [archivedID]).isEmpty)
        #expect(await query.defaultResult()?.id == id)
    }
}
