//
//  AnalytcisDataProvider.swift
//  Stiint
//
//  Created by Wittig, Liam on 15.12.25.
//

import Foundation
import SwiftUI

class AnalyticsDataProvider {
    func loadDataForTimeFrame(filterData: FilterData) async -> TimeFrameData {
        let logs = await PersistenceManager.shared.activityLogActor.getActivityLogsForTimeFrame(filterData: filterData)

        let dataFrame = TimeFrameData(filterData: filterData, logs: logs)

        return dataFrame
    }

    func loadWorkReport(
        filterData: FilterData,
        hierarchyFilters: WorkReportFilters,
        groupings: [WorkReportGrouping],
        metric: WorkReportMetric,
        sorting: [WorkReportSort]
    ) async throws -> WorkReportLoad {
        let capturedNow = Date.now
        let calendar = Calendar.current
        let entries = try await PersistenceManager.shared.activityLogActor.getReportLogs(
            start: filterData.startDate,
            end: filterData.endDate,
            now: capturedNow
        )
        let query = WorkReportQuery(
            startDate: filterData.startDate,
            endDateExclusive: filterData.endDate,
            capturedNow: capturedNow,
            calendar: calendar,
            filters: hierarchyFilters,
            groupings: groupings,
            metric: metric,
            sorting: sorting
        )
        let report = WorkReportEngine.build(entries: entries, query: query)
        var chartFilter = filterData
        if !isAny(hierarchyFilters.organizations) || !isAny(hierarchyFilters.clients)
            || !isAny(hierarchyFilters.projects) || !isAny(hierarchyFilters.tasks) {
            chartFilter.showFreeTime = false
        }
        let charts = TimeFrameData(
            filterData: chartFilter,
            report: report,
            calendar: calendar
        )
        return WorkReportLoad(
            timeFrameData: charts,
            chartFilterData: chartFilter,
            report: report,
            options: WorkReportEngine.options(from: entries)
        )
    }

    private func isAny(_ selection: WorkReportSelection<UUID>) -> Bool {
        if case .any = selection { return true }
        return false
    }
}

struct WorkReportLoad {
    let timeFrameData: TimeFrameData
    let chartFilterData: FilterData
    let report: WorkReportResult
    let options: WorkReportOptions
}

struct DataPoint: Identifiable, Equatable {
    let id: UUID
    let activity: ActivityItem
    var timeSpend: Double
    let filterData: FilterData
    private let averagingDayCount: Int?

    var timeAvg: Double {
        guard let averagingDayCount else { return 0 }
        return timeSpend / Double(averagingDayCount)
    }

    init(
        activity: ActivityItem,
        timeSpend: Double,
        filterData: FilterData,
        calendar: Calendar = .current
    ) {
        id = UUID()
        self.activity = activity
        self.timeSpend = timeSpend
        self.filterData = filterData
        averagingDayCount = calendarDayCount(
            from: filterData.startDate,
            to: filterData.endDate,
            calendar: calendar
        )
    }
}

struct DataSeriesPoint: Identifiable, Equatable {
    let id: UUID
    let activity: ActivityItem
    let date: Date
    var timeSpend: Double
    let color: Color

    init(activity: ActivityItem, timeSpend: Double, date: Date) {
        id = UUID()
        self.activity = activity
        self.timeSpend = timeSpend
        self.date = date
        color = activity.color
    }
}

class TimeFrameData {
    var dataPoints: [DataPoint]
    var dataSeries: [DataSeriesPoint]
    let filterData: FilterData
    let calendar: Calendar
    private var chartEndDate: Date? = nil

    var seriesStyles: [(name: String, color: Color)] {
        var seenNames = Set<String>()
        return dataSeries.compactMap { point in
            guard let name = point.activity.name, seenNames.insert(name).inserted else { return nil }
            return (name: name, color: point.activity.color)
        }
    }

    var timeSpendOnActivities: Double {
        var timeSpend: Double = 0
        for dp in dataPoints {
            timeSpend = timeSpend + dp.timeSpend
        }
        return timeSpend
    }

    var timeOverall: Double {
        guard isFiniteDate(filterData.startDate), isFiniteDate(filterData.endDate) else { return 0 }
        let effectiveEnd = min(chartEndDate ?? filterData.endDate, filterData.endDate)
        let duration = effectiveEnd.timeIntervalSince(filterData.startDate)
        return duration.isFinite && duration > 0 ? duration : 0
    }

    var timeSpendOnActivitiesAvg: Double {
        guard let numberOfDays = calendarDayCount(
            from: filterData.startDate,
            to: filterData.endDate,
            calendar: calendar
        ) else { return 0 }
        return timeSpendOnActivities / Double(numberOfDays)
    }

    var timeOverallAvg: Double {
        guard let numberOfDays = calendarDayCount(
            from: filterData.startDate,
            to: filterData.endDate,
            calendar: calendar
        ) else { return 0 }
        return timeOverall / Double(numberOfDays)
    }

    init(
        filterData: FilterData,
        logs: [ActivityLog],
        calendar: Calendar = .current,
        now: Date = .now
    ) {
        self.filterData = filterData
        self.calendar = calendar
        dataSeries = []
        dataPoints = []

        for log in logs {
            guard let interval = clippedInterval(
                for: log,
                filterData: filterData,
                now: now
            ),
            let dailySlices = splitByCalendarDay(interval, calendar: calendar) else { continue }

            insertLog(interval: interval)
            for slice in dailySlices {
                insertSeries(activity: interval.activity, slice: slice)
            }
        }
    }

    /// Builds all five chart inputs from the same clipped report result used by
    /// the table. Stable group keys ensure a log appears once in each requested
    /// category even when it spans local calendar days.
    init(
        filterData: FilterData,
        report: WorkReportResult,
        calendar: Calendar
    ) {
        self.filterData = filterData
        self.calendar = calendar
        chartEndDate = min(report.capturedNow, filterData.endDate)

        var activitiesByKey: [String: ActivityItem] = [:]
        func activity(for key: WorkReportGroupKey, displayName: String? = nil) -> ActivityItem {
            if let cached = activitiesByKey[key.id] { return cached }
            let style = key.components.reversed().compactMap { component -> WorkReportEntityValue? in
                guard case .entity(let value) = component.value else { return nil }
                return value
            }.first
            let value = ActivityItem(
                name: displayName ?? key.displayName,
                color: Color(hex: style?.colorHex),
                sfSymbolName: style?.sfSymbolName
            )
            activitiesByKey[key.id] = value
            return value
        }

        dataPoints = report.rows.map { row in
            DataPoint(
                activity: activity(for: row.key, displayName: row.displayName),
                timeSpend: row.durationSeconds,
                filterData: filterData,
                calendar: calendar
            )
        }
        dataSeries = report.series.map { point in
            DataSeriesPoint(
                activity: activity(for: point.key, displayName: point.displayName),
                timeSpend: point.durationSeconds,
                date: point.date
            )
        }
    }

    private func insertSeries(activity: ActivityItem, slice: DailyActivitySlice) {
        if let index = dataSeries.firstIndex(where: { point in
            point.date == slice.date && point.activity == activity
        }) {
            dataSeries[index].timeSpend += slice.duration
        } else {
            dataSeries.append(
                DataSeriesPoint(activity: activity, timeSpend: slice.duration, date: slice.date)
            )
        }
    }

    private func insertLog(interval: ClippedActivityInterval) {
        let seconds = interval.duration

        if let index = dataPoints.firstIndex(where: { DataPoint in
            DataPoint.activity == interval.activity
        }) {
            dataPoints[index].timeSpend += seconds

        } else {
            dataPoints.append(
                DataPoint(
                    activity: interval.activity,
                    timeSpend: seconds,
                    filterData: filterData,
                    calendar: calendar
                )
            )
        }
    }
}

private struct ClippedActivityInterval {
    let activity: ActivityItem
    let start: Date
    let end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

private struct DailyActivitySlice {
    let date: Date
    let duration: TimeInterval
}

private func clippedInterval(
    for log: ActivityLog,
    filterData: FilterData,
    now: Date
) -> ClippedActivityInterval? {
    guard let activity = log.activity,
          let originalStart = log.startTime,
          isFiniteDate(originalStart),
          isFiniteDate(filterData.startDate),
          isFiniteDate(filterData.endDate),
          filterData.endDate > filterData.startDate else { return nil }

    let filterDuration = filterData.endDate.timeIntervalSince(filterData.startDate)
    let originalEnd = log.endTime ?? now
    guard filterDuration.isFinite, filterDuration > 0,
          isFiniteDate(originalEnd), originalEnd > originalStart else { return nil }

    let start = max(originalStart, filterData.startDate)
    let end = min(originalEnd, filterData.endDate)
    let duration = end.timeIntervalSince(start)
    guard duration.isFinite, duration > 0 else { return nil }

    return ClippedActivityInterval(activity: activity, start: start, end: end)
}

private func splitByCalendarDay(
    _ interval: ClippedActivityInterval,
    calendar: Calendar
) -> [DailyActivitySlice]? {
    var slices: [DailyActivitySlice] = []
    var sliceStart = interval.start

    while sliceStart < interval.end {
        let dayStart = calendar.startOfDay(for: sliceStart)
        guard isFiniteDate(dayStart), dayStart <= sliceStart,
              let nextDayStart = calendar.date(byAdding: .day, value: 1, to: dayStart),
              isFiniteDate(nextDayStart), nextDayStart > sliceStart else { return nil }

        let sliceEnd = min(interval.end, nextDayStart)
        let seconds = sliceEnd.timeIntervalSince(sliceStart)
        guard seconds.isFinite, seconds > 0 else { return nil }

        slices.append(DailyActivitySlice(date: dayStart, duration: seconds))
        sliceStart = sliceEnd
    }

    return slices.isEmpty ? nil : slices
}

private func isFiniteDate(_ date: Date) -> Bool {
    date.timeIntervalSinceReferenceDate.isFinite
}

private func calendarDayCount(from start: Date, to end: Date, calendar: Calendar) -> Int? {
    guard isFiniteDate(start), isFiniteDate(end), end > start,
          let days = calendar.dateComponents([.day], from: start, to: end).day else { return nil }
    return max(days, 1)
}
