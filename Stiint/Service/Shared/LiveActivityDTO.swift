//
//  LiveActivityDTO.swift
//  Stiint
//
//  Created by Wittig, Liam on 17.12.25.
//

import ActivityKit
import Foundation
import SwiftUI

struct LiveActivityDTO: ActivityAttributes, Hashable, Decodable {
    typealias Status = ContentState

    let id: UUID
    let name: String
    let startTime: Date
    let icon: String
    let color: String
    let organizationName: String?
    let clientName: String?
    let projectName: String?

    init(
        id: UUID,
        name: String,
        startTime: Date,
        icon: String,
        color: String,
        organizationName: String? = nil,
        clientName: String? = nil,
        projectName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.icon = icon
        self.color = color
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

    private enum CodingKeys: String, CodingKey {
        case id, name, startTime, icon, color
        case organizationName, clientName, projectName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        startTime = try container.decode(Date.self, forKey: .startTime)
        icon = try container.decode(String.self, forKey: .icon)
        color = try container.decode(String.self, forKey: .color)
        organizationName = try container.decodeIfPresent(String.self, forKey: .organizationName)
        clientName = try container.decodeIfPresent(String.self, forKey: .clientName)
        projectName = try container.decodeIfPresent(String.self, forKey: .projectName)
    }

    struct ContentState: Codable, Hashable {
        var isActive: Bool
    }
}
