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
        let activities = await activityActor.getAllAvaibleActivitys()
        return activities
            .compactMap { activity in
                guard activity.archived != true, let id = activity.id,
                      let name = activity.name, identifiers.contains(id) else { return nil }
                return ActivityEntity(id: id, name: name)
            }
    }

    func suggestedEntities() async throws -> [ActivityEntity] {
        let activities = await activityActor.getAllAvaibleActivitys()
        return activities.compactMap { activity in
            guard activity.archived != true, let id = activity.id,
                  let name = activity.name else { return nil }
            return ActivityEntity(id: id, name: name)
        }
    }

    func defaultResult() async -> ActivityEntity? {
        try? await suggestedEntities().first
    }
}
