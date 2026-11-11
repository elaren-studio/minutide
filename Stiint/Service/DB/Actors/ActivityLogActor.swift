//
//  ActivityLogActor.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//

import Foundation
import SwiftData
import CoreLocation
import os

@ModelActor
public actor ActivityLogActor {
    public struct RunningActivity: Sendable {
        public let logId: UUID
        public let activity: ActivityDTO
    }

    /// The database owns timer state. Preferences are only a recovery hint.
    /// Historical unfinished rows are closed, never deleted, when recovering.
    public func recoverRunningActivity(preferredLogId: UUID? = nil) throws -> RunningActivity? {
        let logs = try modelContext.fetch(FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.endTime == nil }
        ))
        let ordered = logs.sorted {
            let first = $0.startTime ?? .distantPast
            let second = $1.startTime ?? .distantPast
            if first != second { return first < second }
            if $0.id == preferredLogId { return false }
            if $1.id == preferredLogId { return true }
            return ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "")
        }
        let current = ordered.last(where: { runningActivity(for: $0) != nil })

        for (index, log) in ordered.enumerated() where log !== current {
            let nextStart = ordered.dropFirst(index + 1).compactMap(\.startTime).first
            log.endTime = max(log.startTime ?? .distantPast, nextStart ?? Date.now)
        }
        if modelContext.hasChanges {
            do { try modelContext.save() }
            catch { modelContext.rollback(); throw error }
        }
        return current.flatMap { runningActivity(for: $0) }
    }

    /// Validation, closing the previous timer, and insertion happen before any
    /// suspension, so concurrent callers cannot create two running timers.
    public func startOrSwitchActivity(activityId: UUID, preferredLogId: UUID? = nil) async throws -> RunningActivity? {
        // Other model contexts (the editor and ActivityActor) can archive an
        // already-registered activity. Validate against a fresh store read.
        let validationContext = ModelContext(modelContainer)
        guard let savedActivity = try validationContext.fetch(FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )).first, savedActivity.archived != true else { return nil }
        guard let activity = try modelContext.fetch(FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )).first, activity.archived != true, activity.name != nil else { return nil }

        let current = try recoverRunningActivity(preferredLogId: preferredLogId)
        if current?.activity.id == activityId { return current }

        let now = max(Date.now, current?.activity.startTime ?? .distantPast)
        let previous = current.flatMap { getActivityLogById(from: $0.logId) }
        previous?.endTime = max(previous?.startTime ?? now, now)
        let log = ActivityLog(startTime: now, activity: activity, previousActivityLogId: current?.logId)
        modelContext.insert(log)
        do { try modelContext.save() }
        catch { modelContext.rollback(); throw error }

        let result = runningActivity(for: log)
        if previous?.activity?.storeLocation == true, let id = previous?.id {
            Task { await captureLocation(activityLogId: id, isStart: false) }
        }
        if activity.storeLocation == true, let id = log.id {
            Task { await captureLocation(activityLogId: id, isStart: true) }
        }
        return result
    }

    // Optional metadata must never hold up starting/stopping a timer or its UI.
    private func captureLocation(activityLogId: UUID, isStart: Bool) async {
        guard let location = try? await LocationProvider.shared.getCurrentLocation(),
              let log = getActivityLogById(from: activityLogId) else { return }
        if isStart {
            log.startLatitude = location.coordinate.latitude
            log.startLongitude = location.coordinate.longitude
        } else {
            log.endLatitude = location.coordinate.latitude
            log.endLongitude = location.coordinate.longitude
        }
        do { try modelContext.save() }
        catch { modelContext.rollback() }
    }

    private func runningActivity(for log: ActivityLog) -> RunningActivity? {
        guard let id = log.id, let dto = getActivtyLogDTO(activityLogId: id) else { return nil }
        return RunningActivity(logId: id, activity: dto)
    }

    public func startActivity(activityId: UUID, previousAcvitiyLogId: UUID? = nil) async -> UUID? {
        try? await startOrSwitchActivity(activityId: activityId)?.logId
    }
    
    
    public func insertActivityLog(
        activityId: UUID,
        startTime: Date,
        endTime: Date
    ){
        let fetchDescriptor = FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )
        guard let activity = try? modelContext.fetch(fetchDescriptor).first,
              activity.archived != true else { return }
        
        
        let activityLog = ActivityLog(
            startTime: startTime,
            endTime: endTime,
            activity: activity
        )
        
        modelContext.insert(activityLog)
        try? modelContext.save()
    }

    
    // Compatibility entry point for older callers. Recovery preserves history.
    public func killDeadActvities(knwonRunningid: UUID?) throws {
        _ = try recoverRunningActivity(preferredLogId: knwonRunningid)
    }
    
    public func mergeNearbyLogsIfNeeded(activityLogId: UUID) throws {
        // Keep explicit boundaries intact. Automatic merging remains disabled.
    }
    
    
    private func mergeUpperLog(activityLogId: UUID) throws {
        let defaultDate = Date.distantPast
        let defaultDateFuture = Date.distantFuture
        
        guard
            let log = getActivityLogById(from: activityLogId),
            let activityId = log.activity?.id,
            let endTime = log.endTime // We look relative to the END of the current log
        else { return }
        
        // Business logic check (consistent with your lower merge)
        guard log.activity?.storeLocation == false else { return }

        // Define the window: 2 minutes after the current log ends
        let upperBound = endTime.addingTimeInterval(2 * 60)

        // 1. Predicate: Find logs starting in the 2-minute window after this one ends
        let predicate = #Predicate<ActivityLog> { nextLog in
            (nextLog.startTime ?? defaultDateFuture) <= upperBound &&
            (nextLog.startTime ?? defaultDate) >= endTime
        }

        let descriptor = FetchDescriptor<ActivityLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)] // Closest start time first
        )

        let candidates = try modelContext.fetch(descriptor)

        // 2. Filter: Ensure matching activity and unique ID
        guard let upperLog = candidates.first(where: {
            $0.activity?.id == activityId && $0.id != activityLogId
        }) else {
            return
        }

        // 3. Merge: "Stretch" the current log's end to the upper log's end
        log.endTime = upperLog.endTime
        modelContext.delete(upperLog)

        try modelContext.save()
    }
    
    private func mergeLowerLog(activityLogId: UUID) throws {
        let defaultDate = Date.distantPast
        let defaultDateFuture = Date.distantFuture
        
        guard
            let log = getActivityLogById(from: activityLogId),
            let activityId = log.activity?.id, // Get ID directly
            let startTime = log.startTime
        else { return }
        
        
        guard log.activity?.storeLocation == false else { return }
        

        let lowerBound = startTime.addingTimeInterval(-2 * 60)

        // 1. Predicate: Find logs ending in the 2-minute window before this one starts
        let predicate = #Predicate<ActivityLog> { priorLog in
            (priorLog.endTime ?? defaultDate) >= lowerBound &&
            (priorLog.endTime ?? defaultDateFuture) <= startTime
        }

        let descriptor = FetchDescriptor<ActivityLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        let candidates = try modelContext.fetch(descriptor)

        // 2. Filter: Ensure it's the same activity and NOT the same log
        // (The ID check is just a safety net)
        guard let lowerLog = candidates.first(where: {
            $0.activity?.id == activityId && $0.id != activityLogId
        }) else {
            return
        }

        // 3. Merge: "Stretch" the current log and remove the old one
        log.startTime = lowerLog.startTime
        modelContext.delete(lowerLog)

        try modelContext.save()
    }
    
    public func clearTimeFrame(startDate: Date, endDate: Date, logId: UUID, currentActivityStartDate: Date? = nil) throws {
        do {
            try applyTimeFrameClear(startDate: startDate, endDate: endDate, logId: logId,
                                    currentActivityStartDate: currentActivityStartDate)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func applyTimeFrameClear(startDate: Date, endDate: Date, logId: UUID, currentActivityStartDate: Date?) throws {
        let defaultDate = Date.distantPast
        let defaultDateFuture = Date.distantFuture
        
        if let currentActivityStartDate { //INFO: Should never be triggered
            guard endDate <= currentActivityStartDate else {
                throw(ActivityLogActorErrors.cannotOverwriteRunningActivity)
            }
        }
        
        // 0. Split logs that span the entire range
        let logsToSplit = #Predicate<ActivityLog> { log in
            (log.startTime ?? defaultDate) < startDate &&
            (log.endTime ?? defaultDate) > endDate
        }
        let splitDescriptor = FetchDescriptor<ActivityLog>(
            predicate: logsToSplit
        )
        let dataToSplit = try modelContext.fetch(splitDescriptor)
        
        for log in dataToSplit {
            guard log.id != logId else { continue }
            guard let originalEnd = log.endTime else {
                throw(ActivityLogActorErrors.cannotOverwriteRunningActivity)
            }

            // Historical splitting preserves the original relationship, including
            // archived or missing activities. Commit both segments together.
            let tail = ActivityLog(
                startTime: endDate, endTime: originalEnd, activity: log.activity,
                previousActivityLogId: log.previousActivityLogId
            )
            tail.endLatitude = log.endLatitude
            tail.endLongitude = log.endLongitude
            modelContext.insert(tail)
            log.endTime = startDate
            log.endLatitude = nil
            log.endLongitude = nil
        }
        
        let logsToDelete = #Predicate<ActivityLog> { log in
            (log.startTime ?? defaultDate) >= startDate &&
            (log.endTime ?? defaultDateFuture) <= endDate
        }
        let deleteDescriptor = FetchDescriptor<ActivityLog>(
            predicate: logsToDelete
        )
        let dataToDelete = try modelContext.fetch(deleteDescriptor)
        
        for log in dataToDelete {
            guard log.id != logId else { continue }
            guard log.endTime != nil else {
                throw(ActivityLogActorErrors.cannotOverwriteRunningActivity)
            }
            modelContext.delete(log)
        }
        
        // 2. Truncate logs that start before range and end within range
        let logsStartingBefore = #Predicate<ActivityLog> { log in
            (log.startTime ?? defaultDate) < startDate &&
            (log.endTime ?? defaultDate) > startDate &&
            (log.endTime ?? defaultDate) <= endDate
        }
        let beforeDescriptor = FetchDescriptor<ActivityLog>(
            predicate: logsStartingBefore
        )
        let dataStartingBefore = try modelContext.fetch(beforeDescriptor)
        
        for log in dataStartingBefore {
            guard log.id != logId else { continue }
            guard log.endTime != nil else {
                throw(ActivityLogActorErrors.cannotOverwriteRunningActivity)
            }
            log.endTime = startDate
        }
        
        // 3. Truncate logs that start within range and end after range
        let logsEndingAfter = #Predicate<ActivityLog> { log in
            (log.startTime ?? defaultDate) >= startDate &&
            (log.startTime ?? defaultDate) < endDate &&
            (log.endTime ?? defaultDate) > endDate
        }
        let afterDescriptor = FetchDescriptor<ActivityLog>(
            predicate: logsEndingAfter
        )
        let dataEndingAfter = try modelContext.fetch(afterDescriptor)
        
        for log in dataEndingAfter {
            guard log.id != logId else { continue }
            guard log.endTime != nil else {
                throw(ActivityLogActorErrors.cannotOverwriteRunningActivity)
            }
            
            log.startTime = endDate
        }
        
    }

    public func getActivityLogsForTimeFrame(filterData: FilterData) -> [ActivityLog] {
        let defaultDate = Date.distantPast
        let startDate = filterData.startDate
        let endDate = filterData.endDate
        let selectedIds: [UUID] = filterData.selectedActivityIds

        // Glaub hier muss endzeit genommen werden
        let afterStartDate = #Predicate<ActivityLog> { log in
            (log.endTime ?? defaultDate) > startDate
        }

        // Hier passt es
        let beforeEndDate = #Predicate<ActivityLog> { log in
            (log.startTime ?? defaultDate) < endDate
        }

        // Combine predicates
        let fetchDescriptor = FetchDescriptor<ActivityLog>(
            predicate: #Predicate { log in
                afterStartDate.evaluate(log) &&
                beforeEndDate.evaluate(log)
            }
        )

        // Fetch with proper error handling
        do {
            let data = try modelContext.fetch(fetchDescriptor)
            return data.filter { log in
                guard let activityId = log.activity?.id else { return false }
                return selectedIds.contains(activityId)
            }
        } catch {
            print("Database fetch failed: \(error)")
            return []
        }
    }

    public func getAllActivityLogs() -> [ActivityLog] {
        let fetchDescriptor = FetchDescriptor<ActivityLog>()
        do {
            let data = try modelContext.fetch(fetchDescriptor)
            return data
        } catch {
            print("Database fetch failed: \(error)")
            return []
        }
    }

    public func resumeActivity(activityLogId: UUID) -> UUID? {
        guard let log = getActivityLogById(from: activityLogId),
              log.activity?.archived != true,
              runningActivity(for: log) != nil else { return nil }
        do {
            let current = try recoverRunningActivity()
            if let current, current.logId != activityLogId { return nil }
            log.endTime = nil
            try modelContext.save()
            return log.id
        } catch {
            modelContext.rollback()
            return nil
        }
    }

    public func getPreviousActivtyLogID(activityLogId: UUID) -> UUID? {
        let fetchDescriptor = FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == activityLogId }
        )
        let activityLog = try? modelContext.fetch(fetchDescriptor).first

        return activityLog?.previousActivityLogId
    }

    public func getActivtyLogDTO(activityLogId: UUID) -> ActivityDTO? {
        let fetchDescriptor = FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == activityLogId }
        )
        let activityLog = try? modelContext.fetch(fetchDescriptor).first

        guard let activityLog = activityLog,
              let activity = activityLog.activity,
              let activityId = activity.id,
              let activityName = activity.name,
              let startTime = activityLog.startTime
        else {
            return nil
        }

        return ActivityDTO(
            id: activityId,
            name: activityName,
            startTime: startTime,
            icon: activity.sfSymbolName ?? "questionmark.circle.fill",
            color: activity.color,
            weekdays: activity.weekdays ?? [],
            endTime: activityLog.endTime
        )
    }

    private func isActivtyLongerThen(date: Date, min: Double) -> Bool {
        let seconds = min * 60
        let now = Date.now
        return now.timeIntervalSince(date) <= seconds
    }

    @discardableResult
    public func stopRunningActivity(preferredLogId: UUID? = nil, matchingActivityId: UUID? = nil) async throws -> Bool {
        guard let current = try recoverRunningActivity(preferredLogId: preferredLogId),
              matchingActivityId == nil || current.activity.id == matchingActivityId else { return false }
        try finishActivity(activityLogId: current.logId)
        return true
    }

    public func stopActivity(activityLogId: UUID) async {
        try? finishActivity(activityLogId: activityLogId)
    }

    private func finishActivity(activityLogId: UUID) throws {
        guard let activityLog = getActivityLogById(from: activityLogId),
              activityLog.endTime == nil else { return }
        activityLog.endTime = max(activityLog.startTime ?? .distantPast, Date.now)
        do { try modelContext.save() }
        catch { modelContext.rollback(); throw error }

        if activityLog.activity?.storeLocation == true {
            Task { await captureLocation(activityLogId: activityLogId, isStart: false) }
        }
    }

    public func getActivityLogById(from activityLogId: UUID) -> ActivityLog? {
        let fetchDescriptor = FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == activityLogId }
        )
        let activityLog = try? modelContext.fetch(fetchDescriptor)

        return activityLog?.first
    }

    public func editActivityLogById(
        activityId: UUID,
        newActivity: ActivityItem
    ) {
        let fetchDescriptor = FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )
        let activity = try? modelContext.fetch(fetchDescriptor).first

        activity?.name = newActivity.name

        try? modelContext.save()
    }

    public func delete(activityLog: ActivityLog) {
        modelContext.delete(activityLog)
        try? modelContext.save()
    }
}



