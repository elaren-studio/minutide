import AppIntents
import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct ActivityQueryTests {
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
