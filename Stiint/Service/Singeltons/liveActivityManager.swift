//
// Original Stiint by Liam Wittig. Community recovery implementation.
//
import ActivityKit
import Foundation
import os

/// ActivityKit identifiers are system generated; the tracked activity ID lives in attributes.
/// Enumerate system activities so stop/recovery also works after the process is relaunched.
@MainActor
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    public func startLiveActivity(dto: ActivityDTO) async {
        guard dto.endTime == nil else {
            await stopLiveActivity()
            return
        }

        let color = dto.color.toHex() ?? "#007AFF"
        let existing = Activity<LiveActivityDTO>.activities
        let matching = existing.first {
            $0.attributes.id == dto.id &&
            $0.attributes.startTime == dto.startTime &&
            $0.attributes.name == dto.name &&
            $0.attributes.icon == dto.icon &&
            $0.attributes.color == color &&
            $0.attributes.organizationName == dto.organizationName &&
            $0.attributes.clientName == dto.clientName &&
            $0.attributes.projectName == dto.projectName &&
            ($0.activityState == .active || $0.activityState == .stale)
        }

        for activity in existing where activity.id != matching?.id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        if let matching {
            await matching.update(.init(state: .init(isActive: true), staleDate: nil))
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = LiveActivityDTO(
            id: dto.id, name: dto.name, startTime: dto.startTime,
            icon: dto.icon, color: color,
            organizationName: dto.organizationName,
            clientName: dto.clientName,
            projectName: dto.projectName
        )
        do {
            _ = try Activity<LiveActivityDTO>.request(
                attributes: attributes,
                content: .init(state: .init(isActive: true), staleDate: nil),
                pushType: nil
            )
        } catch {
            // Failure to present a Live Activity must never lose the persisted timer.
            Logger.app.error("Live Activity could not start: \(error.localizedDescription)")
        }
    }

    public func stopLiveActivity() async {
        for activity in Activity<LiveActivityDTO>.activities {
            await activity.end(
                .init(state: .init(isActive: false), staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }
}
