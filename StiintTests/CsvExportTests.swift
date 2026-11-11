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
        let target = FileManager.default.temporaryDirectory
            .appendingPathComponent("stiint-export-test-\(UUID().uuidString).csv")
        defer { try? FileManager.default.removeItem(at: target) }
        let exported = try await CsvHandler().exportDataAsCsv(logs: logs, destinationURL: target)
        #expect(exported == target)
        return try String(contentsOf: exported, encoding: .utf8)
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
