import Foundation
import SwiftData
import SwiftUI

public nonisolated enum WorkParent: Hashable, Sendable, Codable {
    case organization(UUID), client(UUID), project(UUID)

    public var id: UUID {
        switch self {
        case .organization(let id), .client(let id), .project(let id): id
        }
    }

    public var kind: WorkEntityKind {
        switch self {
        case .organization: .organization
        case .client: .client
        case .project: .project
        }
    }
}

public nonisolated enum WorkEntityKind: String, CaseIterable, Codable, Sendable {
    case organization, client, project, task
}

public nonisolated struct WorkNodeSnapshot: Codable, Equatable, Sendable {
    public var id: UUID?
    public var name: String
    public var colorHex: String?
    public var sfSymbolName: String?

    public init(id: UUID?, name: String, colorHex: String? = nil, sfSymbolName: String? = nil) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sfSymbolName = sfSymbolName
    }
}

public nonisolated struct WorkSnapshot: Codable, Equatable, Sendable {
    public var task: WorkNodeSnapshot?
    public var organization: WorkNodeSnapshot?
    public var client: WorkNodeSnapshot?
    public var project: WorkNodeSnapshot?

    public init(task: WorkNodeSnapshot? = nil, organization: WorkNodeSnapshot? = nil,
                client: WorkNodeSnapshot? = nil, project: WorkNodeSnapshot? = nil) {
        self.task = task
        self.organization = organization
        self.client = client
        self.project = project
    }
}

public nonisolated enum WorkHierarchyError: LocalizedError, Equatable {
    case emptyName, duplicateName, missingEntity, invalidParent, archivedParent, invalidColor

    public var errorDescription: String? {
        switch self {
        case .emptyName: "Enter a name."
        case .duplicateName: "That name is already used in this location."
        case .missingEntity: "This item is unavailable. Close and reopen the editor."
        case .invalidParent: "Choose a valid location for this item."
        case .archivedParent: "Restore this item and its archived parents before using it."
        case .invalidColor: "Choose a valid color."
        }
    }
}

/// Reads a single context's graph. No cached ancestry is stored on tasks.
public enum WorkHierarchy {
    public nonisolated static let defaultColorHex = "#32ADE6"
    public nonisolated static let defaultSymbolName = "book.fill"

    public nonisolated static func resolve(task: ActivityItem, in context: ModelContext,
                               requireAvailable: Bool = false) throws -> WorkSnapshot {
        guard (task.workParentKindRaw == nil) == (task.workParentID == nil),
              task.workParentKindRaw == nil || task.workParent != nil else {
            throw WorkHierarchyError.invalidParent
        }
        if requireAvailable {
            guard task.id != nil,
                  let name = task.name,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw WorkHierarchyError.missingEntity
            }
            if task.archived == true { throw WorkHierarchyError.archivedParent }
        }
        var result = try resolve(parent: task.workParent, in: context, requireAvailable: requireAvailable)
        let inherited = result.project ?? result.client ?? result.organization
        result.task = node(id: task.id, name: task.name ?? "Unknown task", color: task.colorHex,
                           symbol: task.sfSymbolName, inherited: inherited)
        return result
    }

    public nonisolated static func resolve(parent: WorkParent?, in context: ModelContext,
                               requireAvailable: Bool = false) throws -> WorkSnapshot {
        var organization: WorkOrganization?
        var client: WorkClient?
        var project: WorkProject?
        switch parent {
        case .organization(let id):
            organization = try self.organization(id: id, in: context)
        case .client(let id):
            client = try self.client(id: id, in: context)
        case .project(let id):
            project = try self.project(id: id, in: context)
            guard let clientID = project?.clientID else { throw WorkHierarchyError.invalidParent }
            client = try self.client(id: clientID, in: context)
        case nil: break
        }
        if let client {
            guard let organizationID = client.organizationID else { throw WorkHierarchyError.invalidParent }
            organization = try self.organization(id: organizationID, in: context)
        }
        if requireAvailable,
           organization?.archived == true || client?.archived == true || project?.archived == true {
            throw WorkHierarchyError.archivedParent
        }
        var result = WorkSnapshot()
        if let organization {
            result.organization = node(id: organization.id, name: organization.name,
                                       color: organization.colorHex, symbol: organization.sfSymbolName)
        }
        if let client {
            result.client = node(id: client.id, name: client.name, color: client.colorHex,
                                 symbol: client.sfSymbolName, inherited: result.organization)
        }
        if let project {
            result.project = node(id: project.id, name: project.name, color: project.colorHex,
                                  symbol: project.sfSymbolName, inherited: result.client)
        }
        return result
    }

    public nonisolated static func isAvailable(task: ActivityItem, in context: ModelContext) -> Bool {
        (try? resolve(task: task, in: context, requireAvailable: true)) != nil
    }

    /// Legacy entries predate hierarchy. Never infer their ancestors from a later task assignment.
    public nonisolated static func legacySnapshot(task: ActivityItem?) -> WorkSnapshot {
        guard let task else { return WorkSnapshot() }
        return WorkSnapshot(task: WorkNodeSnapshot(id: task.id, name: task.name ?? "Unknown task",
            colorHex: task.colorHex ?? task.color.toHex(),
            sfSymbolName: task.sfSymbolName ?? "questionmark.circle.fill"))
    }

    nonisolated static func node(id: UUID?, name: String, color: String?, symbol: String?,
                     inherited: WorkNodeSnapshot? = nil) -> WorkNodeSnapshot {
        WorkNodeSnapshot(id: id, name: name,
                         colorHex: color ?? inherited?.colorHex ?? defaultColorHex,
                         sfSymbolName: symbol ?? inherited?.sfSymbolName ?? defaultSymbolName)
    }

    nonisolated static func organization(id: UUID, in context: ModelContext) throws -> WorkOrganization {
        guard let value = try context.fetch(FetchDescriptor<WorkOrganization>(
            predicate: #Predicate { $0.id == id })).first else { throw WorkHierarchyError.missingEntity }
        return value
    }

    nonisolated static func client(id: UUID, in context: ModelContext) throws -> WorkClient {
        guard let value = try context.fetch(FetchDescriptor<WorkClient>(
            predicate: #Predicate { $0.id == id })).first else { throw WorkHierarchyError.missingEntity }
        return value
    }

    nonisolated static func project(id: UUID, in context: ModelContext) throws -> WorkProject {
        guard let value = try context.fetch(FetchDescriptor<WorkProject>(
            predicate: #Predicate { $0.id == id })).first else { throw WorkHierarchyError.missingEntity }
        return value
    }

    nonisolated static func task(id: UUID, in context: ModelContext) throws -> ActivityItem {
        guard let value = try context.fetch(FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == id })).first else { throw WorkHierarchyError.missingEntity }
        return value
    }
}
