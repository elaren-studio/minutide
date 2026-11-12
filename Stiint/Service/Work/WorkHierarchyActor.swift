import Foundation
import SwiftData

@ModelActor
public actor WorkHierarchyActor {
    @discardableResult
    public func saveOrganization(id: UUID? = nil, name: String, colorHex: String? = nil,
                                 sfSymbolName: String? = nil) throws -> UUID {
        try transaction { context in
            let name = try WorkMutations.name(name)
            let values = try context.fetch(FetchDescriptor<WorkOrganization>())
            try WorkMutations.checkDuplicate(values.contains {
                $0.id != id && WorkMutations.sameName($0.name, name)
            })
            let value: WorkOrganization
            if let id { value = try WorkHierarchy.organization(id: id, in: context) }
            else { value = WorkOrganization(name: name); context.insert(value) }
            value.name = name
            value.colorHex = try WorkMutations.color(colorHex)
            value.sfSymbolName = WorkMutations.symbol(sfSymbolName)
            return value.id
        }
    }

    @discardableResult
    public func saveClient(id: UUID? = nil, name: String, organizationID: UUID,
                           colorHex: String? = nil, sfSymbolName: String? = nil) throws -> UUID {
        try transaction { context in
            _ = try WorkHierarchy.resolve(parent: .organization(organizationID), in: context, requireAvailable: true)
            let name = try WorkMutations.name(name)
            let values = try context.fetch(FetchDescriptor<WorkClient>())
            try WorkMutations.checkDuplicate(values.contains {
                $0.id != id && $0.organizationID == organizationID && WorkMutations.sameName($0.name, name)
            })
            let value: WorkClient
            if let id { value = try WorkHierarchy.client(id: id, in: context) }
            else { value = WorkClient(name: name, organizationID: organizationID); context.insert(value) }
            value.name = name
            value.organizationID = organizationID
            value.colorHex = try WorkMutations.color(colorHex)
            value.sfSymbolName = WorkMutations.symbol(sfSymbolName)
            return value.id
        }
    }

    @discardableResult
    public func saveProject(id: UUID? = nil, name: String, clientID: UUID,
                            colorHex: String? = nil, sfSymbolName: String? = nil) throws -> UUID {
        try transaction { context in
            _ = try WorkHierarchy.resolve(parent: .client(clientID), in: context, requireAvailable: true)
            let name = try WorkMutations.name(name)
            let values = try context.fetch(FetchDescriptor<WorkProject>())
            try WorkMutations.checkDuplicate(values.contains {
                $0.id != id && $0.clientID == clientID && WorkMutations.sameName($0.name, name)
            })
            let value: WorkProject
            if let id { value = try WorkHierarchy.project(id: id, in: context) }
            else { value = WorkProject(name: name, clientID: clientID); context.insert(value) }
            value.name = name
            value.clientID = clientID
            value.colorHex = try WorkMutations.color(colorHex)
            value.sfSymbolName = WorkMutations.symbol(sfSymbolName)
            return value.id
        }
    }

    @discardableResult
    public func saveTask(id: UUID? = nil, name: String, parent: WorkParent?, colorHex: String? = nil,
                         sfSymbolName: String? = nil, weekdays: Set<Weekday> = [],
                         storeLocation: Bool = false) throws -> UUID {
        try transaction { context in
            try WorkMutations.saveTask(in: context, id: id, name: name, parent: parent,
                colorHex: colorHex, sfSymbolName: sfSymbolName, weekdays: weekdays, storeLocation: storeLocation)
        }
    }

    public func setArchived(kind: WorkEntityKind, id: UUID, archived: Bool) throws {
        try transaction { context in
            switch kind {
            case .organization:
                let value = try WorkHierarchy.organization(id: id, in: context)
                value.archived = archived
            case .client:
                let value = try WorkHierarchy.client(id: id, in: context)
                value.archived = archived
            case .project:
                let value = try WorkHierarchy.project(id: id, in: context)
                value.archived = archived
            case .task:
                let value = try WorkHierarchy.task(id: id, in: context)
                value.archived = archived
            }
        }
    }

    public func resolveTask(taskID: UUID) throws -> WorkSnapshot {
        let context = ModelContext(modelContainer)
        return try WorkHierarchy.resolve(task: WorkHierarchy.task(id: taskID, in: context), in: context)
    }

    private func transaction<Value>(_ body: (ModelContext) throws -> Value) throws -> Value {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        do {
            let result = try body(context)
            try context.save()
            return result
        } catch {
            context.rollback()
            throw error
        }
    }
}

/// Shared validation for the hierarchy actor and legacy ActivityActor entry points.
enum WorkMutations {
    nonisolated static func name(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WorkHierarchyError.emptyName }
        return trimmed
    }

    nonisolated static func sameName(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines).compare(rhs, options: .caseInsensitive) == .orderedSame
    }

    nonisolated static func checkDuplicate(_ duplicate: Bool) throws {
        if duplicate { throw WorkHierarchyError.duplicateName }
    }

    nonisolated static func color(_ value: String?) throws -> String? {
        guard let value = symbol(value) else { return nil }
        let normalized = value.hasPrefix("#") ? String(value.dropFirst()) : value
        guard normalized.count == 6, normalized.allSatisfy({ $0.isHexDigit }) else {
            throw WorkHierarchyError.invalidColor
        }
        return "#" + normalized.uppercased()
    }

    nonisolated static func symbol(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    nonisolated static func saveTask(in context: ModelContext, id: UUID?, name: String, parent: WorkParent?,
                         colorHex: String?, sfSymbolName: String?, weekdays: Set<Weekday>,
                         storeLocation: Bool) throws -> UUID {
        _ = try WorkHierarchy.resolve(parent: parent, in: context, requireAvailable: true)
        let name = try self.name(name)
        let values = try context.fetch(FetchDescriptor<ActivityItem>())
        try checkDuplicate(values.contains {
            $0.id != id && $0.workParent == parent && sameName($0.name ?? "", name)
        })
        let value: ActivityItem
        if let id { value = try WorkHierarchy.task(id: id, in: context) }
        else { value = ActivityItem(name: name); context.insert(value) }
        value.name = name
        value.workParent = parent
        value.colorHex = try color(colorHex)
        value.sfSymbolName = symbol(sfSymbolName)
        value.weekdays = weekdays
        value.storeLocation = storeLocation
        guard let valueID = value.id else { throw WorkHierarchyError.missingEntity }
        return valueID
    }
}
