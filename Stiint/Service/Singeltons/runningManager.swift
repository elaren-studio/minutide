//
//  runningManager.swift
//  Stiint
//

import Foundation

public actor RunningManager {
    private(set) var currentActivityLogId: UUID?
    private var operationInProgress = false
    private var waitingOperations: [CheckedContinuation<Void, Never>] = []

    // Actor methods may re-enter at an await. Keep complete timer operations,
    // including their UI/preferences/Live Activity mirrors, in arrival order.
    private func acquireOperation() async {
        if !operationInProgress {
            operationInProgress = true
            return
        }
        await withCheckedContinuation { waitingOperations.append($0) }
    }

    private func releaseOperation() {
        if waitingOperations.isEmpty {
            operationInProgress = false
        } else {
            waitingOperations.removeFirst().resume()
        }
    }

    private func recover() async throws -> ActivityLogActor.RunningActivity? {
        let preferred = await ActivityLogPreferences.getActivityLogId()
        return try await PersistenceManager.shared.activityLogActor
            .recoverRunningActivity(preferredLogId: preferred)
    }

    private func display(_ running: ActivityLogActor.RunningActivity?, updateLiveActivity: Bool = true) async {
        currentActivityLogId = running?.logId
        await DtoManager.shared.setActivityDTO(running?.activity)
        if let running {
            await ActivityLogPreferences.saveActivityLogId(id: running.logId)
            if updateLiveActivity {
                await LiveActivityManager.shared.startLiveActivity(dto: running.activity)
            }
        } else {
            await ActivityLogPreferences.removeActivityLogId()
            if updateLiveActivity {
                await LiveActivityManager.shared.stopLiveActivity()
            }
        }
    }

    public func ensureReady() async {
        await acquireOperation()
        defer { releaseOperation() }
        do { await display(try await recover(), updateLiveActivity: false) }
        catch { print("Timer recovery failed: \(error)") }
    }

    public func setup() async {
        await acquireOperation()
        defer { releaseOperation() }
        do { await display(try await recover()) }
        catch { print("Timer recovery failed: \(error)") }
    }

    @discardableResult
    private func start(activityId: UUID) async throws -> Bool {
        guard let running = try await PersistenceManager.shared.activityLogActor
            .startOrSwitchActivity(activityId: activityId, preferredLogId: currentActivityLogId)
        else { return false }
        await display(running)
        return true
    }

    public func startActivity(activityId: UUID) async {
        await acquireOperation()
        defer { releaseOperation() }
        do { try await start(activityId: activityId) }
        catch { print("Starting timer failed: \(error)") }
    }

    /// A completed entry supplies its captured work details; a new timer begins
    /// now. Keep database and visible timer mirrors within the operation gate.
    @discardableResult
    public func resumeCompletedLog(logId: UUID) async throws -> ActivityLogActor.RunningActivity {
        await acquireOperation()
        defer { releaseOperation() }
        guard !UserDefaults.standard.bool(forKey: "pauseTracking") else {
            throw ActivityLogActor.ResumeLogError.trackingPaused
        }
        let running = try await PersistenceManager.shared.activityLogActor
            .resumeCompletedLog(logId: logId, preferredLogId: currentActivityLogId)
        await display(running)
        return running
    }

    private func stop(matchingActivityId: UUID? = nil) async throws {
        let stopped = try await PersistenceManager.shared.activityLogActor
            .stopRunningActivity(preferredLogId: currentActivityLogId, matchingActivityId: matchingActivityId)
        if stopped || matchingActivityId == nil {
            await display(try await recover())
        }
    }

    public func stopActivity() async {
        await acquireOperation()
        defer { releaseOperation() }
        do { try await stop() }
        catch { print("Stopping timer failed: \(error)") }
    }

    public func stopSpecificActivity(activityId: UUID) async {
        await acquireOperation()
        defer { releaseOperation() }
        do { try await stop(matchingActivityId: activityId) }
        catch { print("Stopping timer failed: \(error)") }
    }

    public func stopSpecificAndStartPreviousActivity(activityId: UUID) async {
        await acquireOperation()
        defer { releaseOperation() }
        do {
            guard let running = try await recover(), running.activity.id == activityId else { return }
            let logs = await PersistenceManager.shared.activityLogActor
            if let previousId = await logs.getPreviousActivtyLogID(activityLogId: running.logId),
               let previous = await logs.getActivtyLogDTO(activityLogId: previousId),
               try await start(activityId: previous.id) {
                return
            }
            try await stop(matchingActivityId: activityId)
        } catch { print("Returning to previous timer failed: \(error)") }
    }
}

public extension RunningManager {
    static let shared = RunningManager()
}
