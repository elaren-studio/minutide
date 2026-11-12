import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct CsvExportTests {
    private static let header = "Activity,Start Date,End Date,Duration,Start Latitude,Start Longitude,End Latitude,End Longitude\n"

    @Test func exportEscapesCommasQuotesAndNewlinesAndKeepsExactCoordinates() async throws {
        let fixture = try ExportFixture()
        let activity = ActivityItem(name: "Planning, \"focus\"\nReview")
        fixture.context.insert(activity)
        let log = ActivityLog(startTime: Date(timeIntervalSince1970: 0),
                              endTime: Date(timeIntervalSince1970: 60), activity: activity)
        log.startLatitude = 32.123456789
        log.startLongitude = -97.123456789
        log.endLatitude = 32.987654321
        log.endLongitude = -97.987654321
        fixture.context.insert(log)
        try fixture.context.save()

        let csv = try await readExport([log])
        #expect(csv == Self.header + "\"Planning, \"\"focus\"\"\nReview\",\"1970-01-01T00:00:00Z\",\"1970-01-01T00:01:00Z\",\"60.0\",\"32.123456789\",\"-97.123456789\",\"32.987654321\",\"-97.987654321\"\n")
    }

    @Test func exportKeepsOrphanAndIncompleteCompletedRows() async throws {
        let fixture = try ExportFixture()
        let orphan = ActivityLog(startTime: Date(timeIntervalSince1970: 0),
                                 endTime: Date(timeIntervalSince1970: 60))
        let missingStart = ActivityLog(endTime: Date(timeIntervalSince1970: 60))
        missingStart.startTime = nil
        let reversed = ActivityLog(startTime: Date(timeIntervalSince1970: 60),
                                   endTime: Date(timeIntervalSince1970: 0))
        for log in [orphan, missingStart, reversed] { fixture.context.insert(log) }
        try fixture.context.save()

        let csv = try await readExport([orphan, missingStart, reversed])
        #expect(csv == Self.header
            + "\"Unknown activity\",\"1970-01-01T00:00:00Z\",\"1970-01-01T00:01:00Z\",\"60.0\",\"\",\"\",\"\",\"\"\n"
            + "\"Unknown activity\",\"\",\"1970-01-01T00:01:00Z\",\"\",\"\",\"\",\"\",\"\"\n"
            + "\"Unknown activity\",\"1970-01-01T00:01:00Z\",\"1970-01-01T00:00:00Z\",\"\",\"\",\"\",\"\",\"\"\n")
    }

    @Test func unfinishedLogHasBlankEndAndDurationWithoutMutatingTimer() async throws {
        let fixture = try ExportFixture()
        let activity = ActivityItem(name: "Still running")
        fixture.context.insert(activity)
        let log = ActivityLog(startTime: Date(timeIntervalSince1970: 0), activity: activity)
        fixture.context.insert(log)
        try fixture.context.save()
        let csv = try await readExport([log])
        #expect(csv == Self.header + "\"Still running\",\"1970-01-01T00:00:00Z\",\"\",\"\",\"\",\"\",\"\",\"\"\n")
        #expect(log.endTime == nil)
    }

    @Test func nonfiniteDatesAndCoordinatesExportAsBlankCells() async throws {
        let fixture = try ExportFixture()
        let log = ActivityLog()
        fixture.context.insert(log)
        log.startTime = Date(timeIntervalSinceReferenceDate: .nan)
        log.endTime = Date(timeIntervalSinceReferenceDate: .infinity)
        log.startLatitude = .nan
        log.endLongitude = .infinity
        let csv = try await readExport([log])
        #expect(csv == Self.header + "\"Unknown activity\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\n")
    }

    @Test func emptyExportWritesHeaderToRequestedTemporaryFile() async throws {
        #expect(try await readExport([]) == Self.header)
    }

    @Test func hierarchyExportPreservesCapturedNamesAndIndependentAppearance() async throws {
        let fixture = try ExportFixture()
        let task = ActivityItem(name: "Current task name")
        let taskID = try #require(task.id)
        let organizationID = UUID(), clientID = UUID(), projectID = UUID()
        let log = ActivityLog(startTime: Date(timeIntervalSince1970: 0),
                              endTime: Date(timeIntervalSince1970: 60), activity: task)
        log.workSnapshot = WorkSnapshot(
            task: WorkNodeSnapshot(id: taskID, name: "Recorded, task", colorHex: "#112233", sfSymbolName: "pencil"),
            organization: WorkNodeSnapshot(id: organizationID, name: "Studio", colorHex: "#445566", sfSymbolName: "building.2"),
            client: WorkNodeSnapshot(id: clientID, name: "Client \"A\"", colorHex: "#778899", sfSymbolName: "person"),
            project: WorkNodeSnapshot(id: projectID, name: "Project\nAlpha", colorHex: "#AABBCC", sfSymbolName: "folder"))
        fixture.context.insert(task)
        fixture.context.insert(log)
        try fixture.context.save()
        task.name = "Renamed task"
        try fixture.context.save()
        let rows = parseCSV(try await fullExport([log]))
        #expect(rows.count == 2)
        #expect(Array(rows[0].prefix(8)).joined(separator: ",") + "\n" == Self.header)
        let values = Dictionary(uniqueKeysWithValues: zip(rows[0], rows[1]))
        #expect(values["Activity"] == "Recorded, task")
        #expect(values["Task ID"] == taskID.uuidString)
        #expect(values["Organization ID"] == organizationID.uuidString)
        #expect(values["Client Name"] == "Client \"A\"")
        #expect(values["Project Name"] == "Project\nAlpha")
        #expect(values["Task Color"] == "#112233")
        #expect(values["Client Icon"] == "person")
        #expect(values["Project Color"] == "#AABBCC")
        #expect(values["Assignment Version"] == "1")
    }

    @Test func orphanAndMalformedLogDetailsInitializeWithoutForcedUnwraps() throws {
        let fixture = try ExportFixture()
        let missingDates = ActivityLog()
        missingDates.startTime = nil
        missingDates.endTime = Date(timeIntervalSince1970: 60)
        let reversedDates = ActivityLog(startTime: Date(timeIntervalSince1970: 60),
                                        endTime: Date(timeIntervalSince1970: 0))
        for log in [missingDates, reversedDates] {
            fixture.context.insert(log)
            _ = LogDetailView(log: log)
        }
        #expect(missingDates.activity == nil)
        #expect(missingDates.startTime == nil)
        #expect(reversedDates.startTime == Date(timeIntervalSince1970: 60))
    }

    private func readExport(_ logs: [ActivityLog]) async throws -> String {
        // Assert the original eight-column contract independently of the new
        // metadata suffix, including quoted embedded commas and newlines.
        let rows = parseCSV(try await fullExport(logs))
        return rows.enumerated().map { index, row in
            row.prefix(8).map { index == 0 ? $0 : "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
                .joined(separator: ",")
        }.joined(separator: "\n") + "\n"
    }

    private func fullExport(_ logs: [ActivityLog]) async throws -> String {
        let target = FileManager.default.temporaryDirectory
            .appendingPathComponent("stiint-export-test-\(UUID().uuidString).csv")
        defer { try? FileManager.default.removeItem(at: target) }
        let exported = try await CsvHandler().exportDataAsCsv(logs: logs, destinationURL: target)
        #expect(exported == target)
        return try String(contentsOf: exported, encoding: .utf8)
    }

    private func parseCSV(_ csv: String) -> [[String]] {
        var rows: [[String]] = [], row: [String] = [], cell = "", quoted = false
        let characters = Array(csv)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if quoted, index + 1 < characters.count, characters[index + 1] == "\"" {
                    cell.append("\""); index += 1
                } else { quoted.toggle() }
            } else if character == ",", !quoted {
                row.append(cell); cell = ""
            } else if character == "\n", !quoted {
                row.append(cell); rows.append(row); row = []; cell = ""
            } else { cell.append(character) }
            index += 1
        }
        return rows
    }
}

@MainActor
private final class ExportFixture {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let schema = Schema([ActivityItem.self, ActivityLog.self])
        container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
        context = ModelContext(container)
    }
}
