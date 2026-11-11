//
//  SelectActivity.swift
//  Pattrn
//
//  Created by Liam Wittig on 07.12.25.
//

import SwiftData
import SwiftUI

struct SelectActivity: View {
    @State private var isShowingCreateSheet = false
    @State private var activityToEdit: ActivityItem?
    @State private var activityToDelete: ActivityItem?
    @State private var showDeleteConfirmation = false

    @Query(filter: #Predicate<ActivityItem> { activity in
        activity.archived == nil || activity.archived == false
    })
    private var activities: [ActivityItem]

    var body: some View {
        NavigationView {
            List(activities) { activity in
                if let activityId = activity.id,
                   let name = activity.name,
                   !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        Task {
                            await RunningManager.shared.startActivity(activityId: activityId)
                        }
                    } label: {
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .frame(width: 35, height: 35)
                                    .foregroundStyle(activity.color)
                                    .shadow(color: activity.color.opacity(0.3), radius: 10, x: 0, y: 5)

                                Image(systemName: activity.sfSymbolName ?? "xmark.circle")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text(name).fontWeight(.bold)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start \(name)")
                    .accessibilityIdentifier("activity.start.\(activityId.uuidString)")
                    .contextMenu {
                        Button {
                            activityToEdit = activity
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            activityToDelete = activity
                            showDeleteConfirmation = true
                        } label: {
                            Label("Remove", systemImage: "xmark.circle")
                        }
                    }
                }
            }
            .navigationTitle("Start Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingCreateSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Activity")
                    .accessibilityIdentifier("activity.add")
                }
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                CreateActivityView(activityToEdit: nil)
            }
            .sheet(item: $activityToEdit) { activity in
                CreateActivityView(activityToEdit: activity)
            }.alert("Delete Activity", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let activityId = activityToDelete?.id {
                        Task {
                            await PersistenceManager.shared
                                .activityActor
                                .delete(from: activityId)
                        }
                        activityToDelete = nil
                    }
                }

                Button("Cancel", role: .cancel) {
                    activityToDelete = nil
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

#Preview {
    SelectActivity()
}
