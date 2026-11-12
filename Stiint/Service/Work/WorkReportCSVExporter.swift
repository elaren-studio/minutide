import Foundation

public nonisolated enum WorkReportCSVExporter {
    private static let legacyDetailHeaders = [
        "Activity", "Start Date", "End Date", "Duration",
        "Start Latitude", "Start Longitude", "End Latitude", "End Longitude"
    ]

    public static func summaryCSV(_ result: WorkReportResult) -> String {
        var headers: [String] = []
        for grouping in result.groupings {
            if grouping == .day {
                headers.append("Day")
            } else {
                headers.append("\(grouping.title) ID")
                headers.append(grouping.title)
            }
        }
        if headers.isEmpty { headers.append("Group") }
        headers.append(contentsOf: ["Duration Seconds", "Entry Count"])

        var lines = [headers.joined(separator: ",")]
        for row in result.rows {
            var fields: [String] = []
            for component in row.key.components {
                switch component.value {
                case .entity(let value):
                    if component.grouping == .day {
                        fields.append(value.contextualName ?? value.name)
                    } else {
                        fields.append(value.id.uuidString)
                        fields.append(value.contextualName ?? value.name)
                    }
                case .unassigned:
                    if component.grouping != .day { fields.append("") }
                    fields.append("Unassigned")
                case .day(_, let label):
                    fields.append(label)
                }
            }
            if row.key.components.isEmpty { fields.append(row.displayName) }
            fields.append(String(row.durationSeconds))
            fields.append(String(row.entryCount))
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Retains the original eight detail columns in order, then appends report
    /// clipping and the hierarchy values captured with each log.
    public static func detailedCSV(_ result: WorkReportResult) -> String {
        let headers = legacyDetailHeaders + [
            "Report Start", "Report End", "Reported Duration",
            "Organization ID", "Organization", "Organization Color", "Organization Symbol",
            "Client ID", "Client", "Client Color", "Client Symbol",
            "Project ID", "Project", "Project Color", "Project Symbol",
            "Task ID", "Task", "Task Color", "Task Symbol"
        ]
        let formatter = ISO8601DateFormatter()
        var lines = [headers.joined(separator: ",")]

        for detail in result.details {
            let entry = detail.entry
            let snapshot = entry.workSnapshot
            let start = validDate(entry.startTime)
            let end = validDate(entry.endTime)
            let duration: String
            if let start, let end, end >= start {
                duration = String(end.timeIntervalSince(start))
            } else {
                duration = ""
            }
            let fields = [
                snapshot.task?.name ?? "Unknown activity",
                start.map(formatter.string(from:)) ?? "",
                end.map(formatter.string(from:)) ?? "",
                duration,
                coordinate(entry.startLatitude),
                coordinate(entry.startLongitude),
                coordinate(entry.endLatitude),
                coordinate(entry.endLongitude),
                formatter.string(from: detail.clippedStart),
                formatter.string(from: detail.clippedEnd),
                String(detail.durationSeconds)
            ] + nodeFields(snapshot.organization)
                + nodeFields(snapshot.client)
                + nodeFields(snapshot.project)
                + nodeFields(snapshot.task)
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    public static func writeSummaryCSV(_ result: WorkReportResult, to destinationURL: URL? = nil) throws -> URL {
        try write(summaryCSV(result), filename: "work-report-summary", to: destinationURL)
    }

    public static func writeDetailedCSV(_ result: WorkReportResult, to destinationURL: URL? = nil) throws -> URL {
        try write(detailedCSV(result), filename: "work-report-details", to: destinationURL)
    }

    private static func write(_ contents: String, filename: String, to destinationURL: URL?) throws -> URL {
        let url = destinationURL ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filename)-\(UUID().uuidString).csv")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func nodeFields(_ node: WorkNodeSnapshot?) -> [String] {
        guard let node else { return ["", "Unassigned", "", ""] }
        return [node.id?.uuidString ?? "", node.name, node.colorHex ?? "", node.sfSymbolName ?? ""]
    }

    private static func validDate(_ date: Date?) -> Date? {
        guard let date, date.timeIntervalSinceReferenceDate.isFinite else { return nil }
        return date
    }

    private static func coordinate(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "" }
        return String(value)
    }

    private static func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
