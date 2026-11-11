//
//  IsActivityRunning.swift
//  Stiint
//
//  Created by Wittig, Liam on 20.12.25.
//

import AppIntents
import Foundation

struct IsActivityRunning: AppIntent {
    static var title: LocalizedStringResource = "Is activity running?"
    static var description = IntentDescription(
        "Checks, if the selected activity is currently running."
    )

    @Parameter(title: "Activity")
    var activity: ActivityEntity

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        await RunningManager.shared.ensureReady()
        let currentID = await DtoManager.shared.activityDTO?.id
        return .result(value: currentID == activity.id)
    }
}
