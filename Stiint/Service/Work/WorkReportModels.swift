import Foundation

/// A value copy of one log at the report boundary. The relationship graph is never
/// sent out of SwiftData's model actor.
nonisolated public struct WorkReportEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let startTime: Date?
    public let endTime: Date?
    public let workSnapshot: WorkSnapshot
    public let startLatitude: Double?
    public let startLongitude: Double?
    public let endLatitude: Double?
    public let endLongitude: Double?

    public init(
        id: UUID,
        startTime: Date?,
        endTime: Date?,
        workSnapshot: WorkSnapshot,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        endLatitude: Double? = nil,
        endLongitude: Double? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.workSnapshot = workSnapshot
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
    }
}

nonisolated public enum WorkReportSelection<ID: Hashable & Sendable>: Equatable, Sendable {
    case any
    case unassigned
    case selected(Set<ID>)

    public func includes(_ value: ID?) -> Bool {
        switch self {
        case .any:
            true
        case .unassigned:
            value == nil
        case .selected(let identifiers):
            value.map(identifiers.contains) ?? false
        }
    }

    public static func organizationScope(_ rawValue: String) -> Self where ID == UUID {
        if rawValue == "unassigned" { return .unassigned }
        if rawValue == "all" { return .any }
        if let id = UUID(uuidString: rawValue) { return .selected([id]) }
        return .any
    }
}

nonisolated public struct WorkReportFilters: Equatable, Sendable {
    public var organizations: WorkReportSelection<UUID>
    public var clients: WorkReportSelection<UUID>
    public var projects: WorkReportSelection<UUID>
    public var tasks: WorkReportSelection<UUID>

    public init(
        organizations: WorkReportSelection<UUID> = .any,
        clients: WorkReportSelection<UUID> = .any,
        projects: WorkReportSelection<UUID> = .any,
        tasks: WorkReportSelection<UUID> = .any
    ) {
        self.organizations = organizations
        self.clients = clients
        self.projects = projects
        self.tasks = tasks
    }

    public func includes(_ snapshot: WorkSnapshot) -> Bool {
        organizations.includes(snapshot.organization?.id)
            && clients.includes(snapshot.client?.id)
            && projects.includes(snapshot.project?.id)
            && tasks.includes(snapshot.task?.id)
    }
}

nonisolated public enum WorkReportGrouping: String, CaseIterable, Identifiable, Hashable, Sendable {
    case organization
    case client
    case project
    case task
    case day

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .organization: "Organization"
        case .client: "Client"
        case .project: "Project"
        case .task: "Task"
        case .day: "Day"
        }
    }
}

nonisolated public enum WorkReportMetric: String, CaseIterable, Identifiable, Hashable, Sendable {
    case duration
    case entries

    public var id: String { rawValue }
    public var title: String { self == .duration ? "Time spent" : "Entries" }
}

nonisolated public enum WorkReportSortField: String, CaseIterable, Identifiable, Hashable, Sendable {
    case metric
    case name
    case date

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .metric: "Metric"
        case .name: "Name"
        case .date: "Date"
        }
    }
}

nonisolated public enum WorkReportSortDirection: Equatable, Sendable {
    case ascending
    case descending
}

nonisolated public struct WorkReportSort: Sendable {
    public let field: WorkReportSortField
    public let direction: WorkReportSortDirection

    public init(field: WorkReportSortField, direction: WorkReportSortDirection = .descending) {
        self.field = field
        self.direction = direction
    }
}

nonisolated public struct WorkReportQuery {
    public let startDate: Date
    public let endDateExclusive: Date
    public let capturedNow: Date
    public let calendar: Calendar
    public let filters: WorkReportFilters
    public let groupings: [WorkReportGrouping]
    public let metric: WorkReportMetric
    public let sorting: [WorkReportSort]

    public init(
        startDate: Date,
        endDateExclusive: Date,
        capturedNow: Date,
        calendar: Calendar = .current,
        filters: WorkReportFilters = WorkReportFilters(),
        groupings: [WorkReportGrouping] = [.task],
        metric: WorkReportMetric = .duration,
        sorting: [WorkReportSort] = [WorkReportSort(field: .metric)]
    ) {
        self.startDate = startDate
        self.endDateExclusive = endDateExclusive
        self.capturedNow = capturedNow
        self.calendar = calendar
        var seen = Set<WorkReportGrouping>()
        self.groupings = groupings.filter { seen.insert($0).inserted }
        self.filters = filters
        self.metric = metric
        self.sorting = sorting
    }
}

nonisolated public struct WorkReportEntityValue: Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let contextualName: String?
    public let colorHex: String?
    public let sfSymbolName: String?

    public init?(_ snapshot: WorkNodeSnapshot, contextualName: String? = nil) {
        guard let id = snapshot.id else { return nil }
        self.id = id
        name = snapshot.name
        self.contextualName = contextualName
        colorHex = snapshot.colorHex
        sfSymbolName = snapshot.sfSymbolName
    }

    public init(
        id: UUID,
        name: String,
        contextualName: String? = nil,
        colorHex: String? = nil,
        sfSymbolName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.contextualName = contextualName
        self.colorHex = colorHex
        self.sfSymbolName = sfSymbolName
    }
}

nonisolated public enum WorkReportGroupValue: Hashable, Sendable {
    case entity(WorkReportEntityValue)
    case unassigned
    case day(Date, label: String)

    public var displayName: String {
        switch self {
        case .entity(let value): return value.name
        case .unassigned: return "Unassigned"
        case .day(_, let label): return label
        }
    }

    fileprivate var stableID: String {
        switch self {
        case .entity(let value): "entity-\(value.id.uuidString)"
        case .unassigned: "unassigned"
        case .day(let date, _): "day-\(date.timeIntervalSinceReferenceDate.bitPattern)"
        }
    }
}

nonisolated public struct WorkReportGroupComponent: Hashable, Sendable {
    public let grouping: WorkReportGrouping
    public let value: WorkReportGroupValue

    public init(grouping: WorkReportGrouping, value: WorkReportGroupValue) {
        self.grouping = grouping
        self.value = value
    }
}

nonisolated public struct WorkReportGroupKey: Hashable, Identifiable, Sendable {
    public let components: [WorkReportGroupComponent]

    public init(components: [WorkReportGroupComponent]) {
        self.components = components
    }

    public var id: String {
        guard !components.isEmpty else { return "all-work" }
        return components.map {
            "\($0.grouping.rawValue):\($0.value.stableID)"
        }.joined(separator: "|")
    }

    public var displayName: String {
        guard !components.isEmpty else { return "All matching work" }
        let groupings = Set(components.map(\.grouping))
        return components.map { component in
            guard case .entity(let entity) = component.value else { return component.value.displayName }
            let needsContext: Bool
            switch component.grouping {
            case .organization:
                needsContext = false
            case .client:
                needsContext = !groupings.contains(.organization)
            case .project:
                needsContext = !groupings.contains(.organization) && !groupings.contains(.client)
            case .task:
                needsContext = !groupings.contains(.organization)
                    && !groupings.contains(.client) && !groupings.contains(.project)
            case .day:
                needsContext = false
            }
            return needsContext ? (entity.contextualName ?? entity.name) : entity.name
        }.joined(separator: " / ")
    }
}

nonisolated public struct WorkReportRow: Identifiable, Equatable, Sendable {
    public let key: WorkReportGroupKey
    public let durationSeconds: TimeInterval
    public let entryCount: Int
    public let sortDate: Date?
    public let presentationName: String?

    public var id: String { key.id }
    public var displayName: String { presentationName ?? key.displayName }

    public init(
        key: WorkReportGroupKey,
        durationSeconds: TimeInterval,
        entryCount: Int,
        sortDate: Date?,
        presentationName: String? = nil
    ) {
        self.key = key
        self.durationSeconds = durationSeconds
        self.entryCount = entryCount
        self.sortDate = sortDate
        self.presentationName = presentationName
    }
}

nonisolated public struct WorkReportSeriesPoint: Identifiable, Equatable, Sendable {
    public let key: WorkReportGroupKey
    public let date: Date
    public let durationSeconds: TimeInterval
    public let presentationName: String?

    public var id: String { "\(key.id)|\(date.timeIntervalSinceReferenceDate.bitPattern)" }
    public var displayName: String { presentationName ?? key.displayName }

    public init(key: WorkReportGroupKey, date: Date, durationSeconds: TimeInterval, presentationName: String? = nil) {
        self.key = key
        self.date = date
        self.durationSeconds = durationSeconds
        self.presentationName = presentationName
    }
}

nonisolated public struct WorkReportDetail: Identifiable, Equatable, Sendable {
    public let entry: WorkReportEntry
    public let clippedStart: Date
    public let clippedEnd: Date

    public var id: UUID { entry.id }
    public var durationSeconds: TimeInterval { clippedEnd.timeIntervalSince(clippedStart) }

    public init(entry: WorkReportEntry, clippedStart: Date, clippedEnd: Date) {
        self.entry = entry
        self.clippedStart = clippedStart
        self.clippedEnd = clippedEnd
    }
}

nonisolated public struct WorkReportResult: Equatable, Sendable {
    public let groupings: [WorkReportGrouping]
    public let startDate: Date
    public let endDateExclusive: Date
    public let capturedNow: Date
    public let rows: [WorkReportRow]
    public let series: [WorkReportSeriesPoint]
    public let details: [WorkReportDetail]
    public let totalDurationSeconds: TimeInterval
    public let totalEntryCount: Int

    public init(
        groupings: [WorkReportGrouping] = [],
        startDate: Date = .distantPast,
        endDateExclusive: Date = .distantFuture,
        capturedNow: Date = .distantPast,
        rows: [WorkReportRow],
        series: [WorkReportSeriesPoint],
        details: [WorkReportDetail],
        totalDurationSeconds: TimeInterval,
        totalEntryCount: Int
    ) {
        self.groupings = groupings
        self.startDate = startDate
        self.endDateExclusive = endDateExclusive
        self.capturedNow = capturedNow
        self.rows = rows
        self.series = series
        self.details = details
        self.totalDurationSeconds = totalDurationSeconds
        self.totalEntryCount = totalEntryCount
    }
}

nonisolated public struct WorkReportChoice: Hashable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let colorHex: String?
    public let sfSymbolName: String?

    public init(id: UUID, name: String, colorHex: String? = nil, sfSymbolName: String? = nil) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sfSymbolName = sfSymbolName
    }
}

nonisolated public struct WorkReportOptions: Equatable, Sendable {
    public let organizations: [WorkReportChoice]
    public let clients: [WorkReportChoice]
    public let projects: [WorkReportChoice]
    public let tasks: [WorkReportChoice]

    public init(
        organizations: [WorkReportChoice] = [],
        clients: [WorkReportChoice] = [],
        projects: [WorkReportChoice] = [],
        tasks: [WorkReportChoice] = []
    ) {
        self.organizations = organizations
        self.clients = clients
        self.projects = projects
        self.tasks = tasks
    }
}
