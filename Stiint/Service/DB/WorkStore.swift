import Foundation
import SwiftData

/// Frozen build 1 schema. Do not change these stored properties when evolving the current models.
public enum MinutideSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    public static var models: [any PersistentModel.Type] { [ActivityItem.self, ActivityLog.self] }

    @Model
    public final class ActivityItem {
        public var id: UUID?
        public var createdDate: Date?
        public var name: String?
        public var colorHex: String?
        public var sfSymbolName: String?
        @Attribute(originalName: "deleted") public var archived: Bool?
        public var weekdays: Set<Weekday>?
        public var storeLocation: Bool?

        public init(id: UUID? = UUID(), name: String? = nil, archived: Bool? = nil) {
            self.id = id
            self.createdDate = .now
            self.name = name
            self.archived = archived
            self.weekdays = []
        }
    }

    @Model
    public final class ActivityLog {
        public var id: UUID?
        public var startTime: Date?
        public var endTime: Date?
        public var activity: ActivityItem?
        public var previousActivityLogId: UUID?
        public var startLatitude: Double?
        public var startLongitude: Double?
        public var endLatitude: Double?
        public var endLongitude: Double?

        public init(id: UUID? = UUID(), startTime: Date? = nil, endTime: Date? = nil,
                    activity: ActivityItem? = nil) {
            self.id = id
            self.startTime = startTime
            self.endTime = endTime
            self.activity = activity
        }
    }
}

public enum MinutideSchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [ActivityItem.self, ActivityLog.self, WorkOrganization.self, WorkClient.self, WorkProject.self]
    }
}

public enum MinutideMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [MinutideSchemaV1.self, MinutideSchemaV2.self] }
    public static var stages: [MigrationStage] {
        [.lightweight(fromVersion: MinutideSchemaV1.self, toVersion: MinutideSchemaV2.self)]
    }
}

public enum WorkStore {
    public static func makeContainer(url: URL? = nil, inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: MinutideSchemaV2.self)
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            // Keep the previously shipped default on-disk location unchanged.
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory,
                                               cloudKitDatabase: .none)
        }
        let container = try ModelContainer(for: schema, migrationPlan: MinutideMigrationPlan.self,
                                           configurations: [configuration])
        try bootstrapLegacySnapshots(in: container)
        return container
    }

    public static func bootstrapLegacySnapshots(in container: ModelContainer) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        do {
            let logs = try context.fetch(FetchDescriptor<ActivityLog>(
                predicate: #Predicate { $0.hierarchySnapshotVersion == nil }))
            for log in logs { log.workSnapshot = WorkHierarchy.legacySnapshot(task: log.activity) }
            if context.hasChanges { try context.save() }
        } catch {
            context.rollback()
            throw error
        }
    }
}
