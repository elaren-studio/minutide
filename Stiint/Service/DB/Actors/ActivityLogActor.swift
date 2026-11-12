//
//  ActivityLogActor.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//

import Foundation
import SwiftData
import SwiftUI
import CoreLocation
import os

@ModelActor
public actor ActivityLogActor {
    public enum ManualLogError: LocalizedError, Equatable {
        case invalidInterval, unavailableActivity, unavailableLog, runningActivityOverlap

        public var errorDescription: String? {
            switch self {
            case .invalidInterval: "Choose a valid start and end time, with the end after the start and no later than now."
            case .unavailableActivity: "This activity is unavailable. Choose an active activity and try again."
            case .unavailableLog: "This log is unavailable or still running. Close and reopen the editor."
            case .runningActivityOverlap: "The log must end before the current timer starts. Stop the timer or choose an earlier end time."
            }
        }
    }

    /// All destructive overlap changes and their replacement share one fresh
    /// context and one save. A rejected target or failed save leaves history intact.
    @discardableResult
    public func saveCompletedLog(logId: UUID? = nil, activityId: UUID?, startTime: Date, endTime: Date,
                                 refreshAssignment: Bool = false) throws -> UUID {
        guard startTime.timeIntervalSinceReferenceDate.isFinite,
              endTime.timeIntervalSinceReferenceDate.isFinite,
              startTime < endTime, endTime <= Date.now else {
            throw ManualLogError.invalidInterval
        }

        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        do {
            let editedLog: ActivityLog?
            if let logId {
                guard let saved = try context.fetch(FetchDescriptor<ActivityLog>(
                    predicate: #Predicate { $0.id == logId }
                )).first, saved.endTime != nil else { throw ManualLogError.unavailableLog }
                editedLog = saved
            } else {
                editedLog = nil
            }

            let target: ActivityItem?
            if let activityId {
                guard let activity = try context.fetch(FetchDescriptor<ActivityItem>(
                    predicate: #Predicate { $0.id == activityId }
                )).first, activity.archived != true || (editedLog?.activity?.id == activityId && !refreshAssignment) else {
                    throw ManualLogError.unavailableActivity
                }
                target = activity
            } else {
                // An orphan may keep its missing relationship while its dates
                // are edited; a new log cannot be created without an activity.
                guard let editedLog, editedLog.activity == nil else { throw ManualLogError.unavailableActivity }
                target = nil
            }

            let runningLogs = try context.fetch(FetchDescriptor<ActivityLog>(
                predicate: #Predicate { $0.endTime == nil }
            ))
            for running in runningLogs {
                guard let start = running.startTime,
                      start.timeIntervalSinceReferenceDate.isFinite,
                      endTime <= start else { throw ManualLogError.runningActivityOverlap }
            }

            let replacement = editedLog ?? ActivityLog(startTime: startTime, endTime: endTime, activity: target)
            guard let replacementId = replacement.id else { throw ManualLogError.unavailableLog }
            let reassign = editedLog == nil || editedLog?.activity?.id != activityId || refreshAssignment
            let snapshot: WorkSnapshot
            if reassign, let target {
                do { snapshot = try WorkHierarchy.resolve(task: target, in: context, requireAvailable: true) }
                catch { throw ManualLogError.unavailableActivity }
            } else {
                snapshot = replacement.workSnapshot
            }
            try applyTimeFrameClear(startDate: startTime, endDate: endTime,
                                    logId: replacementId, currentActivityStartDate: nil, context: context)
            if editedLog == nil { context.insert(replacement) }
            if replacement.startTime != startTime {
                replacement.startLatitude = nil
                replacement.startLongitude = nil
            }
            if replacement.endTime != endTime {
                replacement.endLatitude = nil
                replacement.endLongitude = nil
            }
            replacement.startTime = startTime
            replacement.endTime = endTime
            replacement.activity = target
            replacement.workSnapshot = snapshot
            try context.save()
            return replacementId
        } catch {
            context.rollback()
            throw error
        }
    }

    public struct RunningActivity: Sendable {
        public let logId: UUID
        public let activity: ActivityDTO
    }

    public enum ResumeLogError: LocalizedError, Equatable {
        case trackingPaused, unavailableLog, invalidInterval, unavailableActivity

        public var errorDescription: String? {
            switch self {
            case .trackingPaused: "Unpause tracking in Settings before resuming an entry."
            case .unavailableLog: "This completed entry is unavailable. Close and reopen its details."
            case .invalidInterval: "This entry has invalid dates and cannot be resumed."
            case .unavailableActivity: "Restore this task and its current work location before resuming it."
            }
        }
    }

    /// Resume records a separate interval now, preserving the selected entry's
    /// captured assignment and appearance. Validation and all timer changes share
    /// one save; the completed source and its coordinates are never modified.
    public func resumeCompletedLog(logId: UUID, preferredLogId: UUID? = nil) throws -> RunningActivity {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        do {
            let now = Date.now
            guard let source = try context.fetch(FetchDescriptor<ActivityLog>(
                predicate: #Predicate { $0.id == logId })).first,
                  let end = source.endTime else { throw ResumeLogError.unavailableLog }
            guard let start = source.startTime,
                  start.timeIntervalSinceReferenceDate.isFinite,
                  end.timeIntervalSinceReferenceDate.isFinite,
                  start < end, end <= now else { throw ResumeLogError.invalidInterval }
            guard let taskID = source.activity?.id,
                  let task = try context.fetch(FetchDescriptor<ActivityItem>(
                    predicate: #Predicate { $0.id == taskID })).first,
                  WorkHierarchy.isAvailable(task: task, in: context) else {
                throw ResumeLogError.unavailableActivity
            }
            let snapshot = source.workSnapshot
            let previous = try recoverOpenLog(in: context, preferredLogId: preferredLogId, now: now)
            if previous?.activity?.id == taskID, previous?.workSnapshot == snapshot,
               let running = previous.flatMap({ runningActivity(for: $0) }) {
                try context.save()
                return running
            }
            let boundary = max(now, previous?.startTime ?? now)
            previous?.endTime = boundary
            let log = ActivityLog(startTime: boundary, activity: task, previousActivityLogId: previous?.id)
            log.workSnapshot = snapshot
            context.insert(log)
            guard let running = runningActivity(for: log) else { throw ResumeLogError.unavailableLog }
            try context.save()
            captureTimerLocations(previous: previous, started: log)
            return running
        } catch {
            context.rollback()
            throw error
        }
    }

    /// The database owns timer state. Preferences are only a recovery hint.
    /// Historical unfinished rows are closed, never deleted, when recovering.
    public func recoverRunningActivity(preferredLogId: UUID? = nil) throws -> RunningActivity? {
        // Timer operations use fresh contexts so manual edits and a preceding
        // resume transaction cannot leave registered open rows stale.
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        do {
            let current = try recoverOpenLog(in: context, preferredLogId: preferredLogId, now: .now)
            if context.hasChanges { try context.save() }
            return current.flatMap { runningActivity(for: $0) }
        } catch {
            context.rollback()
            throw error
        }
    }

    private func recoverOpenLog(in context: ModelContext, preferredLogId: UUID?, now: Date) throws -> ActivityLog? {
        let logs = try context.fetch(FetchDescriptor<ActivityLog>(
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
            log.endTime = max(log.startTime ?? .distantPast, nextStart ?? now)
        }
        return current
    }

    /// Validation, closing the previous timer, and insertion happen before any
    /// suspension, so concurrent callers cannot create two running timers.
    public func startOrSwitchActivity(activityId: UUID, preferredLogId: UUID? = nil) async throws -> RunningActivity? {
        // Other model contexts (the editor and ActivityActor) can archive an
        // already-registered activity. Validate against a fresh store read.
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        guard let activity = try context.fetch(FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )).first, activity.archived != true, activity.name != nil,
              let snapshot = try? WorkHierarchy.resolve(task: activity, in: context,
                                                        requireAvailable: true) else { return nil }

        do {
            let previous = try recoverOpenLog(in: context, preferredLogId: preferredLogId, now: .now)
            if previous?.activity?.id == activityId {
                try context.save()
                return previous.flatMap { runningActivity(for: $0) }
            }
            let now = max(Date.now, previous?.startTime ?? .distantPast)
            previous?.endTime = now
            let log = ActivityLog(startTime: now, activity: activity, previousActivityLogId: previous?.id)
            log.workSnapshot = snapshot
            context.insert(log)
            try context.save()
            let result = runningActivity(for: log)
            captureTimerLocations(previous: previous, started: log)
            return result
        } catch {
            context.rollback()
            throw error
        }
    }

    private func captureTimerLocations(previous: ActivityLog?, started log: ActivityLog) {
        if previous?.activity?.storeLocation == true, let id = previous?.id,
           let previousActivityId = previous?.activity?.id, let boundary = previous?.endTime {
            Task { await captureLocation(activityLogId: id, activityId: previousActivityId, boundary: boundary, isStart: false) }
        }
        if log.activity?.storeLocation == true, let activityId = log.activity?.id,
           let id = log.id, let boundary = log.startTime {
            Task { await captureLocation(activityLogId: id, activityId: activityId, boundary: boundary, isStart: true) }
        }
    }

    // Optional metadata must never hold up starting/stopping a timer or its UI.
    private func captureLocation(activityLogId: UUID, activityId: UUID, boundary: Date, isStart: Bool) async {
        guard let location = try? await LocationProvider.shared.getCurrentLocation() else { return }
        _ = try? applyCapturedLocation(location, activityLogId: activityLogId,
                                       activityId: activityId, boundary: boundary, isStart: isStart)
    }

    /// A location request can outlive edits, deletion, archiving, or opt-out.
    /// Revalidate its original boundary against storage after the suspension,
    /// and never save a model retained by the actor's long-lived context.
    @discardableResult
    func applyCapturedLocation(_ location: CLLocation, activityLogId: UUID,
                               activityId: UUID, boundary: Date, isStart: Bool) throws -> Bool {
        guard boundary.timeIntervalSinceReferenceDate.isFinite,
              CLLocationCoordinate2DIsValid(location.coordinate) else { return false }
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        guard let log = try context.fetch(FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == activityLogId }
        )).first, let activity = log.activity,
              activity.id == activityId, activity.archived != true,
              activity.storeLocation == true,
              (isStart ? log.startTime : log.endTime) == boundary else { return false }
        if isStart {
            log.startLatitude = location.coordinate.latitude
            log.startLongitude = location.coordinate.longitude
        } else {
            log.endLatitude = location.coordinate.latitude
            log.endLongitude = location.coordinate.longitude
        }
        do { try context.save(); return true }
        catch { context.rollback(); throw error }
    }

    private func runningActivity(for log: ActivityLog) -> RunningActivity? {
        guard let id = log.id, let dto = activityDTO(for: log) else { return nil }
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
        let context = ModelContext(modelContainer)
        let fetchDescriptor = FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )
        guard let activity = try? context.fetch(fetchDescriptor).first,
              let snapshot = try? WorkHierarchy.resolve(task: activity, in: context,
                                                        requireAvailable: true) else { return }
        
        
        let activityLog = ActivityLog(
            startTime: startTime,
            endTime: endTime,
            activity: activity
        )
        
        activityLog.workSnapshot = snapshot
        context.insert(activityLog)
        try? context.save()
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
                                    currentActivityStartDate: currentActivityStartDate, context: modelContext)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func applyTimeFrameClear(startDate: Date, endDate: Date, logId: UUID, currentActivityStartDate: Date?, context: ModelContext) throws {
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
        let dataToSplit = try context.fetch(splitDescriptor)
        
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
            tail.workSnapshot = log.workSnapshot
            // Freeze the retained head as well if this is an unbootstrapped fixture.
            if log.hierarchySnapshotVersion == nil { log.workSnapshot = tail.workSnapshot }
            tail.endLatitude = log.endLatitude
            tail.endLongitude = log.endLongitude
            context.insert(tail)
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
        let dataToDelete = try context.fetch(deleteDescriptor)
        
        for log in dataToDelete {
            guard log.id != logId else { continue }
            guard log.endTime != nil else {
                throw(ActivityLogActorErrors.cannotOverwriteRunningActivity)
            }
            context.delete(log)
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
        let dataStartingBefore = try context.fetch(beforeDescriptor)
        
        for log in dataStartingBefore {
            guard log.id != logId else { continue }
            guard log.endTime != nil else {
                throw(ActivityLogActorErrors.cannotOverwriteRunningActivity)
            }
            log.endTime = startDate
            log.endLatitude = nil
            log.endLongitude = nil
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
        let dataEndingAfter = try context.fetch(afterDescriptor)
        
        for log in dataEndingAfter {
            guard log.id != logId else { continue }
            guard log.endTime != nil else {
                throw(ActivityLogActorErrors.cannotOverwriteRunningActivity)
            }
            
            log.startTime = endDate
            log.startLatitude = nil
            log.startLongitude = nil
        }
        
    }

    public func getActivityLogsForTimeFrame(filterData: FilterData) -> [ActivityLog] {
        let context = ModelContext(modelContainer)
        let defaultDate = Date.distantPast
        let now = Date.now
        let startDate = filterData.startDate
        let endDate = filterData.endDate
        let selectedIds: [UUID] = filterData.selectedActivityIds

        // Open timers contribute up to this query's captured current time.
        let afterStartDate = #Predicate<ActivityLog> { log in
            (log.endTime ?? now) > startDate
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
            let data = try context.fetch(fetchDescriptor)
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
        let context = ModelContext(modelContainer)
        let fetchDescriptor = FetchDescriptor<ActivityLog>()
        do {
            let data = try context.fetch(fetchDescriptor)
            return data
        } catch {
            print("Database fetch failed: \(error)")
            return []
        }
    }

    /// Immutable actor boundary for reports; a single captured now controls open-log inclusion.
    public func getReportLogs(start: Date, end: Date, now: Date) throws -> [WorkReportEntry] {
        guard start.timeIntervalSinceReferenceDate.isFinite, end.timeIntervalSinceReferenceDate.isFinite,
              now.timeIntervalSinceReferenceDate.isFinite, start < end else { return [] }
        let context = ModelContext(modelContainer)
        let distantPast = Date.distantPast
        let logs = try context.fetch(FetchDescriptor<ActivityLog>(predicate: #Predicate {
            ($0.startTime ?? distantPast) < end && ($0.endTime ?? now) > start
        }))
        return logs.compactMap { log in
            guard let id = log.id, let began = log.startTime,
                  began.timeIntervalSinceReferenceDate.isFinite,
                  (log.endTime ?? now).timeIntervalSinceReferenceDate.isFinite,
                  began < end, (log.endTime ?? now) > start else { return nil }
            return WorkReportEntry(id: id, startTime: log.startTime, endTime: log.endTime,
                workSnapshot: log.workSnapshot, startLatitude: log.startLatitude,
                startLongitude: log.startLongitude, endLatitude: log.endLatitude, endLongitude: log.endLongitude)
        }
    }

    public func resumeActivity(activityLogId: UUID) -> UUID? {
        guard let log = getActivityLogById(from: activityLogId),
              log.activity?.archived != true,
              runningActivity(for: log) != nil else { return nil }
        do {
            let context = ModelContext(modelContainer)
            guard let taskID = log.activity?.id,
                  let task = try context.fetch(FetchDescriptor<ActivityItem>(
                    predicate: #Predicate { $0.id == taskID })).first,
                  WorkHierarchy.isAvailable(task: task, in: context) else { return nil }
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
        let context = ModelContext(modelContainer)
        let fetchDescriptor = FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == activityLogId }
        )
        let activityLog = try? context.fetch(fetchDescriptor).first

        return activityLog?.previousActivityLogId
    }

    public func getActivtyLogDTO(activityLogId: UUID) -> ActivityDTO? {
        let context = ModelContext(modelContainer)
        let fetchDescriptor = FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == activityLogId }
        )
        guard let log = try? context.fetch(fetchDescriptor).first else { return nil }
        return activityDTO(for: log)
    }

    private func activityDTO(for activityLog: ActivityLog) -> ActivityDTO? {
        guard let activity = activityLog.activity,
              let activityId = activity.id,
              let startTime = activityLog.startTime
        else {
            return nil
        }

        let snapshot = activityLog.workSnapshot
        let task = snapshot.task
        guard let activityName = task?.name ?? activity.name else { return nil }
        return ActivityDTO(
            id: activityId,
            name: activityName,
            startTime: startTime,
            icon: task?.sfSymbolName ?? activity.sfSymbolName ?? "questionmark.circle.fill",
            color: Color(hex: task?.colorHex ?? activity.colorHex),
            weekdays: activity.weekdays ?? [],
            endTime: activityLog.endTime,
            organizationName: snapshot.organization?.name,
            clientName: snapshot.client?.name,
            projectName: snapshot.project?.name
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
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        guard let activityLog = try context.fetch(FetchDescriptor<ActivityLog>(
            predicate: #Predicate { $0.id == activityLogId })).first,
              activityLog.endTime == nil else { return }
        activityLog.endTime = max(activityLog.startTime ?? .distantPast, Date.now)
        do { try context.save() }
        catch { context.rollback(); throw error }

        if activityLog.activity?.storeLocation == true,
           let activityId = activityLog.activity?.id, let boundary = activityLog.endTime {
            Task { await captureLocation(activityLogId: activityLogId, activityId: activityId, boundary: boundary, isStart: false) }
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



