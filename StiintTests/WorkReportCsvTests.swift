import Foundation
import Testing
@testable import Stiint

@MainActor
struct WorkReportCsvTests {
    @Test func detailedCSVKeepsLegacyColumnsThenAddsClippedAndCapturedHierarchyValues() {
        let task = id("a0000000-0000-0000-0000-000000000001")
        let org = id("a0000000-0000-0000-0000-000000000002")
        let client = id("a0000000-0000-0000-0000-000000000003")
        let project = id("a0000000-0000-0000-0000-000000000004")
        let entry = WorkReportEntry(
            id: id("a0000000-0000-0000-0000-000000000010"),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 30),
            workSnapshot: WorkSnapshot(
                task: WorkNodeSnapshot(id: task, name: "Build, \"A\"", colorHex: "#112233", sfSymbolName: "hammer.fill"),
                organization: WorkNodeSnapshot(id: org, name: "Studio"),
                client: WorkNodeSnapshot(id: client, name: "Client"),
                project: WorkNodeSnapshot(id: project, name: "Mobile")
            ),
            startLatitude: 32.123456789,
            startLongitude: -97.123456789,
            endLatitude: 32.987654321,
            endLongitude: -97.987654321
        )
        let result = report(entry, start: 10, end: 25)
        let csv = WorkReportCSVExporter.detailedCSV(result)
        let header = csv.components(separatedBy: "\n")[0]

        #expect(header == "Activity,Start Date,End Date,Duration,Start Latitude,Start Longitude,End Latitude,End Longitude,Report Start,Report End,Reported Duration,Organization ID,Organization,Organization Color,Organization Symbol,Client ID,Client,Client Color,Client Symbol,Project ID,Project,Project Color,Project Symbol,Task ID,Task,Task Color,Task Symbol")
        #expect(csv.contains("\"Build, \"\"A\"\"\",\"1970-01-01T00:00:00Z\",\"1970-01-01T00:00:30Z\",\"30.0\",\"32.123456789\",\"-97.123456789\",\"32.987654321\",\"-97.987654321\""))
        #expect(csv.contains("\"1970-01-01T00:00:10Z\",\"1970-01-01T00:00:25Z\",\"15.0\""))
        #expect(csv.contains("\"\(org.uuidString)\",\"Studio\""))
        #expect(csv.contains("\"\(task.uuidString)\",\"Build, \"\"A\"\"\",\"#112233\",\"hammer.fill\""))
    }

    @Test func detailedCSVKeepsOpenEndBlankAndRepresentsReportEndWithoutMutatingEntry() {
        let entry = WorkReportEntry(
            id: id("a1000000-0000-0000-0000-000000000010"),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: nil,
            workSnapshot: WorkSnapshot(task: WorkNodeSnapshot(
                id: id("a1000000-0000-0000-0000-000000000001"), name: "Running task"
            ))
        )
        let result = report(entry, start: 10, end: 25, now: 20)
        let csv = WorkReportCSVExporter.detailedCSV(result)

        #expect(csv.contains("\"Running task\",\"1970-01-01T00:00:00Z\",\"\",\"\""))
        #expect(csv.contains("\"1970-01-01T00:00:10Z\",\"1970-01-01T00:00:20Z\",\"10.0\""))
        #expect(entry.endTime == nil)
    }

    @Test func summaryCSVSeparatesSameNamedTasksByStableIDsAndEscapesNames() {
        let orgA = id("a2000000-0000-0000-0000-000000000001")
        let orgB = id("a2000000-0000-0000-0000-000000000002")
        let taskA = id("a2000000-0000-0000-0000-000000000011")
        let taskB = id("a2000000-0000-0000-0000-000000000012")
        let entries = [
            WorkReportEntry(
                id: id("a2000000-0000-0000-0000-000000000021"),
                startTime: Date(timeIntervalSince1970: 0),
                endTime: Date(timeIntervalSince1970: 60),
                workSnapshot: WorkSnapshot(
                    task: WorkNodeSnapshot(id: taskA, name: "Planning, \"focus\"\nReview"),
                    organization: WorkNodeSnapshot(id: orgA, name: "Studio North")
                )
            ),
            WorkReportEntry(
                id: id("a2000000-0000-0000-0000-000000000022"),
                startTime: Date(timeIntervalSince1970: 60),
                endTime: Date(timeIntervalSince1970: 120),
                workSnapshot: WorkSnapshot(
                    task: WorkNodeSnapshot(id: taskB, name: "Planning, \"focus\"\nReview"),
                    organization: WorkNodeSnapshot(id: orgB, name: "Studio South")
                )
            )
        ]
        let result = WorkReportEngine.build(
            entries: entries,
            query: WorkReportQuery(
                startDate: Date(timeIntervalSince1970: 0),
                endDateExclusive: Date(timeIntervalSince1970: 120),
                capturedNow: Date(timeIntervalSince1970: 120),
                groupings: [.task],
                sorting: [WorkReportSort(field: .name, direction: .ascending)]
            )
        )
        let csv = WorkReportCSVExporter.summaryCSV(result)

        #expect(result.rows.count == 2)
        #expect(Set(result.rows.map(\.displayName)).count == 2)
        #expect(csv.components(separatedBy: "\n")[0] == "Task ID,Task,Duration Seconds,Entry Count")
        #expect(csv.contains("\"\(taskA.uuidString)\",\"Planning, \"\"focus\"\"\nReview — Studio North\""))
        #expect(csv.contains("\"\(taskB.uuidString)\",\"Planning, \"\"focus\"\"\nReview — Studio South\""))
        #expect(csv.components(separatedBy: "\n").filter { $0.contains(taskA.uuidString) }.count == 1)
        #expect(csv.components(separatedBy: "\n").filter { $0.contains(taskB.uuidString) }.count == 1)
    }

    @Test func legacyUnassignedHierarchyAppearsExplicitlyInDetailedCSV() {
        let entry = WorkReportEntry(
            id: id("a3000000-0000-0000-0000-000000000010"),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 60),
            workSnapshot: WorkSnapshot(task: WorkNodeSnapshot(
                id: id("a3000000-0000-0000-0000-000000000001"), name: "Old task"
            ))
        )
        let csv = WorkReportCSVExporter.detailedCSV(report(entry, start: 0, end: 60))

        #expect(csv.contains("\"\",\"Unassigned\",\"\",\"\",\"\",\"Unassigned\",\"\",\"\",\"\",\"Unassigned\""))
        #expect(csv.contains("\"\(entry.workSnapshot.task?.id?.uuidString ?? "")\",\"Old task\""))
    }

    private func report(
        _ entry: WorkReportEntry,
        start: TimeInterval,
        end: TimeInterval,
        now: TimeInterval? = nil
    ) -> WorkReportResult {
        WorkReportEngine.build(
            entries: [entry],
            query: WorkReportQuery(
                startDate: Date(timeIntervalSince1970: start),
                endDateExclusive: Date(timeIntervalSince1970: end),
                capturedNow: Date(timeIntervalSince1970: now ?? end),
                groupings: [.task]
            )
        )
    }

    private func id(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}
