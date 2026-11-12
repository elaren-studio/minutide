import Foundation
import SwiftData
import Testing
@testable import Stiint

@MainActor
struct TimelineDayQueryTests {
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
