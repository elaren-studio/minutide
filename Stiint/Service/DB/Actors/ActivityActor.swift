//
//  ActivityActor.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//

import Foundation
import SwiftData
import SwiftUI

@ModelActor
public actor ActivityActor {
    public func addActivity(name: String, color: Color = .blue, icon: String? = nil, weekdays: Set<Weekday> = [], storeLocation: Bool = false) {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        do {
            _ = try WorkMutations.saveTask(in: context, id: nil, name: name, parent: nil,
                colorHex: color.toHex(), sfSymbolName: icon, weekdays: weekdays, storeLocation: storeLocation)
            try context.save()
        } catch {
            context.rollback()
        }
    }

    public func editActivityById(activityId: UUID, newName: String? = nil, newColor: Color? = nil, newIcon: String? = nil, weekdays: Set<Weekday> = [], storeLocation: Bool = false) {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        do {
            let activity = try WorkHierarchy.task(id: activityId, in: context)
            _ = try WorkMutations.saveTask(in: context, id: activityId, name: newName ?? activity.name ?? "",
                parent: activity.workParent, colorHex: newColor?.toHex() ?? activity.colorHex,
                sfSymbolName: newIcon, weekdays: weekdays, storeLocation: storeLocation)
            try context.save()
        } catch {
            context.rollback()
        }
    }

    /// Shortcuts uses committed graph state, including archived ancestors.
    public func getStartableActivitySnapshots() throws -> [WorkSnapshot] {
        let context = ModelContext(modelContainer)
        return try context.fetch(FetchDescriptor<ActivityItem>(sortBy: [SortDescriptor(\.createdDate)]))
            .compactMap { activity in
                guard activity.id != nil, activity.name != nil else { return nil }
                return try? WorkHierarchy.resolve(task: activity, in: context, requireAvailable: true)
            }
    }

    public func getAllAvaibleActivitys() -> [ActivityItem] {
        let fetchDescriptor = FetchDescriptor<ActivityItem>()
        let activitys = try? modelContext.fetch(fetchDescriptor)

        return activitys ?? []
    }

    public func getActivityByName(from name: String) -> ActivityItem? {
        let fetchDescriptor = FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.name == name }
        )
        let activity = try? modelContext.fetch(fetchDescriptor)

        return activity?.first
    }

    public func getActivityById(from activityId: UUID) -> ActivityItem? {
        let fetchDescriptor = FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )
        let activity = try? modelContext.fetch(fetchDescriptor)

        return activity?.first
    }

    public func addWeekday(from activityId: UUID, weekday: Weekday) {
        let fetchDescriptor = FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )
        let activity = try? modelContext.fetch(fetchDescriptor).first
        activity?.weekdays?.insert(weekday)

        try? modelContext.save()
    }

    public func removeWeekday(from activityId: UUID, weekday: Weekday) {
        let fetchDescriptor = FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )
        let activity = try? modelContext.fetch(fetchDescriptor).first
        activity?.weekdays?.remove(weekday)

        try? modelContext.save()
    }

    public func delete(from activityId: UUID) {
        let fetchDescriptor = FetchDescriptor<ActivityItem>(
            predicate: #Predicate { $0.id == activityId }
        )
        guard let activity = try? modelContext.fetch(fetchDescriptor).first else { return }
        activity.archived = true

        try? modelContext.save()
    }
}
