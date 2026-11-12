//
//  GetAllActivities.swift
//  Stiint
//
//  Created by Wittig, Liam on 20.12.25.
//

import AppIntents
import Foundation
import SwiftData

// Define the result struct that will be returned by the intent

// Define the App Intent
struct GetAllActivities: AppIntent {
    static var title: LocalizedStringResource = "Get all available Activities"
    static var description = IntentDescription(
        "Get all available activities."
    )

    func perform() async throws -> some IntentResult & ReturnsValue<[ActivityEntity]> {
        let activities = try await ActivityQuery().suggestedEntities()
        return .result(value: activities)
    }
}
