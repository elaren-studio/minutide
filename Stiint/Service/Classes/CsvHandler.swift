import Foundation

final class CsvHandler {
    func exportDataAsCsv(logs: [ActivityLog], destinationURL: URL? = nil) async throws -> URL {
        let headers = ["Activity", "Start Date", "End Date", "Duration", "Start Latitude", "Start Longitude", "End Latitude", "End Longitude"]
        let dateFormatter = ISO8601DateFormatter()
        var rows = [headers.joined(separator: ",")]

        for log in logs {
            let start = validDate(log.startTime)
            let end = validDate(log.endTime)
            let duration: String
            if let start, let end, end >= start {
                duration = String(end.timeIntervalSince(start))
            } else {
                duration = ""
            }
            let fields = [
                log.activity?.name ?? "Unknown activity",
                start.map { dateFormatter.string(from: $0) } ?? "",
                end.map { dateFormatter.string(from: $0) } ?? "",
                duration,
                coordinate(log.startLatitude),
                coordinate(log.startLongitude),
                coordinate(log.endLatitude),
                coordinate(log.endLongitude),
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }

        // A missing end is an unfinished log, never an invented stop time.
        // Every supplied row is retained, even if its relationship/dates are missing.
        let csv = rows.joined(separator: "\n") + "\n"
        let fileURL = destinationURL ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("activity_logs-\(UUID().uuidString).csv")
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func validDate(_ date: Date?) -> Date? {
        guard let date, date.timeIntervalSinceReferenceDate.isFinite else { return nil }
        return date
    }

    private func coordinate(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "" }
        return String(value)
    }

    private func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
