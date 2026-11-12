import Foundation

public nonisolated enum WorkReportEngine {
    public static func build(entries: [WorkReportEntry], query: WorkReportQuery) -> WorkReportResult {
        guard isFinite(query.startDate), isFinite(query.endDateExclusive),
              isFinite(query.capturedNow), query.endDateExclusive > query.startDate else {
            return emptyResult
        }

        let uniqueEntries = uniqueEntries(entries)
        var details: [WorkReportDetail] = []
        for entry in uniqueEntries where query.filters.includes(entry.workSnapshot) {
            guard let detail = clippedDetail(entry, query: query),
                  splitByDay(detail, calendar: query.calendar) != nil else { continue }
            details.append(detail)
        }
        details.sort {
            if $0.clippedStart != $1.clippedStart { return $0.clippedStart < $1.clippedStart }
            return $0.id.uuidString < $1.id.uuidString
        }
        // A later entry outside the selected organization or date range must
        // not relabel matching historical work with its new assignment.
        let metadata = canonicalMetadata(from: details.map(\.entry))

        let hasDayGrouping = query.groupings.contains(.day)
        let categoryGroupings = query.groupings.filter { $0 != .day }
        var rowAggregates: [WorkReportGroupKey: Aggregate] = [:]
        var seriesAggregates: [SeriesKey: TimeInterval] = [:]

        for detail in details {
            guard let dailySlices = splitByDay(detail, calendar: query.calendar) else { continue }
            let categoryKey = makeKey(
                groupings: categoryGroupings,
                snapshot: detail.entry.workSnapshot,
                metadata: metadata
            )

            if hasDayGrouping {
                for slice in dailySlices {
                    let key = makeKey(
                        groupings: query.groupings,
                        snapshot: detail.entry.workSnapshot,
                        metadata: metadata,
                        day: slice.date,
                        calendar: query.calendar
                    )
                    rowAggregates[key, default: Aggregate()].add(
                        duration: slice.duration,
                        entryID: detail.id,
                        sortDate: slice.date
                    )
                }
            } else {
                rowAggregates[categoryKey, default: Aggregate()].add(
                    duration: detail.durationSeconds,
                    entryID: detail.id,
                    sortDate: detail.clippedStart
                )
            }

            for slice in dailySlices {
                seriesAggregates[SeriesKey(key: categoryKey, date: slice.date), default: 0] += slice.duration
            }
        }

        let rawRows = rowAggregates.map { element in
            let key = element.key
            let aggregate = element.value
            return WorkReportRow(
                key: key,
                durationSeconds: aggregate.duration,
                entryCount: aggregate.entryIDs.count,
                sortDate: aggregate.sortDate
            )
        }
        let rows = disambiguate(rawRows).sorted { isOrderedBefore($0, $1, query: query) }

        let rawSeries = seriesAggregates.map { element in
            let key = element.key
            let duration = element.value
            return WorkReportSeriesPoint(key: key.key, date: key.date, durationSeconds: duration)
        }
        let series = disambiguate(rawSeries).sorted {
            if $0.date != $1.date { return $0.date < $1.date }
            if $0.displayName != $1.displayName {
                return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            return $0.key.id < $1.key.id
        }

        return WorkReportResult(
            groupings: query.groupings,
            startDate: query.startDate,
            endDateExclusive: query.endDateExclusive,
            capturedNow: query.capturedNow,
            rows: rows,
            series: series,
            details: details,
            totalDurationSeconds: details.reduce(0) { $0 + $1.durationSeconds },
            totalEntryCount: details.count
        )
    }

    public static func options(from entries: [WorkReportEntry]) -> WorkReportOptions {
        let unique = uniqueEntries(entries)
        let metadata = canonicalMetadata(from: unique)
        return WorkReportOptions(
            organizations: choices(metadata.organizations, grouping: .organization, metadata: metadata),
            clients: choices(metadata.clients, grouping: .client, metadata: metadata),
            projects: choices(metadata.projects, grouping: .project, metadata: metadata),
            tasks: choices(metadata.tasks, grouping: .task, metadata: metadata)
        )
    }

    private static var emptyResult: WorkReportResult {
        WorkReportResult(rows: [], series: [], details: [], totalDurationSeconds: 0, totalEntryCount: 0)
    }

    private static func uniqueEntries(_ entries: [WorkReportEntry]) -> [WorkReportEntry] {
        var seen = Set<UUID>()
        return entries.sorted(by: entryOrder).filter { seen.insert($0.id).inserted }
    }

    private static func entryOrder(_ lhs: WorkReportEntry, _ rhs: WorkReportEntry) -> Bool {
        if lhs.id != rhs.id { return lhs.id.uuidString < rhs.id.uuidString }
        let leftStart = sortTime(lhs.startTime)
        let rightStart = sortTime(rhs.startTime)
        if leftStart != rightStart { return leftStart < rightStart }
        let leftEnd = sortTime(lhs.endTime)
        let rightEnd = sortTime(rhs.endTime)
        if leftEnd != rightEnd { return leftEnd < rightEnd }
        return metadataFingerprint(lhs.workSnapshot) < metadataFingerprint(rhs.workSnapshot)
    }

    fileprivate static func sortTime(_ date: Date?) -> Double {
        guard let date else { return -.infinity }
        let value = date.timeIntervalSinceReferenceDate
        return value.isFinite ? value : -.infinity
    }

    private static func metadataFingerprint(_ snapshot: WorkSnapshot) -> String {
        [snapshot.organization, snapshot.client, snapshot.project, snapshot.task]
            .map { node in
                guard let node else { return "" }
                return "\(node.id?.uuidString ?? "")|\(node.name)|\(node.colorHex ?? "")|\(node.sfSymbolName ?? "")"
            }
            .joined(separator: "\u{1f}")
    }

    private static func canonicalMetadata(from entries: [WorkReportEntry]) -> CanonicalMetadata {
        var result = CanonicalMetadata()
        for entry in entries {
            result.keepLatest(entry.workSnapshot.organization, for: .organization, entry: entry)
            result.keepLatest(entry.workSnapshot.client, for: .client, entry: entry)
            result.keepLatest(entry.workSnapshot.project, for: .project, entry: entry)
            result.keepLatest(entry.workSnapshot.task, for: .task, entry: entry)
        }
        return result
    }

    private static func clippedDetail(_ entry: WorkReportEntry, query: WorkReportQuery) -> WorkReportDetail? {
        guard let start = entry.startTime, isFinite(start),
              query.filters.includes(entry.workSnapshot) else { return nil }
        let originalEnd = entry.endTime ?? query.capturedNow
        guard isFinite(originalEnd), originalEnd > start else { return nil }
        let clippedStart = max(start, query.startDate)
        let clippedEnd = min(originalEnd, query.endDateExclusive)
        guard clippedEnd > clippedStart,
              clippedEnd.timeIntervalSince(clippedStart).isFinite else { return nil }
        return WorkReportDetail(entry: entry, clippedStart: clippedStart, clippedEnd: clippedEnd)
    }

    private static func splitByDay(
        _ detail: WorkReportDetail,
        calendar: Calendar
    ) -> [DaySlice]? {
        var slices: [DaySlice] = []
        var sliceStart = detail.clippedStart
        while sliceStart < detail.clippedEnd {
            let dayStart = calendar.startOfDay(for: sliceStart)
            guard isFinite(dayStart), dayStart <= sliceStart,
                  let nextDayStart = calendar.date(byAdding: .day, value: 1, to: dayStart),
                  isFinite(nextDayStart), nextDayStart > sliceStart else { return nil }
            let sliceEnd = min(detail.clippedEnd, nextDayStart)
            let duration = sliceEnd.timeIntervalSince(sliceStart)
            guard duration.isFinite, duration > 0 else { return nil }
            slices.append(DaySlice(date: dayStart, duration: duration))
            sliceStart = sliceEnd
        }
        return slices.isEmpty ? nil : slices
    }

    private static func makeKey(
        groupings: [WorkReportGrouping],
        snapshot: WorkSnapshot,
        metadata: CanonicalMetadata,
        day: Date? = nil,
        calendar: Calendar = .current
    ) -> WorkReportGroupKey {
        let components = groupings.map { grouping -> WorkReportGroupComponent in
            if grouping == .day {
                guard let day else {
                    return WorkReportGroupComponent(grouping: grouping, value: .unassigned)
                }
                return WorkReportGroupComponent(
                    grouping: grouping,
                    value: .day(day, label: dayLabel(day, calendar: calendar))
                )
            }

            let node = metadata.node(for: grouping, snapshot: snapshot)
            let value: WorkReportGroupValue
            if let node, let entity = WorkReportEntityValue(
                node,
                contextualName: node.id.flatMap { metadata.contextualName(for: grouping, id: $0) }
            ) {
                value = .entity(entity)
            } else {
                value = .unassigned
            }
            return WorkReportGroupComponent(grouping: grouping, value: value)
        }
        return WorkReportGroupKey(components: components)
    }

    private static func dayLabel(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale ?? .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static func choices(
        _ values: [UUID: WorkNodeSnapshot],
        grouping: WorkReportGrouping,
        metadata: CanonicalMetadata
    ) -> [WorkReportChoice] {
        values.compactMap { id, snapshot in
            guard let snapshotID = snapshot.id else { return nil }
            return WorkReportChoice(
                id: snapshotID,
                name: metadata.contextualName(for: grouping, id: id) ?? snapshot.name,
                colorHex: snapshot.colorHex,
                sfSymbolName: snapshot.sfSymbolName
            )
        }.sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            if order != .orderedSame { return order == .orderedAscending }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    private static func isOrderedBefore(
        _ lhs: WorkReportRow,
        _ rhs: WorkReportRow,
        query: WorkReportQuery
    ) -> Bool {
        for sort in query.sorting {
            let order: ComparisonResult
            switch sort.field {
            case .metric:
                let left = query.metric == .duration ? lhs.durationSeconds : Double(lhs.entryCount)
                let right = query.metric == .duration ? rhs.durationSeconds : Double(rhs.entryCount)
                order = left == right ? .orderedSame : (left < right ? .orderedAscending : .orderedDescending)
            case .name:
                order = lhs.displayName.localizedStandardCompare(rhs.displayName)
            case .date:
                let left = lhs.sortDate ?? .distantPast
                let right = rhs.sortDate ?? .distantPast
                order = left == right ? .orderedSame : (left < right ? .orderedAscending : .orderedDescending)
            }
            if order != .orderedSame {
                return sort.direction == .ascending
                    ? order == .orderedAscending
                    : order == .orderedDescending
            }
        }
        return lhs.key.id < rhs.key.id
    }

    private static func disambiguate(_ rows: [WorkReportRow]) -> [WorkReportRow] {
        let counts = Dictionary(grouping: rows, by: \.displayName).mapValues(\.count)
        return rows.map { row in
            guard counts[row.displayName, default: 0] > 1 else { return row }
            return WorkReportRow(
                key: row.key,
                durationSeconds: row.durationSeconds,
                entryCount: row.entryCount,
                sortDate: row.sortDate,
                presentationName: "\(row.displayName) · \(row.key.id)"
            )
        }
    }

    private static func disambiguate(_ series: [WorkReportSeriesPoint]) -> [WorkReportSeriesPoint] {
        var keysByID: [String: WorkReportGroupKey] = [:]
        for point in series { keysByID[point.key.id] = point.key }
        let uniqueKeys = Array(keysByID.values)
        let counts = Dictionary(grouping: uniqueKeys, by: \.displayName).mapValues(\.count)
        let ambiguousKeyIDs = Set(uniqueKeys.compactMap { key in
            counts[key.displayName, default: 0] > 1 ? key.id : nil
        })
        return series.map { point in
            guard ambiguousKeyIDs.contains(point.key.id) else { return point }
            return WorkReportSeriesPoint(
                key: point.key,
                date: point.date,
                durationSeconds: point.durationSeconds,
                presentationName: "\(point.displayName) · \(point.key.id)"
            )
        }
    }

    private static func isFinite(_ date: Date) -> Bool {
        date.timeIntervalSinceReferenceDate.isFinite
    }
}

private nonisolated struct DaySlice {
    let date: Date
    let duration: TimeInterval
}

private nonisolated struct SeriesKey: Hashable {
    let key: WorkReportGroupKey
    let date: Date
}

private nonisolated struct Aggregate {
    var duration: TimeInterval = 0
    var entryIDs: Set<UUID> = []
    var sortDate: Date?

    mutating func add(duration: TimeInterval, entryID: UUID, sortDate: Date) {
        self.duration += duration
        entryIDs.insert(entryID)
        if self.sortDate == nil || sortDate < self.sortDate! { self.sortDate = sortDate }
    }
}

private nonisolated struct CanonicalMetadata {
    var organizations: [UUID: WorkNodeSnapshot] = [:]
    var clients: [UUID: WorkNodeSnapshot] = [:]
    var projects: [UUID: WorkNodeSnapshot] = [:]
    var tasks: [UUID: WorkNodeSnapshot] = [:]
    private var timestamps: [WorkReportGrouping: [UUID: (Double, String)]] = [:]
    private var contexts: [WorkReportGrouping: [UUID: WorkSnapshot]] = [:]

    mutating func keepLatest(_ node: WorkNodeSnapshot?, for grouping: WorkReportGrouping, entry: WorkReportEntry) {
        guard let node, let id = node.id else { return }
        let start = WorkReportEngine.sortTime(entry.startTime)
        let tieBreaker = entry.id.uuidString
        let candidate = (start, tieBreaker)
        let existing = timestamps[grouping]?[id]
        guard existing == nil || candidate.0 > existing!.0
                || (candidate.0 == existing!.0 && candidate.1 > existing!.1) else { return }
        timestamps[grouping, default: [:]][id] = candidate
        switch grouping {
        case .organization: organizations[id] = node
        case .client: clients[id] = node
        case .project: projects[id] = node
        case .task: tasks[id] = node
        case .day: break
        }
        contexts[grouping, default: [:]][id] = entry.workSnapshot
    }

    func node(for grouping: WorkReportGrouping, snapshot: WorkSnapshot) -> WorkNodeSnapshot? {
        let source: WorkNodeSnapshot?
        let values: [UUID: WorkNodeSnapshot]
        switch grouping {
        case .organization: source = snapshot.organization; values = organizations
        case .client: source = snapshot.client; values = clients
        case .project: source = snapshot.project; values = projects
        case .task: source = snapshot.task; values = tasks
        case .day: return nil
        }
        guard let id = source?.id else { return nil }
        return values[id] ?? source
    }

    func contextualName(for grouping: WorkReportGrouping, id: UUID) -> String? {
        let node: WorkNodeSnapshot?
        switch grouping {
        case .organization: node = organizations[id]
        case .client: node = clients[id]
        case .project: node = projects[id]
        case .task: node = tasks[id]
        case .day: return nil
        }
        guard let node else { return nil }
        let context = contexts[grouping]?[id]
        let parentNames: [String]
        switch grouping {
        case .organization:
            parentNames = []
        case .client:
            parentNames = [context?.organization?.name].compactMap { $0 }
        case .project:
            parentNames = [context?.organization?.name, context?.client?.name].compactMap { $0 }
        case .task:
            parentNames = [context?.organization?.name, context?.client?.name, context?.project?.name]
                .compactMap { $0 }
        case .day:
            parentNames = []
        }
        if !parentNames.isEmpty { return "\(node.name) — \(parentNames.joined(separator: " / "))" }
        return grouping == .organization ? node.name : "\(node.name) — Unassigned"
    }
}
