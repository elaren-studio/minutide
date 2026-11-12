//
//  persistenceManager.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//

import Foundation
import SwiftData

public final class PersistenceManager: Sendable {
    public let modelContainer: ModelContainer
    public let activityActor: ActivityActor
    public let activityLogActor: ActivityLogActor
    public let workHierarchyActor: WorkHierarchyActor

    init() {
        modelContainer = {
            do {
                return try WorkStore.makeContainer()
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()

        activityActor = ActivityActor(modelContainer: modelContainer)
        activityLogActor = ActivityLogActor(modelContainer: modelContainer)
        workHierarchyActor = WorkHierarchyActor(modelContainer: modelContainer)
    }
}

public extension PersistenceManager {
    static let shared = PersistenceManager()
}
