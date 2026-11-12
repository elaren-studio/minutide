import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct TimelineDayQueryTests {
    @Test func secondsLongAndSubsecondEntriesRemainRenderableAndHonestlyLabeled() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let task = ActivityItem(name: "Brief task")
        let brief = ActivityLog(startTime: now, endTime: now.addingTimeInterval(28), activity: task)
        let segment = TimeLineActivitySegmentView(start: 20, end: 20.32, log: brief, now: now)
        #expect(segment.shouldRenderSegment)
        #expect(segment.timeDistance == "28 sec")
        let next = ActivityLog(startTime: now.addingTimeInterval(28),
                               endTime: now.addingTimeInterval(28.25), activity: task)
        let nextSegment = TimeLineActivitySegmentView(start: 20.32, end: 20.323, log: next, now: now)
        #expect(nextSegment.shouldRenderSegment)
        #expect(nextSegment.timeDistance == "<1 sec")
        #expect(MyDayEntry.durationText(89.9) == "1 min 29 sec")
        #expect(MyDayEntry.durationText(.infinity) == "0 sec")
        #expect(brief.endTime?.timeIntervalSince(now) == 28)
    }

    @Test func shortMalformedIntervalsRemainExcludedRegardlessOfGeometry() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let logs = [
            ActivityLog(startTime: now, endTime: now),
            ActivityLog(startTime: now, endTime: now.addingTimeInterval(-1)),
            ActivityLog(startTime: now, endTime: Date(timeIntervalSinceReferenceDate: .nan)),
            ActivityLog(startTime: now.addingTimeInterval(1), endTime: nil)
        ]
        for log in logs {
            #expect(!TimeLineActivitySegmentView(start: 0, end: 1, log: log, now: now).shouldRenderSegment)
        }
    }

    @Test func sharedDayProjectionClipsMidnightSortsAndPreservesOrphanHistory() throws {
        let fixture = try TimelineDayFixture()
        let start = try fixture.date(year: 2026, month: 11, day: 11)
        let end = try fixture.date(year: 2026, month: 11, day: 12)
        let orphan = fixture.add(start: start.addingTimeInterval(-28), end: start.addingTimeInterval(12))
        orphan.workSnapshot = WorkSnapshot(task: WorkNodeSnapshot(id: UUID(), name: "Captured task",
                                                                  colorHex: "#123456", sfSymbolName: "book.fill"))
        let brief = fixture.add(start: end.addingTimeInterval(-28), end: end.addingTimeInterval(12))
        let malformed = fixture.add(start: start.addingTimeInterval(1), end: start)
        let entries = MyDayEntry.entries(logs: [brief, malformed, orphan], dayStart: start, dayEnd: end,
                                         now: end, scope: .allWork)
        #expect(entries.map { $0.log.id } == [orphan.id, brief.id])
        #expect(entries.map(\.duration) == [12, 28])
        #expect(entries.reduce(0) { $0 + $1.duration } == 40)
        #expect(entries.first?.task?.name == "Captured task")
        #expect(entries.first?.task?.colorHex == "#123456")
        #expect(orphan.activity == nil)
        #expect(orphan.startTime == start.addingTimeInterval(-28))
        #expect(brief.endTime == end.addingTimeInterval(12))
    }

    @Test func sharedProjectionUsesCapturedOrganizationAndLiveNowForRunningEntries() throws {
        let fixture = try TimelineDayFixture()
        let start = try fixture.date(year: 2026, month: 11, day: 11)
        let end = try fixture.date(year: 2026, month: 11, day: 12)
        let organization = UUID()
        let assigned = fixture.add(start: start.addingTimeInterval(10), end: nil)
        assigned.workSnapshot = WorkSnapshot(organization: WorkNodeSnapshot(id: organization, name: "Recorded org"))
        let unassigned = fixture.add(start: start.addingTimeInterval(20), end: start.addingTimeInterval(48))
        let future = fixture.add(start: start.addingTimeInterval(100), end: nil)
        let logs = [future, unassigned, assigned]
        let early = MyDayEntry.entries(logs: logs, dayStart: start, dayEnd: end,
                                       now: start.addingTimeInterval(38), scope: .organization(organization))
        #expect(early.map { $0.log.id } == [assigned.id])
        #expect(early.first?.isRunning == true)
        #expect(early.first?.duration == 28)
        let later = MyDayEntry.entries(logs: logs, dayStart: start, dayEnd: end,
                                       now: start.addingTimeInterval(48), scope: .organization(organization))
        #expect(later.first?.duration == 38)
        let unassignedEntries = MyDayEntry.entries(logs: logs, dayStart: start, dayEnd: end,
                                                    now: start.addingTimeInterval(48), scope: .unassigned)
        #expect(unassignedEntries.map { $0.log.id } == [unassigned.id])
        #expect(MyDayEntry.entries(logs: logs, dayStart: start, dayEnd: end, now: start,
                                  scope: .allWork).map { $0.log.id } == [unassigned.id])
    }

    @Test func dayProjectionUsesCalendarBoundariesAcrossDSTAndRejectsInvalidRows() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let end = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        let fullDay = ActivityLog(startTime: start.addingTimeInterval(-28), endTime: end.addingTimeInterval(28))
        let missing = ActivityLog(startTime: start, endTime: end)
        missing.startTime = nil
        let nonfinite = ActivityLog(startTime: start, endTime: Date(timeIntervalSinceReferenceDate: .infinity))
        let entries = MyDayEntry.entries(logs: [missing, nonfinite, fullDay], dayStart: start, dayEnd: end,
                                         now: end, scope: .allWork)
        #expect(entries.count == 1)
        let duration = try #require(entries.first?.duration)
        #expect(duration == TimeInterval(25 * 3600))
        #expect(MyDayEntry.entries(logs: [fullDay], dayStart: end, dayEnd: start,
                                  now: end, scope: .allWork).isEmpty)
        #expect(MyDayEntry.entries(logs: [fullDay], dayStart: start, dayEnd: end,
                                  now: Date(timeIntervalSinceReferenceDate: .nan), scope: .allWork).isEmpty)
    }

    @Test func includesIntervalsThatOverlapDayAndExcludesAdjacentOrMalformedRows() throws {
        let fixture = try TimelineDayFixture()
        let dayStart = try fixture.date(year: 2026, month: 11, day: 11)
        let dayEnd = try fixture.date(year: 2026, month: 11, day: 12)
        let inside = dayStart.addingTimeInterval(60 * 60)
        let before = dayStart.addingTimeInterval(-60 * 60)
        let after = dayEnd.addingTimeInterval(60 * 60)

        let allDay = fixture.add(start: dayStart, end: dayEnd)
        let startsAtDayStart = fixture.add(start: dayStart, end: inside)
        let spansAcrossDay = fixture.add(start: before, end: after)
        let endsAtDayStart = fixture.add(start: before, end: dayStart)
        let startsAtDayEnd = fixture.add(start: dayEnd, end: after)
        let outsideBefore = fixture.add(
            start: before.addingTimeInterval(-60),
            end: before
        )
        let outsideAfter = fixture.add(
            start: after,
            end: after.addingTimeInterval(60)
        )
        let reversed = fixture.add(start: inside, end: dayStart)
        let zeroLength = fixture.add(start: inside, end: inside)
        let missingStart = fixture.add(start: nil, end: inside)

        let results = try fixture.fetch(dayStart: dayStart, dayEnd: dayEnd, now: inside)
        #expect(fixture.ids(results) == fixture.ids([allDay, startsAtDayStart, spansAcrossDay]))
        #expect(results.contains { $0.id == allDay.id })
        #expect(!results.contains { $0.id == endsAtDayStart.id })
        #expect(!results.contains { $0.id == startsAtDayEnd.id })
        #expect(!results.contains { $0.id == outsideBefore.id })
        #expect(!results.contains { $0.id == outsideAfter.id })
        #expect(!results.contains { $0.id == reversed.id })
        #expect(!results.contains { $0.id == zeroLength.id })
        #expect(!results.contains { $0.id == missingStart.id })
    }

    @Test func includesRunningOverlapUsingOneCapturedNowAndExcludesMalformedRunningRows() throws {
        let fixture = try TimelineDayFixture()
        let dayStart = try fixture.date(year: 2026, month: 11, day: 11)
        let dayEnd = try fixture.date(year: 2026, month: 11, day: 12)
        let now = dayStart.addingTimeInterval(60 * 60)

        let runningAcrossStart = fixture.add(
            start: dayStart.addingTimeInterval(-60 * 60),
            end: nil
        )
        let runningInsideDay = fixture.add(
            start: dayStart.addingTimeInterval(30 * 60),
            end: nil
        )
        let futureRunning = fixture.add(
            start: dayStart.addingTimeInterval(2 * 60 * 60),
            end: nil
        )
        let nonfiniteStartRunning = fixture.add(
            start: Date(timeIntervalSinceReferenceDate: .nan),
            end: nil
        )
        let nonfiniteEnd = fixture.add(
            start: dayStart.addingTimeInterval(30 * 60),
            end: Date(timeIntervalSinceReferenceDate: .infinity)
        )
        let missingStartRunning = fixture.add(start: nil, end: nil)

        let results = try fixture.fetch(dayStart: dayStart, dayEnd: dayEnd, now: now)
        #expect(fixture.ids(results) == fixture.ids([runningAcrossStart, runningInsideDay]))
        #expect(runningAcrossStart.endTime == nil)
        #expect(runningInsideDay.endTime == nil)
        #expect(!results.contains { $0.id == futureRunning.id })
        #expect(!results.contains { $0.id == nonfiniteStartRunning.id })
        #expect(!results.contains { $0.id == nonfiniteEnd.id })
        #expect(!results.contains { $0.id == missingStartRunning.id })

        let beforeDay = try fixture.fetch(
            dayStart: dayStart,
            dayEnd: dayEnd,
            now: dayStart.addingTimeInterval(-60)
        )
        #expect(beforeDay.isEmpty)
    }
}

@MainActor
private final class TimelineDayFixture {
    let container: ModelContainer
    let context: ModelContext
    private var calendar: Calendar

    init() throws {
        let schema = Schema([ActivityItem.self, ActivityLog.self])
        container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    }

    func date(year: Int, month: Int, day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    @discardableResult
    func add(start: Date?, end: Date?) -> ActivityLog {
        let log = ActivityLog(startTime: start, endTime: end)
        // ActivityLog defaults a nil start to now; restore it to model a malformed persisted row.
        log.startTime = start
        log.endTime = end
        context.insert(log)
        return log
    }

    func fetch(dayStart: Date, dayEnd: Date, now: Date) throws -> [ActivityLog] {
        try context.save()
        let predicate = TimelineDayQuery.predicate(dayStart: dayStart, dayEnd: dayEnd, now: now)
        return try context.fetch(FetchDescriptor<ActivityLog>(predicate: predicate))
    }

    func ids(_ logs: [ActivityLog]) -> Set<UUID> {
        Set(logs.compactMap(\.id))
    }
}
