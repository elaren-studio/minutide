import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import Stiint

@MainActor
struct AnalyticsIntervalTests {
    @Test func clipsIntervalAtFilterBoundariesAndKeepsAggregateAndSeriesConsistent() throws {
        let calendar = try makeCalendar(timeZoneIdentifier: "UTC")
        let today = try date(2026, 11, 11, 0, 0, calendar: calendar)
        let filterEnd = today.addingTimeInterval(60 * 60)
        let activity = ActivityItem(name: "Cross midnight")
        let log = makeLog(
            activity: activity,
            start: today.addingTimeInterval(-60 * 60),
            end: filterEnd.addingTimeInterval(60 * 60)
        )

        let data = TimeFrameData(
            filterData: filter(start: today, end: filterEnd),
            logs: [log],
            calendar: calendar,
            now: filterEnd.addingTimeInterval(2 * 60 * 60)
        )

        #expect(data.dataPoints.count == 1)
        #expect(data.dataPoints[0].timeSpend == 60 * 60)
        #expect(data.dataSeries.count == 1)
        #expect(data.dataSeries[0].date == today)
        #expect(data.dataSeries[0].timeSpend == data.dataPoints[0].timeSpend)
    }

    @Test func splitsMultiDayIntervalIntoCalendarDayTotals() throws {
        let calendar = try makeCalendar(timeZoneIdentifier: "UTC")
        let firstDay = try date(2026, 1, 1, 0, 0, calendar: calendar)
        let start = firstDay.addingTimeInterval(23 * 60 * 60)
        let thirdDay = try #require(calendar.date(byAdding: .day, value: 2, to: firstDay))
        let end = thirdDay.addingTimeInterval(60 * 60)
        let secondDay = try #require(calendar.date(byAdding: .day, value: 1, to: firstDay))
        let filterEnd = try #require(calendar.date(byAdding: .day, value: 3, to: firstDay))
        let activity = ActivityItem(name: "Overnight span")
        let log = makeLog(activity: activity, start: start, end: end)

        let data = TimeFrameData(
            filterData: filter(start: firstDay, end: filterEnd),
            logs: [log],
            calendar: calendar,
            now: filterEnd
        )

        #expect(data.dataPoints.count == 1)
        #expect(data.dataPoints[0].timeSpend == 26 * 60 * 60)
        let expectedDurations: [Double] = [3_600, 86_400, 3_600]
        #expect(data.dataSeries.map(\.timeSpend) == expectedDurations)
        #expect(data.dataSeries.map(\.date) == [
            firstDay,
            secondDay,
            thirdDay,
        ])
        #expect(data.dataSeries.reduce(0) { $0 + $1.timeSpend } == data.dataPoints[0].timeSpend)
    }

    @Test func splitsSpringAndFallDayBoundariesUsingInjectedTimeZone() throws {
        let calendar = try makeCalendar(timeZoneIdentifier: "America/Los_Angeles")
        let activity = ActivityItem(name: "DST span")

        let springStart = try date(2026, 3, 7, 0, 0, calendar: calendar)
        let springEnd = try date(2026, 3, 9, 0, 0, calendar: calendar)
        let springLog = makeLog(activity: activity, start: springStart, end: springEnd)
        let spring = TimeFrameData(
            filterData: filter(start: springStart, end: springEnd),
            logs: [springLog],
            calendar: calendar,
            now: springEnd
        )

        let springDurations: [Double] = [86_400, 82_800]
        #expect(spring.dataSeries.map(\.timeSpend) == springDurations)
        #expect(spring.dataPoints.first?.timeSpend == 169_200.0)
        #expect(spring.dataSeries.reduce(0) { $0 + $1.timeSpend } == spring.dataPoints[0].timeSpend)

        let fallStart = try date(2026, 10, 31, 0, 0, calendar: calendar)
        let fallEnd = try date(2026, 11, 2, 0, 0, calendar: calendar)
        let fallLog = makeLog(activity: activity, start: fallStart, end: fallEnd)
        let fall = TimeFrameData(
            filterData: filter(start: fallStart, end: fallEnd),
            logs: [fallLog],
            calendar: calendar,
            now: fallEnd
        )

        let fallDurations: [Double] = [86_400, 90_000]
        #expect(fall.dataSeries.map(\.timeSpend) == fallDurations)
        #expect(fall.dataPoints.first?.timeSpend == 176_400.0)
        #expect(fall.dataSeries.reduce(0) { $0 + $1.timeSpend } == fall.dataPoints[0].timeSpend)
    }

    @Test func runningIntervalUsesInjectedNowWithoutChangingLog() throws {
        let calendar = try makeCalendar(timeZoneIdentifier: "UTC")
        let start = try date(2026, 11, 11, 12, 0, calendar: calendar)
        let now = start.addingTimeInterval(45 * 60)
        let filterEnd = start.addingTimeInterval(60 * 60)
        let activity = ActivityItem(name: "Running")
        let log = makeLog(activity: activity, start: start, end: nil)

        let data = TimeFrameData(
            filterData: filter(start: start, end: filterEnd),
            logs: [log],
            calendar: calendar,
            now: now
        )

        #expect(data.dataPoints.first?.timeSpend == 2_700.0)
        #expect(data.dataSeries.first?.timeSpend == 2_700.0)
        #expect(log.endTime == nil)
    }

    @Test func malformedIntervalsDoNotEnterAnalyticsOrCreateInvalidStatistics() throws {
        let calendar = try makeCalendar(timeZoneIdentifier: "UTC")
        let start = try date(2026, 11, 11, 0, 0, calendar: calendar)
        let end = start.addingTimeInterval(60 * 60)
        let activity = ActivityItem(name: "Malformed rows")

        let missingStart = makeLog(activity: activity, start: start, end: end)
        missingStart.startTime = nil
        let nonfiniteStart = makeLog(
            activity: activity,
            start: Date(timeIntervalSinceReferenceDate: .nan),
            end: end
        )
        let nonfiniteEnd = makeLog(
            activity: activity,
            start: start,
            end: Date(timeIntervalSinceReferenceDate: .infinity)
        )
        let reversed = makeLog(activity: activity, start: end, end: start)
        let zeroLength = makeLog(activity: activity, start: start, end: start)
        let futureRunning = makeLog(activity: activity, start: end, end: nil)
        let running = makeLog(activity: activity, start: start, end: nil)

        let data = TimeFrameData(
            filterData: filter(start: start, end: end),
            logs: [missingStart, nonfiniteStart, nonfiniteEnd, reversed, zeroLength, futureRunning],
            calendar: calendar,
            now: start
        )

        #expect(data.dataPoints.isEmpty)
        #expect(data.dataSeries.isEmpty)
        #expect(data.timeSpendOnActivities == 0)
        #expect(data.timeSpendOnActivities.isFinite)
        #expect(data.timeOverall.isFinite)

        let invalidNow = TimeFrameData(
            filterData: filter(start: start, end: end),
            logs: [running],
            calendar: calendar,
            now: Date(timeIntervalSinceReferenceDate: .nan)
        )
        #expect(invalidNow.dataPoints.isEmpty)
        #expect(invalidNow.dataSeries.isEmpty)

        let invalidFilter = TimeFrameData(
            filterData: filter(start: Date(timeIntervalSinceReferenceDate: .nan), end: end),
            logs: [running],
            calendar: calendar,
            now: end
        )
        #expect(invalidFilter.dataPoints.isEmpty)
        #expect(invalidFilter.timeOverall == 0)
        #expect(invalidFilter.timeOverallAvg == 0)
    }

    @Test func timelineSegmentInitializationAndGeometryHandleMalformedValues() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let activity = ActivityItem(name: "Timeline")
        let missingStart = makeLog(activity: activity, start: now, end: now.addingTimeInterval(120))
        missingStart.startTime = nil
        let missingStartView = TimeLineActivitySegmentView(
            start: 0,
            end: 120,
            log: missingStart,
            now: now
        )
        #expect(missingStartView.timeDistance == "Duration unavailable")
        #expect(!missingStartView.shouldRenderSegment)
        _ = missingStartView.body

        let reversed = makeLog(activity: activity, start: now.addingTimeInterval(120), end: now)
        let reversedView = TimeLineActivitySegmentView(start: 0, end: 120, log: reversed, now: now)
        #expect(reversedView.timeDistance == "Duration unavailable")
        #expect(!reversedView.shouldRenderSegment)
        _ = reversedView.body

        let nonfiniteEnd = makeLog(
            activity: activity,
            start: now,
            end: Date(timeIntervalSinceReferenceDate: .infinity)
        )
        let nonfiniteEndView = TimeLineActivitySegmentView(start: 0, end: 120, log: nonfiniteEnd, now: now)
        #expect(nonfiniteEndView.timeDistance == "Duration unavailable")
        #expect(!nonfiniteEndView.shouldRenderSegment)
        _ = nonfiniteEndView.body

        let malformedRunning = makeLog(activity: activity, start: now, end: nil)
        malformedRunning.startTime = Date(timeIntervalSinceReferenceDate: .infinity)
        let runningView = TimeLineActivitySegmentView(
            start: 0,
            end: 120,
            log: malformedRunning,
            now: now
        )
        #expect(runningView.timeDistance == "Duration unavailable")
        #expect(!runningView.shouldRenderSegment)
        _ = runningView.body

        let futureRunning = makeLog(activity: activity, start: now.addingTimeInterval(120), end: nil)
        let futureRunningView = TimeLineActivitySegmentView(start: 0, end: 120, log: futureRunning, now: now)
        #expect(!futureRunningView.shouldRenderSegment)
        _ = futureRunningView.body

        let valid = makeLog(activity: activity, start: now, end: now.addingTimeInterval(120))
        let validView = TimeLineActivitySegmentView(start: 0, end: 120, log: valid, now: now)
        #expect(validView.shouldRenderSegment)
        _ = validView.body

        let validRunning = makeLog(activity: activity, start: now, end: nil)
        let validRunningView = TimeLineActivitySegmentView(start: 0, end: 120, log: validRunning, now: now)
        #expect(validRunningView.shouldRenderSegment)
        _ = validRunningView.body

        let invalidGeometry = TimeLineActivitySegmentView(
            start: .nan,
            end: .infinity,
            log: valid,
            now: now
        )
        #expect(!invalidGeometry.hasValidGeometry)
        #expect(!invalidGeometry.shouldRenderSegment)
        _ = invalidGeometry.body

        let negativeGeometry = TimeLineActivitySegmentView(start: 120, end: 0, log: valid, now: now)
        #expect(!negativeGeometry.hasValidGeometry)
        #expect(!negativeGeometry.shouldRenderSegment)
        _ = negativeGeometry.body
    }

    private func makeCalendar(timeZoneIdentifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return try #require(calendar.date(from: components))
    }

    private func filter(start: Date, end: Date) -> FilterData {
        FilterData(startDate: start, endDate: end, showFreeTime: false, selectedActivityIds: [])
    }

    private func makeLog(activity: ActivityItem, start: Date?, end: Date?) -> ActivityLog {
        let log = ActivityLog(startTime: start, endTime: end, activity: activity)
        log.startTime = start
        log.endTime = end
        return log
    }
}
