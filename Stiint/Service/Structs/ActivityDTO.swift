//
//  Untitled.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//
import ActivityKit
import Foundation
import SwiftUI

public struct ActivityDTO: Sendable {
    let id: UUID
    let name: String
    let startTime: Date
    let icon: String
    let color: Color
    let weekdays: Set<Weekday>
    var endTime: Date?
    let organizationName: String?
    let clientName: String?
    let projectName: String?

    nonisolated init(
        id: UUID,
        name: String,
        startTime: Date,
        icon: String,
        color: Color,
        weekdays: Set<Weekday>,
        endTime: Date? = nil,
        organizationName: String? = nil,
        clientName: String? = nil,
        projectName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.icon = icon
        self.color = color
        self.weekdays = weekdays
        self.endTime = endTime
        self.organizationName = organizationName
        self.clientName = clientName
        self.projectName = projectName
    }

    var workPath: String {
        [organizationName, clientName, projectName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " › ")
    }
}
