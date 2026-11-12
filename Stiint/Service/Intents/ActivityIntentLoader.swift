//
//  ActivityIntentLoader.swift
//  Stiint
//
//  Created by Wittig, Liam on 20.12.25.
//

import AppIntents
import Foundation

// Dynamic Entity that loads from PersistenceManager
struct ActivityEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Activity"
    }

    var id: UUID
    var name: String
    var startDate: Date?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = ActivityQuery()
}

// Query to provide dynamic entities
struct ActivityQuery: EntityQuery {
    private let activityActor: ActivityActor

    init() {
        activityActor = PersistenceManager.shared.activityActor
    }

    init(activityActor: ActivityActor) {
        self.activityActor = activityActor
    }

    func entities(for identifiers: [UUID]) async throws -> [ActivityEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ActivityEntity] {
        let snapshots = try await activityActor.getStartableActivitySnapshots()
        return snapshots.compactMap { snapshot in
            guard let task = snapshot.task, let id = task.id else { return nil }
            let location = [snapshot.organization?.name, snapshot.client?.name, snapshot.project?.name]
                .compactMap { $0 }.joined(separator: " / ")
            let name = location.isEmpty ? task.name : "\(task.name) — \(location)"
            return ActivityEntity(id: id, name: name)
        }
    }

    func defaultResult() async -> ActivityEntity? {
        try? await suggestedEntities().first
    }
}
