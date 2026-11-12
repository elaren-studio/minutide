//
//  ActivityLog.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//

import Foundation
import SwiftData
import SwiftUI
import CoreLocation

@Model
public final class ActivityLog {
    public var id: UUID?
    
    public var startTime: Date?
    public var endTime: Date?
    
    public var activity: ActivityItem?
    public var previousActivityLogId: UUID?

    public var hierarchySnapshotVersion: Int?
    public var snapshotTaskID: UUID?
    public var snapshotTaskName: String?
    public var snapshotTaskColorHex: String?
    public var snapshotTaskSymbolName: String?
    public var snapshotOrganizationID: UUID?
    public var snapshotOrganizationName: String?
    public var snapshotOrganizationColorHex: String?
    public var snapshotOrganizationSymbolName: String?
    public var snapshotClientID: UUID?
    public var snapshotClientName: String?
    public var snapshotClientColorHex: String?
    public var snapshotClientSymbolName: String?
    public var snapshotProjectID: UUID?
    public var snapshotProjectName: String?
    public var snapshotProjectColorHex: String?
    public var snapshotProjectSymbolName: String?

    public var workSnapshot: WorkSnapshot {
        get {
            guard hierarchySnapshotVersion != nil else {
                return WorkHierarchy.legacySnapshot(task: activity)
            }
            return WorkSnapshot(
                task: Self.snapshotNode(id: snapshotTaskID, name: snapshotTaskName,
                    color: snapshotTaskColorHex, symbol: snapshotTaskSymbolName),
                organization: Self.snapshotNode(id: snapshotOrganizationID, name: snapshotOrganizationName,
                    color: snapshotOrganizationColorHex, symbol: snapshotOrganizationSymbolName),
                client: Self.snapshotNode(id: snapshotClientID, name: snapshotClientName,
                    color: snapshotClientColorHex, symbol: snapshotClientSymbolName),
                project: Self.snapshotNode(id: snapshotProjectID, name: snapshotProjectName,
                    color: snapshotProjectColorHex, symbol: snapshotProjectSymbolName))
        }
        set {
            hierarchySnapshotVersion = 1
            snapshotTaskID = newValue.task?.id
            snapshotTaskName = newValue.task?.name
            snapshotTaskColorHex = newValue.task?.colorHex
            snapshotTaskSymbolName = newValue.task?.sfSymbolName
            snapshotOrganizationID = newValue.organization?.id
            snapshotOrganizationName = newValue.organization?.name
            snapshotOrganizationColorHex = newValue.organization?.colorHex
            snapshotOrganizationSymbolName = newValue.organization?.sfSymbolName
            snapshotClientID = newValue.client?.id
            snapshotClientName = newValue.client?.name
            snapshotClientColorHex = newValue.client?.colorHex
            snapshotClientSymbolName = newValue.client?.sfSymbolName
            snapshotProjectID = newValue.project?.id
            snapshotProjectName = newValue.project?.name
            snapshotProjectColorHex = newValue.project?.colorHex
            snapshotProjectSymbolName = newValue.project?.sfSymbolName
        }
    }

    private static func snapshotNode(id: UUID?, name: String?, color: String?, symbol: String?) -> WorkNodeSnapshot? {
        guard id != nil || name != nil else { return nil }
        return WorkNodeSnapshot(id: id, name: name ?? "Unknown", colorHex: color, sfSymbolName: symbol)
    }
    
    public var startLatitude: Double?
    public var startLongitude: Double?
    public var endLatitude: Double?
    public var endLongitude: Double?
    
    
    public init(
        startTime: Date? = nil,
        endTime: Date? = nil,
        activity: ActivityItem? = nil,
        previousActivityLogId: UUID? = nil,
        startLocation: CLLocation? = nil,
        endLocation: CLLocation? = nil,

    ) {
        id = id ?? UUID()
        
        self.startTime = startTime ?? Date.now
        self.endTime = endTime
        
        self.activity = activity
        self.previousActivityLogId = previousActivityLogId

        self.startLatitude = startLocation?.coordinate.latitude
        self.startLongitude = startLocation?.coordinate.longitude
        self.endLatitude = endLocation?.coordinate.latitude
        self.endLongitude = endLocation?.coordinate.longitude
    }
}
